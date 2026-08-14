# TEBBY.md - pickle_casinos

## Overview

`pickle_casinos` is a fully-featured, player-owned casino system for FiveM servers (ESX and QBCore). It lets administrators create and manage in-game casinos complete with eight game types (Blackjack, Baccarat, Roulette, Thunder Roulette, Poker, Wheel, Horse Racing, Slot Machines), a Lucky Wheel, a chip economy, VIP memberships, per-casino stores, ambient audio zones, and a management dashboard. All casino state is stored in a MySQL database (`pickle_casinos` and `pickle_casino_transactions` tables). The NUI front end is a compiled Vite/React bundle; source lives in `web/`, the build output is committed to `nui/`.

---

## Code design

### Architecture

The resource follows a standard FiveM client/server/shared split, wired together by `fxmanifest.lua`:

- **Shared** (`config.lua`, `core/shared.lua`, `locales/`, `templates/`, `modules/**/shared.lua`) — loaded on both sides. Defines configuration, helper utilities (`lerp`, `debugPrint`, `NumberWithCommas`, `_L`), and the `Templates` table.
- **Server** (`bridge/**/**/server.lua`, `modules/**/server.lua`, `core/server.lua`, `config_sv.lua`) — owns all authoritative state. Casino data lives in the global `Casinos` table, populated from the database at startup. All game logic runs here; the client is never trusted for outcomes.
- **Client** (`bridge/**/**/client.lua`, `modules/**/client.lua`, `core/client.lua`) — renders entities (NPCs, props), manages interactions, drives the NUI, and forwards player inputs to the server. The `Casinos` table is mirrored client-side via `pickle_casinos:registerCasino` / `pickle_casinos:updateCasinoEntity` events.
- **NUI** (`nui/index.html`, `nui/assets/`) — a compiled single-page app that handles the management dashboard, game UIs (Blackjack, Roulette, Poker, etc.), slot machines, and the casino editor. Communication is via `SendNUIMessage` (Lua → NUI) and `RegisterNUICallback` (NUI → Lua).

### Framework bridge

All framework-specific calls are wrapped in a bridge layer (`bridge/`). The correct bridge is selected at startup by checking `GetResourceState('es_extended')` / `GetResourceState('qb-core')`. If neither is running, `bridge/custom/` stubs load instead. The `Inventory` global is also populated by the bridge (or its own inventory sub-folder file). A thin `bridge/xp/` handles optional XP integration.

Target-system support (`bridge/target/ox_target/`, `bridge/target/qb-target/`, `bridge/target/qtarget/`) is similarly auto-selected.

### Main flows

