# TEBBY.md - pickle_casinos

## Overview
pickle_casinos is a FiveM resource by Pickle Mods that adds player-owned casinos
with eight game types (blackjack, baccarat, roulette, thunder roulette, poker,
wheel, horse racing, slots), plus a lucky wheel, per-casino stores, VIP
memberships, an in-game chip economy, employee management, and ambient audio
zones. Casinos are created and configured entirely in-game by admins; gameplay
runs server-authoritatively and is animated on the client. It ships ESX and
QBCore bridges (with a custom stub) and depends on `ox_lib` and `mysql-async`.

## Code design
The resource is organised as a manifest-loaded set of modules under `modules/`,
each split into `shared.lua` / `client.lua` / `server.lua`, glued together by a
framework bridge under `bridge/`. Load order is defined in `fxmanifest.lua`:
`@ox_lib/init.lua` first, then config, core, locales, templates, then the bridge,
then modules, then `core/server.lua` / `core/client.lua`.

The bridge abstracts every framework-specific call behind global functions
(`AddMoney`, `GetIdentifier`, `IsPlayerAdmin`, `Inventory.*`, notifications,
callbacks, …) so module code never calls ESX/QBCore directly. Each bridge file
early-returns unless its framework is the running one, so exactly one framework
bridge loads.

Client↔server request/response goes through two conventions. The newer, preferred
one is `ox_lib` callbacks (`lib.callback.register` on the server, `lib.callback` /
`lib.callback.await` on the client) — used by the employees subsystem and the
management transaction/profit queries. The older one is the bridge's own
`RegisterCallback(name, function(source, cb, ...))` / `ServerCallback(name, cb,
...)` pair; as of the callback fix these bridge wrappers are themselves
implemented on top of `lib.callback`, so all callbacks are framework-agnostic and
no longer depend on the ESX/QBCore callback API version. State-push updates use
plain `TriggerClientEvent` / `TriggerServerEvent`.

## Important files
| Path | Why it matters |
| --- | --- |
| `fxmanifest.lua` | Load order, `escrow_ignore` list, ui_page, data_files, lua54. |
| `config.lua` / `config_sv.lua` | Shared/client config and server-only (webhook) config. |
| `core/shared.lua` / `core/client.lua` / `core/server.lua` | Bootstrap and shared helpers loaded around the modules. |
| `bridge/esx/*.lua`, `bridge/qb/*.lua`, `bridge/custom/*.lua` | Framework adapters; the callback wrappers `RegisterCallback`/`ServerCallback` live here. |
| `bridge/target/*/client.lua` | ox_target / qb-target / qtarget adapters. |
| `bridge/xp/*.lua` | Optional pickle_xp integration. |
| `modules/<game>/server.lua` & `client.lua` | Per-game logic; server is authoritative for outcomes and payouts. |
| `modules/casino/server.lua` | Casino registry, management callbacks, transaction logging, gameplay P/L accounting. |
| `modules/casino/employees_*.lua` | Employee callbacks already using `lib.callback` (reference for the framework-agnostic pattern). |
| `locales/locale.lua` + `locales/translations/*.lua` | Localization loader and strings; `_L(name, ...)` returns `ERR_TRANSLATE_<name>_404` on a miss. |

## Intended behaviors
- **Casino balance is not touched on game start/end.** In `modules/casino/server.lua`
  the `startTransaction` / `endTransaction` handlers deliberately do NOT move
  `casino.balance`; real cash moves only at the cashier buy/sell. Commented
  extensively — touching it re-introduces a double-count bug. Not a bug.
- **Escrow.** `fxmanifest.lua` has an `escrow_ignore` list. Files listed there
  (config, core, bridge, locales) are the customer-editable surface; other files
  ship encrypted under FiveM escrow. Edit the ignored files freely; do not assume
  you can read escrowed ones.
- **Bridges early-return by framework.** Each `bridge/<fw>/*.lua` starts with a
  `GetResourceState(...) ~= 'started' then return end` guard. This is intentional
  single-framework selection, not dead code.
- **`esx_skin` callbacks stay on ESX.** `bridge/esx/client.lua` still calls
  `ESX.TriggerServerCallback('esx_skin:getPlayerSkin', ...)` — those target an
  external resource, not this one, so they correctly remain on the ESX API.
- No hardcoded-name/anti-tamper self-checks were found in the bridge/config/core
  source that is readable.

## Common issues & fixes
- **Locales show `ERR_TRANSLATE_..._404` or raw keys.** Usually the resource
  folder is misnamed (must be `pickle_casinos`, not `pickle_casino`) or
  `Config.Language` doesn't match a file key in `locales/translations/`.
- **Callbacks silently fail on newer ESX Legacy.** Root cause of the callback fix:
  the ESX callback API signature changed. All callbacks now route through
  `lib.callback` via the bridge wrappers, so this should no longer recur; ensure
  `ox_lib` is started before `pickle_casinos`.
- **Nothing works / `lib` is nil.** `@ox_lib/init.lua` must load first — keep it as
  the first `shared_script` and start ox_lib before this resource.
- **Item images missing / chips not usable.** Inventory items from `__INSTALL/`
  must exist; set `Config.ImageDirectory` to match your inventory.

## Conventions
- Never call ESX/QBCore directly from `modules/`; add or use a bridge function.
- For new client↔server request/response, use `lib.callback.register` (server,
  `return` the result) and `lib.callback` / `lib.callback.await` (client). The
  legacy `RegisterCallback(source, cb, ...)` pattern still works via the bridge but
  is not the pattern for new code.
- Keep each module split into `shared.lua` / `client.lua` / `server.lua` and let
  the `modules/**` manifest globs pick them up; keep the server authoritative for
  game outcomes and money.
- Respect `escrow_ignore` — edit config/core/bridge/locales; do not add logic that
  assumes escrowed files are editable.
- Do not bump the `version` field in `fxmanifest.lua` by hand.
