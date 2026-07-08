CurrentPlayers = {}
PlayerCooldowns = {}

function GetCasino(casinoId)
    return Casinos[casinoId]
end

exports("GetCasino", GetCasino)

function EnsureOwnerInfo(owner_info)
    if not owner_info then return nil end
    if owner_info.identifier and not owner_info.type then
        owner_info.type = "player"
    end
    return owner_info
end

function IsCasinoOwned(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return false end
    local oi = casino.owner_info
    if not oi then return false end
    if oi.type == "job" and oi.job then return true end
    if oi.identifier and oi.identifier ~= "none" then return true end
    return false
end

function IsCasinoPersonalCasinos(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return false end
    if casino.settings.label == PERSONAL_CASINOS_LABEL then return true end
    return false
end

function CanManageCasino(source, casinoId)
    if IsPlayerAdmin(source) then return true end
    if not casinoId then return false end
    local casino = Casinos[casinoId]
    if not casino then return false end
    local oi = casino.owner_info
    if not oi then return false end
    if oi.type == "job" then
        if not oi.job then return false end
        if type(IsPlayerJobBoss) ~= "function" then return false end
        return IsPlayerJobBoss(source, oi.job) and true or false
    end
    if oi.identifier and oi.identifier == GetIdentifier(source) then return true end
    return false
end

function InitializeCasinoEntity(casinoId, entity, dataOnly)
    entity.settings = EnsureGameSettings(entity.type, entity.settings)
    if entity.type == "blackjack" then
        entity = InitializeBlackjackEntity(casinoId, entity, dataOnly)
    elseif entity.type == "roulette" then
        entity = InitializeRouletteEntity(casinoId, entity, dataOnly)
    elseif entity.type == "thunder_roulette" then
        entity = InitializeThunderRouletteEntity(casinoId, entity, dataOnly)
    elseif entity.type == "baccarat" then
        entity = InitializeBaccaratEntity(casinoId, entity, dataOnly)
    elseif entity.type == "slot" then
        entity = InitializeSlotEntity(casinoId, entity, dataOnly)
    elseif entity.type == "poker" then
        entity = InitializePokerEntity(casinoId, entity, dataOnly)
    elseif entity.type == "wheel" then
        entity = InitializeWheelEntity(casinoId, entity, dataOnly)
    elseif entity.type == "luckywheel" then
        entity = InitializeLuckyWheelEntity(casinoId, entity, dataOnly)
    elseif entity.type == "horseracing" then
        entity = InitializeHorseRacingEntity(casinoId, entity, dataOnly)
    elseif entity.type == "cashier" then
        entity = InitializeCashierEntity(casinoId, entity, dataOnly)
    elseif entity.type == "store" then
        entity = InitializeStoreEntity(casinoId, entity, dataOnly)
    end
    return entity
end

function InitializeCasinoEntities(casinoId, entities)
    for i=1, #entities do
        entities[i] = InitializeCasinoEntity(casinoId, entities[i])
    end
    return entities
end

function EnsureCasinoSettings(settings)
    local newSettings = {}
    for k,v in pairs(settings) do
        newSettings[k] = v
    end
    if not newSettings.label then newSettings.label = "UNKNOWN_LABEL" end
    if not newSettings.location then newSettings.location = { coords = vector3(0, 0, 0), rotation = vector3(0, 0, 0) } end
    newSettings.location.coords = vector3(newSettings.location.coords.x, newSettings.location.coords.y, newSettings.location.coords.z)
    newSettings.location.rotation = vector3(newSettings.location.rotation.x, newSettings.location.rotation.y, newSettings.location.rotation.z)
    if not newSettings.chipItem then newSettings.chipItem = "UNKNOWN_CHIP_ITEM" end
    if not newSettings.blipEnabled then newSettings.blipEnabled = false end
    if not newSettings.isOpen then newSettings.isOpen = false end
    if not newSettings.cashEnabled then newSettings.cashEnabled = false end
    if not newSettings.markedEnabled then newSettings.markedEnabled = false end
    if tonumber(newSettings.moneyExchangeRate or "a") == nil then newSettings.moneyExchangeRate = 100 end
    if tonumber(newSettings.dirtyExchangeRate or "a") == nil then newSettings.dirtyExchangeRate = 75 end
    if tonumber(newSettings.vipPrice or "a") == nil then newSettings.vipPrice = 1000 end
    return newSettings
end

function EnsureCasinoTransactions(transactions)
    local expireTime = os.time() - (86400 * 7)
    local newTransactions = {}
    for i=1, #transactions do
        local transaction = transactions[i]
        if transaction and transaction.datetime then
            if transaction.datetime > expireTime then
                table.insert(newTransactions, transaction)
            end
        end
    end
    return newTransactions
end

function RegisterCasino(id, data, dontSync)
    Casinos[id] = {
        id = id,
        balance = data.balance or 0,
        marked_balance = data.marked_balance or 0,
        owner_info = EnsureOwnerInfo(data.owner_info) or nil,
        vip_players = data.vip_players or {},
        transactions = EnsureCasinoTransactions(data.transactions or {}),
        settings = EnsureCasinoSettings(data.settings),
        entities = InitializeCasinoEntities(id, data.entities or {})
    }
    if dontSync then return end
    TriggerClientEvent("pickle_casinos:registerCasino", -1, id, Casinos[id])
end

function JoinCasinoEntity(source, casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if entity.type == "blackjack" then
        JoinBlackjackEntity(source, casinoId, entityId)
    elseif entity.type == "roulette" then
        JoinRouletteEntity(source, casinoId, entityId)
    elseif entity.type == "baccarat" then
        JoinBaccaratEntity(source, casinoId, entityId)
    end
end

function GenerateDeck()
    local deck = {}
    local classes = {"spd", "club", "dia", "hrt"}
    local values = {"ace", "02", "03", "04", "05", "06", "07", "08", "09", "10", "jack", "queen", "king"}
    for i=1, #classes do
        for j=1, #values do
            table.insert(deck, { class = classes[i], value = values[j] })
        end
    end
    -- Randomize the deck
    for i = #deck, 2, -1 do
        local j = math.random(1, i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

function GenerateCard(deck) 
    local classes = {"spd", "club", "dia", "hrt"}
    local values = {"ace", "02", "03", "04", "05", "06", "07", "08", "09", "10", "jack", "queen", "king"}
    -- return { class = classes[1], value = values[6] }
    if deck then
        local index = math.random(1, #deck)
        local card = deck[index]
        table.remove(deck, index)
        return card, deck
    else
        return { class = classes[math.random(1, #classes)], value = values[math.random(1, #values)] }
    end
end

function GetCasinoEntity(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    for i=1, #casino.entities do
        if casino.entities[i].id == entityId then
            return casino.entities[i]
        end
    end
end

exports("GetCasinoEntity", GetCasinoEntity)

function SendCasinoEntityUpdate(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    TriggerClientEvent("pickle_casinos:updateCasinoEntity", -1, casinoId, entity)
end

function GenerateEntityId(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entityId
    repeat
        entityId = math.random(1, 9999999) .. "_" .. math.random(1, 9999999)
    until not GetCasinoEntity(casinoId, entityId)
    return entityId
end

function EnsureGameSettings(entityType, settings)
    local defaultSettings = {
        location = settings.location and {
            coords = vector3(settings.location.coords.x, settings.location.coords.y, settings.location.coords.z) or vector3(0, 0, 0),
            rotation = settings.location.rotation and vector3(settings.location.rotation.x, settings.location.rotation.y, settings.location.rotation.z) or vector3(0, 0, 0)
        } or {
            coords = vector3(0, 0, 0),
            rotation = vector3(0, 0, 0)
        },
        vip = settings.vip and true or false,
    }
    if entityType == "blackjack" or entityType == "roulette" or entityType == "thunder_roulette" or entityType == "baccarat" or entityType == "slot" or entityType == "wheel" or entityType == "horseracing" then
        defaultSettings["maxWager"] = settings.maxWager or 1000
        if Config.MaxWager and defaultSettings["maxWager"] > Config.MaxWager then
            defaultSettings["maxWager"] = Config.MaxWager
        end
    end
    if entityType == "blackjack" or entityType == "roulette" or entityType == "thunder_roulette" or entityType == "baccarat" or entityType == "poker" then
        defaultSettings["tableModel"] = settings.tableModel
        defaultSettings["dealerModel"] = settings.dealerModel
    end
    if entityType == "cashier" or entityType == "store" then
        defaultSettings["dealerModel"] = settings.dealerModel
    end
    if entityType == "luckywheel" then
        defaultSettings["wheelModel"] = settings.wheelModel
        defaultSettings["spinPrice"] = settings.spinPrice or 0
        defaultSettings["costsTickets"] = settings.costsTickets and true or false
        defaultSettings["vehicleLocation"] = settings.vehicleLocation and {
            coords = vector3(settings.vehicleLocation.coords.x, settings.vehicleLocation.coords.y, settings.vehicleLocation.coords.z) or vector3(0, 0, 0),
            rotation = vector3(settings.vehicleLocation.rotation.x, settings.vehicleLocation.rotation.y, settings.vehicleLocation.rotation.z) or vector3(0, 0, 0)
        } or { coords = vector3(0, 0, 0), rotation = vector3(0, 0, 0) }
    end
    if entityType == "store" then
        defaultSettings["store"] = settings.store or 1
    end
    if entityType == "slot" then
        defaultSettings["game"] = settings.game
    end
    if entityType == "poker" then
        defaultSettings["smallBlind"] = settings.smallBlind or 10
        defaultSettings["bigBlind"] = settings.bigBlind or 20
    end
    return defaultSettings
end

function UpdateCasinoEntitiesSQL(casinoId)
    local entities = {}
    for i=1, #Casinos[casinoId].entities do
        table.insert(entities, {
            id = Casinos[casinoId].entities[i].id,
            type = Casinos[casinoId].entities[i].type,
            settings = Casinos[casinoId].entities[i].settings,
            owner_info = Casinos[casinoId].entities[i].owner_info,
        })
    end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET entities = ? WHERE id = ?', {json.encode(entities), casinoId})
end

function GetPlayerCasinoInfo(source, casinoId)
    local casino = Casinos[casinoId]
    if not casino then return false end
    local identifier = GetIdentifier(source)
    for i=1, #casino.vip_players do
        if casino.vip_players[i].identifier == identifier then
            return casino.vip_players[i], i
        end
    end
    return { identifier = identifier, name = GetPlayerCharacterName(source) }, nil
end

function UpdateCasinoPlayerInfo(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET vip_players = ? WHERE id = ?', {json.encode(casino.vip_players), casinoId})
end

function IsPlayerCasinoVIP(source, casinoId)
    local casino = Casinos[casinoId]
    if not casino then return false end
    local player = GetPlayerCasinoInfo(source, casinoId)
    return player.startTime ~= nil
end

-- Sources currently viewing a casino's management UI, keyed by casinoId.
-- We push new-transaction events only to these, instead of broadcasting the
-- full history to every connected player like the old flow did.
ManagementViewers = ManagementViewers or {}

local function GetManagementViewers(casinoId)
    return ManagementViewers[casinoId] or {}
end

function RegisterManagementViewer(source, casinoId)
    if not casinoId then return end
    ManagementViewers[casinoId] = ManagementViewers[casinoId] or {}
    ManagementViewers[casinoId][source] = true
end

function UnregisterManagementViewer(source, casinoId)
    if casinoId then
        if ManagementViewers[casinoId] then
            ManagementViewers[casinoId][source] = nil
        end
        return
    end
    -- No casino specified — sweep the player out of every casino (used on
    -- disconnect so we don't leak dangling sources).
    for cid, viewers in pairs(ManagementViewers) do
        viewers[source] = nil
    end
end

AddEventHandler("playerDropped", function()
    UnregisterManagementViewer(source)
end)

-- Gameplay rounds (slots/blackjack/poker/etc) fire Start/EndCasinoGameplayTransaction
-- via core/server.lua. The previous build TriggerEvent'd those names but had no
-- listener, so the casino balance never moved and nothing got logged when a
-- player won or lost — which is exactly the bug reported. Track each round
-- between start and end so we can compute the net P/L for the house in one
-- log entry.
local PendingGameplayTransactions = {}

AddEventHandler("pickle_casinos:gameplay:startTransaction", function(id, source, casinoId, _entityId, gameType, wagerAmount)
    wagerAmount = tonumber(wagerAmount) or 0
    if wagerAmount <= 0 then return end
    PendingGameplayTransactions[id] = {
        source     = source,
        casinoId   = casinoId,
        gameType   = gameType,
        wagerAmount = wagerAmount,
    }
    -- NOTE: We intentionally do NOT touch casino.balance here. The real-money
    -- inflow was already accounted for when the player purchased chips at the
    -- cashier (buy handler). Crediting the balance again here would double-count
    -- the revenue before any actual cash has moved.
end)

AddEventHandler("pickle_casinos:gameplay:endTransaction", function(id, source, casinoId, _entityId, gameType, winAmount)
    winAmount = tonumber(winAmount) or 0
    local pending = PendingGameplayTransactions[id]
    PendingGameplayTransactions[id] = nil
    local wager = (pending and pending.wagerAmount) or 0
    -- NOTE: We intentionally do NOT touch casino.balance here. The real-money
    -- outflow is accounted for when the player redeems chips at the cashier
    -- (sell handler). Debiting the balance here would cause a double-debit:
    -- once when winning chips are issued, and again when those chips are cashed
    -- out — which is exactly the bug this fix resolves.
    --
    -- Net P/L for the house from this round. One log row, not two, so high-
    -- volume games (slots) don't flood the transactions list.
    local net = wager - winAmount
    if net > 0 then
        AddCasinoTransaction(source, casinoId, gameType .. "_deposit", net)
    elseif net < 0 then
        AddCasinoTransaction(source, casinoId, gameType .. "_withdraw", -net)
    end
end)

function AddCasinoTransaction(source, casinoId, transactionType, amount)
    local casino = Casinos[casinoId]
    if not casino then return end
    local transaction = {
        origin = {
            identifier = GetIdentifier(source),
            name = GetPlayerCharacterName(source),
        },
        type = transactionType,
        amount = amount,
        datetime = os.time(),
    }
    local insertedId = MySQL.insert.await(
        "INSERT INTO `pickle_casino_transactions` (`casino_id`, `identifier`, `name`, `type`, `amount`, `datetime`) VALUES (?, ?, ?, ?, ?, ?)",
        {
            casinoId,
            transaction.origin.identifier or "",
            transaction.origin.name or "",
            transaction.type,
            transaction.amount,
            transaction.datetime,
        }
    )
    transaction.id = insertedId
    -- Targeted push: only sources currently in the management UI for this
    -- casino need to know. Everyone else doesn't care and shouldn't pay the
    -- bandwidth.
    for src, _ in pairs(GetManagementViewers(casinoId)) do
        TriggerClientEvent("pickle_casinos:newCasinoTransaction", src, casinoId, transaction)
    end
end

function GetCasinoChips(source, casinoId)
    local casino = Casinos[casinoId]
    if not source then return 0 end
    if not casino then return 0 end
    if casino.settings.label == PERSONAL_CASINOS_LABEL then 
        return GetMoney(source)
    end
    local chips = Inventory.GetItemCount(source, casino.settings.chipItem) or 0
    return chips
end

function AddCasinoChips(source, casinoId, amount)
    local casino = Casinos[casinoId]
    if not casino then return end
    if casino.settings.label == PERSONAL_CASINOS_LABEL then 
        return AddMoney(source, amount)
    end
    Inventory.AddItem(source, casino.settings.chipItem, amount)
end

function RemoveCasinoChips(source, casinoId, amount)
    local casino = Casinos[casinoId]
    if not casino then return end
    if casino.settings.label == PERSONAL_CASINOS_LABEL then 
        return RemoveMoney(source, amount)
    end
    Inventory.RemoveItem(source, casino.settings.chipItem, amount)
end

function UpdatePlayerBalance(source, casinoId, noDelay)
    local performUpdate = function()
        local balance = GetCasinoChips(source, casinoId)
        TriggerClientEvent("pickle_casinos:updateBalance", source, balance, casinoId)
    end
    if noDelay then
        performUpdate()
        return
    end
    SetTimeout(100, function()
        performUpdate()
    end)
end

function GetFormattedPlayer(source)
    local name = GetPlayerName(source)
    name = "**Name:** ".. name .. " (ID: " .. source .. ")\n**Identifiers:**\n`" .. json.encode(GetFilteredPlayerIdentifiers(source), {indent = true}) .. "`"
    return name
end

function PerformCooldownProcess(source)
    local source = tonumber(source)
    local threshold = Config.CooldownTime or 10
    local warningThreshold = threshold - 3
    local newCooldown = false
    if not PlayerCooldowns[source] then
        newCooldown = true
        PlayerCooldowns[source] = {
            cooldown = 0,
        }
    end
    if PlayerCooldowns[source] then 
        PlayerCooldowns[source].cooldown = PlayerCooldowns[source].cooldown + 1
        if PlayerCooldowns[source].cooldown == warningThreshold then
            ShowNotification(source, _L("cooldown_warning"))
        end
    end
    if newCooldown then
        SetTimeout(1000, function()
            if PlayerCooldowns[source] and PlayerCooldowns[source].cooldown >= threshold then
                DropPlayer(source, "Pickle Casinos: You have been kicked for spamming game actions.")
            end
            PlayerCooldowns[source] = nil
        end)
    end
end

RegisterCallback("pickle_casinos:getManagementStatus", function(source, cb, casinoId)
    return cb(CanManageCasino(source, casinoId))
end)

RegisterCallback("pickle_casinos:getPlayers", function(source, cb)
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        players[#players + 1] = {
            source = playerId,
            identifier = GetIdentifier(playerId),
            name = GetPlayerCharacterName(playerId),
        }
    end
    return cb(players)
end)

RegisterCallback("pickle_casinos:getVIPStatus", function(source, cb, casinoId)
    local playerInfo, playerIndex = GetPlayerCasinoInfo(source, casinoId)
    local vipStartTime = playerInfo.startTime
    if not vipStartTime then return cb(false) end
    if Config.Casinos.vipExpireTime > 0 and (vipStartTime + Config.Casinos.vipExpireTime) < os.time() then
        local casino = Casinos[casinoId]
        if not casino then return end
        if playerIndex then
            casino.vip_players[playerIndex].startTime = nil
            MySQL.Async.execute('UPDATE `pickle_casinos` SET vip_players = ? WHERE id = ?', {json.encode(casino.vip_players), casinoId})
        end
        return cb(false)
    end 
    return cb(true, {
        timeLeft = Config.Casinos.vipExpireTime > 0 and ((vipStartTime + Config.Casinos.vipExpireTime) - os.time()) or nil,
    })
end)

-- Whitelist of sortable columns so callers can't pass arbitrary SQL into
-- ORDER BY. Same shape as the indexed columns on pickle_casino_transactions.
local TRANSACTION_SORT_COLUMNS = {
    datetime   = "datetime",
    amount     = "amount",
    type       = "type",
    name       = "name",
}

local function escapeLike(s)
    if type(s) ~= "string" then return "" end
    return s:gsub("\\", "\\\\"):gsub("%%", "\\%%"):gsub("_", "\\_")
end

--- Paged, searchable, sortable transaction fetch. Replaces shipping the full
--- list in setManagementInfo. Caller gets back { rows, total } so the UI can
--- show a "loaded N of M" counter and stop scrolling when total is reached.
lib.callback.register("pickle_casinos:getCasinoTransactions", function(source, data)
    local casinoId = tonumber(data and data.casinoId)
    if not casinoId or not CanManageCasino(source, casinoId) then
        return { rows = {}, total = 0 }
    end

    local offset    = math.max(0, tonumber(data.offset) or 0)
    local limit     = math.max(1, math.min(200, tonumber(data.limit) or 50))
    local search    = type(data.search) == "string" and data.search or ""
    local typeFilter = type(data.type) == "string" and data.type or ""
    local sortBy    = TRANSACTION_SORT_COLUMNS[data.sortBy] or "datetime"
    local sortDir   = (type(data.sortDir) == "string" and data.sortDir:lower() == "asc") and "ASC" or "DESC"

    local where = { "`casino_id` = ?" }
    local params = { casinoId }

    if search ~= "" then
        table.insert(where, "(`name` LIKE ? ESCAPE '\\\\' OR `type` LIKE ? ESCAPE '\\\\')")
        local needle = "%" .. escapeLike(search) .. "%"
        table.insert(params, needle)
        table.insert(params, needle)
    end
    if typeFilter ~= "" then
        table.insert(where, "`type` = ?")
        table.insert(params, typeFilter)
    end

    local whereClause = table.concat(where, " AND ")

    local total = MySQL.scalar.await(
        "SELECT COUNT(*) FROM `pickle_casino_transactions` WHERE " .. whereClause,
        params
    ) or 0

    local pageParams = {}
    for i = 1, #params do pageParams[i] = params[i] end
    table.insert(pageParams, limit)
    table.insert(pageParams, offset)

    local rows = MySQL.query.await(
        ("SELECT `id`, `identifier`, `name`, `type`, `amount`, `datetime` FROM `pickle_casino_transactions` WHERE %s ORDER BY `%s` %s, `id` %s LIMIT ? OFFSET ?")
            :format(whereClause, sortBy, sortDir, sortDir),
        pageParams
    ) or {}

    -- Reshape to the {origin = { identifier, name }, ...} shape the existing
    -- client code consumed, so the chart helpers / row renderer don't need to
    -- learn a new schema.
    local out = {}
    for i = 1, #rows do
        local r = rows[i]
        out[i] = {
            id = r.id,
            origin = { identifier = r.identifier, name = r.name },
            type = r.type,
            amount = tonumber(r.amount) or 0,
            datetime = tonumber(r.datetime) or 0,
        }
    end
    return { rows = out, total = total }
end)

--- Server-side weekly profit so the chart doesn't need the full transaction
--- history client-side. Returns 7 buckets (oldest → newest, today inclusive),
--- each `{ date = 'YYYY-MM-DD', profit = number }`.
lib.callback.register("pickle_casinos:getCasinoWeeklyProfit", function(source, data)
    local casinoId = tonumber(data and data.casinoId)
    if not casinoId or not CanManageCasino(source, casinoId) then
        return {}
    end
    local startTs = os.time() - (86400 * 7)
    local rows = MySQL.query.await(
        "SELECT `type`, `amount`, `datetime` FROM `pickle_casino_transactions` WHERE `casino_id` = ? AND `datetime` >= ?",
        { casinoId, startTs }
    ) or {}

    -- Build seven daily buckets keyed by YYYY-MM-DD in server-local time so
    -- the labels line up with what the client sees in toLocaleDateString.
    local buckets = {}
    local order = {}
    for i = 6, 0, -1 do
        local ts = os.time() - (86400 * i)
        local key = os.date("%Y-%m-%d", ts)
        buckets[key] = { date = key, profit = 0 }
        order[#order + 1] = key
    end
    for _, r in ipairs(rows) do
        local key = os.date("%Y-%m-%d", tonumber(r.datetime) or 0)
        local b = buckets[key]
        if b then
            local amt = tonumber(r.amount) or 0
            if type(r.type) == "string" and r.type:find("withdraw") then
                b.profit = b.profit - amt
            else
                b.profit = b.profit + amt
            end
        end
    end
    local out = {}
    for i, key in ipairs(order) do out[i] = buckets[key] end
    return out
end)

RegisterNetEvent("pickle_casinos:enterManagement", function(casinoId)
    local src = source
    if not CanManageCasino(src, casinoId) then return end
    RegisterManagementViewer(src, casinoId)
end)

RegisterNetEvent("pickle_casinos:exitManagement", function(casinoId)
    UnregisterManagementViewer(source, casinoId)
end)

RegisterNetEvent("pickle_casinos:initializePlayer", function()
    local source = source
    TriggerClientEvent("pickle_casinos:syncCasinos", source, Casinos, GetIdentifier(source))
    TriggerClientEvent("pickle_casinos:setupInventory", source, {
        items = Inventory.Items,
    })
    UpdateHorseTracks(source)
    UpdateObjects(source)
end)

RegisterNetEvent("pickle_casinos:createCasino", function(data)
    if not type(data) == "table" then return end
    if not CanManageCasino(source) then return ShowNotification(source, _L("no_permission")) end
    local casinoSettings = {
        label = data.label or "UNKNOWN_LABEL",
        location = data.location or {
            coords = vector3(0, 0, 0),
            rotation = vector3(0, 0, 0)
        },
        chipItem = data.chipItem or "UNKNOWN_CHIP_ITEM",
        blipEnabled = data.blipEnabled or false,
        isOpen = true,
        cashEnabled = true,
        markedEnabled = true,
    }
    if casinoSettings.label == PERSONAL_CASINOS_LABEL then
        casinoSettings.label = "UNKNOWN_LABEL"
    end
    local entities = {}
    if data.template and data.template ~= "none" then
        local template = Templates[data.template]
        if template then
            entities = json.decode(template.entitiesJSON) or {}
            AddTemplateMapObjects(data.template, json.decode(template.objectsJSON) or {})
        end
    end 
    MySQL.insert('INSERT INTO `pickle_casinos` (settings, entities, transactions, vip_players) VALUES (?, ?, ?, ?)', {
        json.encode(casinoSettings), json.encode(entities), "[]", "[]"
    }, function(id)
        RegisterCasino(id, {
            id = id,
            entities = entities,
            settings = casinoSettings,
        })
    end)
end)

RegisterNetEvent("pickle_casinos:deleteCasino", function(casinoId)
    if not CanManageCasino(source) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    MySQL.Async.execute('DELETE FROM `pickle_casinos` WHERE id = ?', {casinoId})
    Casinos[casinoId] = nil
    TriggerClientEvent("pickle_casinos:deleteCasino", -1, casinoId)
end)

RegisterNetEvent("pickle_casinos:updateCasinoSetting", function(casinoId, variable, value)
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    if variable == "chipItem" and not CanManageCasino(source) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    if variable == "label" then
        casino.settings.label = tostring(value) or "INVALID_LABEL"
        if casino.settings.label == PERSONAL_CASINOS_LABEL then
            casino.settings.label = "INVALID_LABEL"
        end
    elseif variable == "chipItem" then
        casino.settings.chipItem = tostring(value) or "INVALID_CHIP_ITEM"
    elseif variable == "blipEnabled" then
        casino.settings.blipEnabled = value and true or false
    elseif variable == "isOpen" then
        casino.settings.isOpen = value and true or false
    elseif variable == "cashEnabled" then
        casino.settings.cashEnabled = value and true or false
    elseif variable == "markedEnabled" then
        casino.settings.markedEnabled = value and true or false
    elseif variable == "location" then
        if not value or not value.coords or not value.rotation then return end
        casino.settings.location = value
    elseif variable == "moneyExchangeRate" then
        casino.settings.moneyExchangeRate = tonumber(value) or 100
    elseif variable == "dirtyExchangeRate" then
        casino.settings.dirtyExchangeRate = tonumber(value) or 75
    elseif variable == "vipPrice" then 
        casino.settings.vipPrice = tonumber(value) or 1000  
    end
    casino.settings = EnsureCasinoSettings(casino.settings)
    MySQL.Async.execute('UPDATE `pickle_casinos` SET settings = ? WHERE id = ?', {json.encode(casino.settings), casinoId})
    TriggerClientEvent("pickle_casinos:updateCasinoSetting", -1, casinoId, variable, casino.settings[variable])
end)

RegisterNetEvent("pickle_casinos:updateCasinoOwner", function(casinoId, newOwner)
    local source = source
    if not IsPlayerAdmin(source) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    newOwner = newOwner or {}
    local ownerType = newOwner.type
    -- Backwards compatibility: legacy payload sent only {identifier, name}
    if not ownerType then
        if newOwner.identifier and newOwner.identifier ~= "none" then
            ownerType = "player"
        else
            ownerType = "none"
        end
    end
    if ownerType == "none" or newOwner.identifier == "none" then
        casino.owner_info = nil
    elseif ownerType == "job" then
        if not newOwner.job or newOwner.job == "" then
            return ShowNotification(source, _L("no_permission"))
        end
        casino.owner_info = {
            type = "job",
            job = tostring(newOwner.job),
            name = newOwner.name or tostring(newOwner.job),
        }
    else
        casino.owner_info = {
            type = "player",
            identifier = newOwner.identifier,
            name = newOwner.name,
        }
    end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET owner_info = ? WHERE id = ?', {json.encode(casino.owner_info), casinoId})
    TriggerClientEvent("pickle_casinos:updateCasinoOwner", -1, casinoId, casino.owner_info)
end)

RegisterNetEvent("pickle_casinos:createCasinoEntity", function(casinoId, entityType, settings)
    local source = source
    if not IsCasinoPersonalCasinos(casinoId) and not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    if IsCasinoPersonalCasinos(casinoId) then
        local placeableCfg = Config.PlaceableEntities[entityType]
        if not placeableCfg then return end
        local item = placeableCfg.item
        if Inventory.GetItemCount(source, item) < 1 then return end
        Inventory.RemoveItem(source, item, 1)
    end
    local entityId = GenerateEntityId(casinoId)
    local entity = {
        id = entityId,
        type = entityType,
        settings = EnsureGameSettings(entityType, settings),
    }
    if IsCasinoPersonalCasinos(casinoId) then
        entity.owner_info = {
            identifier = GetIdentifier(source),
            name = GetPlayerCharacterName(source)
        }
    end
    table.insert(casino.entities, entity)
    UpdateCasinoEntitiesSQL(casinoId)
    InitializeCasinoEntity(casinoId, entity)
    TriggerClientEvent("pickle_casinos:createCasinoEntity", -1, casinoId, entity)
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    local source = source
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casinoEntity then return end
    local isEntityOwner = (casinoEntity.owner_info and casinoEntity.owner_info.identifier == GetIdentifier(source))
    if not CanManageCasino(source, casinoId) and not isEntityOwner then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    local entityType = nil
    for i=1, #casino.entities do
        if casino.entities[i].id == entityId then
            entityType = casino.entities[i].type
            table.remove(casino.entities, i)
            break
        end
    end
    UpdateCasinoEntitiesSQL(casinoId)
    TriggerClientEvent("pickle_casinos:deleteCasinoEntity", -1, casinoId, entityId)
    if IsCasinoPersonalCasinos(casinoId) then
        local placeableCfg = Config.PlaceableEntities[entityType]
        if not placeableCfg then return end
        local item = placeableCfg.item
        Inventory.AddItem(source, item, 1)
    end
end)

RegisterNetEvent("pickle_casinos:updateCasinoEntitySetting", function(casinoId, entityId, variable, value)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casinoEntity then return end
    local isEntityOwner = (casinoEntity.owner_info and casinoEntity.owner_info.identifier == GetIdentifier(source))
    if not CanManageCasino(source, casinoId) and not isEntityOwner then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    entity.settings[variable] = value
    entity.settings = EnsureGameSettings(entity.type, entity.settings)
    InitializeCasinoEntity(casinoId, entity, true)
    UpdateCasinoEntitiesSQL(casinoId)
    TriggerClientEvent("pickle_casinos:updateCasinoEntitySetting", -1, casinoId, entityId, variable, entity.settings[variable])
end)

RegisterNetEvent("pickle_casinos:startCasinoTransfer", function(casinoId, transferInfo)
    local source = source
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    local transferType = transferInfo.type
    local balanceType = transferInfo.balanceType
    local amount = transferInfo.amount
    local money = GetMoney(source)
    local marked_money = GetMoney(source, "dirty")
    if amount <= 0 then return ShowNotification(source, _L("invalid_amount")) end
    if transferType == "deposit" then
        if balanceType == "balance" then
            if money < amount then return ShowNotification(source, _L("insufficient_funds")) end
            RemoveMoney(source, amount)
            casino.balance = casino.balance + amount
        elseif balanceType == "marked_balance" then
            if marked_money < amount then return ShowNotification(source, _L("insufficient_funds")) end
            RemoveMoney(source, amount, "dirty")
            casino.marked_balance = casino.marked_balance + amount
        end
        ShowNotification(source, _L("casino_deposited", NumberWithCommas(amount), casino.settings.label))
        AddCasinoTransaction(source, casinoId, "management_deposit", amount)
    elseif transferType == "withdraw" then
        if balanceType == "balance" then
            if casino.balance < amount then return ShowNotification(source, _L("insufficient_funds")) end
            casino.balance = casino.balance - amount
            local totalTax = math.floor(amount * (Config.Casinos.tax / 100))
            AddMoney(source, amount - totalTax)
            if totalTax > 0 then
                for k,v in pairs(Config.Casinos.taxRecipients) do
                    AddSocietyMoney(k, math.floor(totalTax * (v / 100)))
                end
                ShowNotification(source, _L("casino_tax", NumberWithCommas(totalTax)))
            end
        elseif balanceType == "marked_balance" then
            if casino.marked_balance < amount then return ShowNotification(source, _L("insufficient_funds")) end
            casino.marked_balance = casino.marked_balance - amount
            AddMoney(source, amount, "dirty")
        end
        AddCasinoTransaction(source, casinoId, "management_withdraw", amount)
        ShowNotification(source, _L("casino_withdrawn", NumberWithCommas(amount), casino.settings.label))
    end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET balance = ?, marked_balance = ? WHERE id = ?', {
        casino.balance,
        casino.marked_balance,
        casinoId
    })
    TriggerClientEvent("pickle_casinos:updateCasinoBalance", -1, casinoId, casino.balance, casino.marked_balance)
end)

RegisterCommand("casinos", function(source, args, raw)
    if not CanManageCasino(source) then return ShowNotification(source, _L("no_permission")) end
    TriggerClientEvent("pickle_casinos:casinosMenu", source)
end)

CreateThread(function() 
    for k,v in pairs(Config.PlaceableEntities) do 
        RegisterUsableItem(v.item, function(source)
            TriggerClientEvent("pickle_casinos:createPlacedEntity", source, k)
        end)
    end
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `pickle_casino_ticket_progress` (
            `identifier` VARCHAR(255) NOT NULL PRIMARY KEY,
            `wager_total` BIGINT NOT NULL DEFAULT 0,
            `tickets_earned` INT NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]], {})
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `pickle_casinos` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `owner_info` longtext DEFAULT NULL,
            `balance` int(11) NOT NULL DEFAULT 0,
            `marked_balance` int(11) NOT NULL DEFAULT 0,
            `settings` longtext NOT NULL,
            `vip_players` longtext NOT NULL,
            `transactions` longtext NOT NULL,
            `entities` longtext NOT NULL,
            PRIMARY KEY (`id`)
        )
    ]], {})

    -- Per-row transaction store. Replaces the JSON blob on pickle_casinos.transactions
    -- so the management UI can paginate / search / sort / aggregate server-side
    -- without ever loading the full history. The legacy `transactions` column on
    -- pickle_casinos is preserved (unread by the management flow) so a rollback
    -- of this resource still has the historical data to fall back on.
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `pickle_casino_transactions` (
            `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            `casino_id`  INT UNSIGNED    NOT NULL,
            `identifier` VARCHAR(64)     NOT NULL DEFAULT '',
            `name`       VARCHAR(128)    NOT NULL DEFAULT '',
            `type`       VARCHAR(64)     NOT NULL DEFAULT '',
            `amount`     BIGINT          NOT NULL DEFAULT 0,
            `datetime`   INT UNSIGNED    NOT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_casino_datetime` (`casino_id`, `datetime`),
            KEY `idx_casino_type`     (`casino_id`, `type`),
            KEY `idx_casino_name`     (`casino_id`, `name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function()
        -- 7-day retention parity with EnsureCasinoTransactions. Prune on boot
        -- so the table doesn't grow unbounded across restarts.
        MySQL.Async.execute(
            "DELETE FROM `pickle_casino_transactions` WHERE `datetime` < ?",
            { os.time() - (86400 * 7) }
        )

        MySQL.Async.fetchAll("SELECT * FROM `pickle_casinos`", {}, function(results)
            local personalCasinoFound = false
            for i=1, #results do
                local result = results[i]
                local settings = json.decode(result.settings) or {}
                local entities = json.decode(result.entities) or {}
                local legacyTransactions = json.decode(result.transactions) or {}
                local vip_players = json.decode(result.vip_players) or {}
                local owner_info = json.decode(result.owner_info) or nil
                if settings and settings.label == PERSONAL_CASINOS_LABEL then
                    personalCasinoFound = true
                end

                -- One-time backfill from the legacy JSON blob into the new
                -- per-row table. Only runs when no rows exist for the casino,
                -- so subsequent restarts are no-ops. We apply the same 7-day
                -- retention EnsureCasinoTransactions used before.
                local existing = MySQL.scalar.await(
                    "SELECT COUNT(*) FROM `pickle_casino_transactions` WHERE `casino_id` = ?",
                    { result.id }
                ) or 0
                if existing == 0 and #legacyTransactions > 0 then
                    local cutoff = os.time() - (86400 * 7)
                    for _, tx in ipairs(legacyTransactions) do
                        if tx and tx.datetime and tx.datetime > cutoff then
                            MySQL.insert.await(
                                "INSERT INTO `pickle_casino_transactions` (`casino_id`, `identifier`, `name`, `type`, `amount`, `datetime`) VALUES (?, ?, ?, ?, ?, ?)",
                                {
                                    result.id,
                                    (tx.origin and tx.origin.identifier) or "",
                                    (tx.origin and tx.origin.name) or "",
                                    tx.type or "",
                                    tonumber(tx.amount) or 0,
                                    tonumber(tx.datetime) or 0,
                                }
                            )
                        end
                    end
                end

                RegisterCasino(result.id, {
                    id = result.id,
                    balance = result.balance,
                    marked_balance = result.marked_balance,
                    owner_info = owner_info,
                    settings = settings,
                    entities = entities,
                    transactions = {}, -- transactions now live in pickle_casino_transactions
                    vip_players = vip_players,
                }, true)
            end
            if not personalCasinoFound then
                MySQL.insert('INSERT INTO `pickle_casinos` (settings, entities, transactions, vip_players) VALUES (?, ?, ?, ?)', {
                    json.encode({
                        label = PERSONAL_CASINOS_LABEL,
                        location = {
                            coords = vector3(0, 0, 0),
                            rotation = vector3(0, 0, 0)
                        },
                        chipItem = "UNKNOWN_CHIP_ITEM",
                        blipEnabled = false,
                        isOpen = true,
                        cashEnabled = true,
                        markedEnabled = true,
                    }), "[]", "[]", "[]"
                }, function(id)
                    RegisterCasino(id, {
                        id = id,
                        balance = 0,
                        marked_balance = 0,
                        owner_info = nil,
                        settings = {
                            label = PERSONAL_CASINOS_LABEL,
                            location = {
                                coords = vector3(0, 0, 0),
                                rotation = vector3(0, 0, 0)
                            },
                            chipItem = "UNKNOWN_CHIP_ITEM",
                            blipEnabled = false,
                            isOpen = true,
                            cashEnabled = true,
                            markedEnabled = true,
                        },
                        entities = {},
                        transactions = {},
                        vip_players = {},
                    }, true)
                end)
            end
        end)
    end)
end)