1. **Server init** — `core/server.lua` (or a module's server file) loads all casinos from the database into `Casinos`, broadcasts them to clients via `pickle_casinos:registerCasino`.
2. **Casino management** — Admins use `/casino` → NUI editor to create/edit casinos. NUI callbacks trigger server events; the server updates the database and re-syncs the client.
3. **Chip economy** — Players buy chips at the cashier (`modules/cashier/server.lua`). Cash flows into `casino.balance`; chip items are added to the player's inventory. On selling, the reverse happens. The balance is updated in the DB immediately.
4. **Game rounds** — Each game module (e.g. `modules/blackjack/server.lua`) runs an authoritative loop on the server. When a round starts, `StartCasinoGameplayTransaction` fires; when it ends, `EndCasinoGameplayTransaction` fires. Listeners in `modules/casino/server.lua` compute net P/L and log one transaction row to `pickle_casino_transactions`.
5. **Lucky Tickets** — `modules/lucky_ticket/server.lua` tracks cumulative chip wagers per-player in MySQL and awards `lucky_ticket` inventory items when thresholds are crossed.
6. **Ambient audio** — `modules/audiozones/client.lua` uses `ox_lib` polygon zones to detect player entry/exit and plays GTA audio banks/streams.
7. **Casino templates** — `templates/*.lua` define pre-built casino layouts (entity coords + map objects JSON). They register into the shared `Templates` table and appear in the in-game editor's template picker.

### Conventions

- **Lua 5.4** (`lua54 'yes'` in manifest).
- Global `Casinos` table on both client and server, keyed by numeric casino ID.
- Server-side chip counts are derived from inventory item counts (`casino.settings.chipItem`), not a separate balance field.
- `_L(key, ...)` for all player-facing strings; missing key returns `ERR_TRANSLATE_<key>_404`.
- `debugPrint(...)` respects `Config.Debug` and is the preferred logging helper.
- `AddCasinoTransaction` writes to `pickle_casino_transactions` and pushes to management viewers only (not all clients).
- `RegisterManagementViewer` / `UnregisterManagementViewer` track which sources are viewing the management UI, used for targeted event pushes.

---

## Important files

| Path | Why it matters |
|---|---|
| `fxmanifest.lua` | Resource manifest; defines load order, escrow exemptions, and streamed assets. |
| `config.lua` | All shared/client configuration (chip denominations, game timers, admin groups, ambient audio presets, slot machine definitions, horse racing config, etc.). |
| `config_sv.lua` | Server-only config: Discord webhook URLs and the `WebhookHandler` function. |
| `core/shared.lua` | Shared utility functions (`lerp`, `v3`, `NumberWithCommas`, `GetRandomInt`, `debugPrint`, etc.) and the `Templates` global. |
| `core/server.lua` | Server utility functions: identifier helpers, `TriggerClientCasinoEvent`, `StartCasinoGameplayTransaction`, `EndCasinoGameplayTransaction`. |
| `core/client.lua` | Client utilities: entity creation helpers (`CreateNPC`, `CreateProp`), interaction system (`CreateInteraction`/`DeleteInteraction`), blip helpers, editor focus management. |
| `modules/casino/server.lua` | Central server module: `Casinos` table management, `RegisterCasino`, `CanManageCasino`, `InitializeCasinoEntity`, transaction logging (`AddCasinoTransaction`), management viewer tracking, paged transaction callbacks, gameplay transaction event handlers. |
| `modules/casino/client.lua` | Central client module: `RegisterCasino`, `StartCasinoManagement`, `ExitCasinoManagement`, NUI callback handlers, dealer ped creation, casino editor start/stop. |
| `modules/cashier/server.lua` | Chip buy/sell logic; updates `casino.balance` and `casino.marked_balance`, logs deposit/withdraw transactions, fires Discord webhooks. |
| `modules/lucky_ticket/server.lua` | Cumulative wager tracking, ticket award logic, `ConsumeLuckyTicket`/`HasLuckyTicket` helpers, `/setwheelticket` admin command. |
| `modules/audiozones/client.lua` | Polygon audio zone management via `ox_lib`; starts/stops GTA audio banks on zone entry/exit. |
| `modules/audiozones/server.lua` | Persists audio zone data to the casino settings in the DB; syncs zone changes to all clients. |
| `bridge/esx/server.lua` | ESX server bridge: `GetIdentifier`, `AddMoney`, `RemoveMoney`, `GetMoney`, `IsPlayerAdmin`, `AddSocietyMoney`, `Inventory` fallback. |
| `bridge/qb/server.lua` | QBCore server bridge: same interface as ESX bridge. |
| `bridge/esx/client.lua` | ESX client bridge: `ShowNotification`, `ServerCallback`, `CanAccessGroup`, inventory fallback. |
| `bridge/qb/client.lua` | QBCore client bridge. |
| `bridge/custom/client.lua` | Stub for custom framework — operators fill this in. |
| `bridge/custom/server.lua` | Stub for custom framework — operators fill this in. |
| `bridge/target/ox_target/client.lua` | ox_target bridge for interaction zones. |
| `locales/locale.lua` | `_L()` helper and `Language` table loader. |
| `locales/translations/en.lua` | All English player-facing strings. |
| `templates/*.lua` | Pre-built casino layouts for popular map resources (gabz, k4mb1, molo, patoche, energy, jurassic). |
| `modules/blackjack/server.lua` | Full authoritative Blackjack game loop; illustrates the pattern all table games follow. |
| `modules/slots/server.lua` | Slot machine RNG and payout logic. |
| `__INSTALL/Items/` | SQL/Lua snippets to register casino table items in each supported inventory. |
| `__INSTALL/Items/esx_limit.sql` / `esx_weight.sql` / `ox_inventory.lua` / `qbcore.lua` | Inventory item definitions for installation. |
| `nui/assets/index-*.js` / `index-*.css` | Compiled NUI bundle (do not edit directly; source is `web/`). |
| `web/` | NUI source (Vite + React). Build via `pnpm build` (do NOT run in this sandbox). |
| `mapobjects.json` | Static map object definitions used by the in-game prop scanner (`/mapobjects` command). |
| `peds.meta` / `stream/` | Custom ped and prop streaming assets (horse, casino tables, slot machines, wheel). |

---

## Intended behaviors

These look like bugs but are deliberate:

1. **Double escrow blocks**: `fxmanifest.lua` lists `templates.lua` (singular, non-existent file) alongside `templates/*.lua` in `escrow_ignore`. The singular entry is harmless (the file doesn't exist) and does not break anything.

2. **`casino.balance` is NOT touched during gameplay rounds**: `StartCasinoGameplayTransaction` and `EndCasinoGameplayTransaction` listeners in `modules/casino/server.lua` intentionally do **not** modify `casino.balance`. Balance only changes at the cashier (chip buy adds to balance; chip sell subtracts from balance). The game-round listeners only write a P/L log row to `pickle_casino_transactions`. Comments in the code explain this explicitly. Touching the balance in both places would double-count revenue/costs.

3. **`Config.IdentifierPrefix` referenced but not in `config.lua`**: `core/server.lua:GetPlayerPrefixIdentifier` reads `Config.IdentifierPrefix`. This key is not defined in the public `config.lua` — it is expected to be set by the operator (or the escrow'd portion of the code) if prefix-based identifier lookups are needed. The function falls back gracefully if the prefix is nil.

4. **Hardcoded `PERSONAL_CASINOS_LABEL`**: Referenced across client and server files as the sentinel label for a special "personal casinos" casino type. This string must not be changed without coordinating across all usages. It is set in an escrow'd portion of the code not visible in the open files.

5. **Audio zone audio banks hardcoded in `modules/audiozones/client.lua`**: Despite `Config.AmbientAudio` defining per-preset banks, the `StartAmbientAudio` function in the client module hardcodes the four DLC casino banks. This means custom audio presets defined in `config.lua` will load those same four banks regardless of what the preset specifies. The preset config is used for the stream/streamRef/audioScene fields only. This is a known limitation, not a bug to "fix" without understanding the intent.

6. **`Config.Debug` zone rendering**: When `Config.Debug = true`, all poly zones render their debug outlines via `ox_lib`. This is intentional and used for server-side zone debugging. Do not treat visible zone overlays as broken on debug servers.

7. **Cooldown kick**: `PerformCooldownProcess` in `modules/casino/server.lua` drops players who exceed `Config.CooldownTime` (default 10) sequential game actions per second. Players on laggy connections may be kicked. This is an anti-spam measure, not a bug.

8. **`taxRecipients` must sum to 100**: The code distributes tax proportionally but does not validate the sum. If configured incorrectly by an operator, tax payouts will be wrong. This is a config pitfall, not a code bug.

9. **Webhook silent-skip**: `ConfigSV.WebhookHandler` silently returns if `webhook.url == "DISCORD_WEBHOOK_URL"` (the placeholder). This is intentional — it means unconfigured webhooks simply don't fire rather than erroring.

10. **`AddMoney`/`RemoveMoney` in QBCore bridge reference undefined `money` variable**: In `bridge/qb/server.lua`, `AddMoney` and `RemoveMoney` call `TriggerClientEvent("pickle_casinos:updateMoney", source, money)` where `money` is not defined in those functions (only in `GetMoney`). This means the client-side money display may not update correctly after add/remove on QBCore. This is a pre-existing quirk and not something to "fix" without testing the full money-update flow.

---

## Common issues & fixes

| Symptom | Cause | Fix |
|---|---|---|
| All UI labels show as `ERR_TRANSLATE_<key>_404` | Resource folder name does not match exactly. Must be `pickle_casinos` (plural). | Rename the resource folder to `pickle_casinos` exactly and update `server.cfg`. |
| `Config.Language` mismatch | `Config.Language` key doesn't match the key in `locales/translations/*.lua` (e.g. `"en"` must match `Language["en"] = {...}`). | Ensure both match exactly. |
| Casino entities not rendering / invisible | `Config.RenderDistance` too low, or the entity's `location.coords` are wrong in the DB. | Increase `Config.RenderDistance` or teleport to the entity via the management panel and verify coords. |
| Players can't buy chips | `casino.settings.cashEnabled` or `casino.settings.markedEnabled` is `false`, or `casino.balance` is 0 (for owned casinos with no funds). | Open management panel → Settings and enable the relevant currency option. For unowned casinos, the balance cap is `Config.MaximumChipPurchaseAmount`. |
| Tax payouts fail silently on QBCore | `Config.FrameworkSettings.society` is set to a resource that isn't running (`qb-management` or `qb-banking`). | Set `Config.FrameworkSettings.society` to the correct running resource name. |
| Lucky Tickets never awarded | `Config.LuckyTicket.enabled = false`, the game type is missing from `eligibleGames`, or `chipsPerTicket` is higher than typical wagers. | Check each field in `Config.LuckyTicket`. |
| Lucky Ticket DB errors on first boot | `pickle_casino_ticket_progress` table doesn't exist. | Run the resource's SQL install file that creates this table. |
| Poker/Blackjack/Roulette tables don't appear | Item (e.g. `blackjack_table`) not registered in the inventory. | Add the item definitions from `__INSTALL/Items/` to your inventory resource. |
| Slot machine bonus music doesn't play | NUI audio files missing from `nui/audio/<machinename>/`. | Ensure the committed `nui/audio/` files are present (they ship with the resource). |
| Ambient audio zone not triggering | Zone has fewer than 3 points, or `ox_lib` isn't started before `pickle_casinos`. | Add at least 3 points to the zone in the editor; confirm `ox_lib` start order in `server.cfg`. |
| Management transactions panel is empty | `pickle_casino_transactions` table missing, or `mysql-async` not connected. | Verify DB connection and that the transactions table was created by the SQL install. |
| Target interactions not appearing | `Config.UseTarget = true` but no supported target resource (`ox_target`, `qb-target`, `qtarget`) is running. | Either start a supported target resource or set `Config.UseTarget = false`. |
| Horse racing track shows wrong location | `Config.HorseRacing.tracks` coords don't match the server's map. | Edit track coords in `config.lua` to match the actual world position. |
| `PERSONAL_CASINOS_LABEL` references break | The escrow'd section of code that sets this constant isn't loaded (resource not started properly). | Ensure the full resource is loaded — this constant is defined in the protected (escrow'd) code section. |

---

## Conventions

### Naming
- Config keys: `PascalCase` for top-level (`Config.MaxWager`), `camelCase` for nested fields (`vipExpireTime`, `taxRecipients`).
- Lua functions: `PascalCase` for public/global functions (`RegisterCasino`, `AddCasinoChips`), `camelCase` locals.
- Network events: `pickle_casinos:<module>:<action>` (e.g. `pickle_casinos:blackjack:updateStage`).
- NUI callbacks: `camelCase` verb+noun (e.g. `getCasinoTransactions`, `updateCasinoSetting`).
- Module files follow a consistent trio: `modules/<name>/client.lua`, `modules/<name>/server.lua`, `modules/<name>/shared.lua`.

### Style
- Lua 5.4 (`lua54 'yes'`). Use `//` only in JS/NUI; use `--` in Lua.
- Prefer `Wait(n)` inside `CreateThread` over `SetTimeout` for sequential game loops.
- `SetTimeout` is used for small delayed callbacks that don't need a full thread.
- All player-facing strings must go through `_L(key)` — never hardcode UI text.
- Guard every server event handler: validate `source`, check casino existence, check permissions before acting.
- Database writes use `MySQL.Async.execute` for fire-and-forget updates and `MySQL.insert.await` / `MySQL.query.await` (via `mysql-async`) for reads that need results.

### Adding a new game module
1. Create `modules/<name>/client.lua`, `server.lua`, `shared.lua`.
2. Add `InitializeXxxEntity`, `CreateXxxEntity`, `JoinXxxEntity` functions following the existing game pattern.
3. Wire into `InitializeCasinoEntity` (server) and `CreateCasinoEntity` (client) dispatch tables.
4. Add game timing to `Config.GameTimes` in `config.lua`.
5. Add locale keys to `locales/translations/en.lua`.
6. Call `StartCasinoGameplayTransaction` / `EndCasinoGameplayTransaction` to log rounds.
7. Call `RegisterLuckyTicketWager` at wager time if the game should count toward Lucky Tickets.

### PR rules
- Do NOT compile the NUI (`web/`) in the sandbox. If NUI source is changed, rely on CI/GitHub Actions to rebuild and commit `nui/assets/`.
- Do NOT touch `fxmanifest.lua` version — Tebby bumps it automatically.
- Do NOT modify files in `nui/assets/` directly; edit `web/src/` instead.
- Escrow-exempt files are listed in `fxmanifest.lua` under `escrow_ignore`; changes to those files are safe to make and will be visible to operators.
