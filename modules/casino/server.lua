CurrentPlayers = {}

function CanManageCasino(source, casinoId)
    if IsPlayerAdmin(source) then return true end
    if not casinoId then return false end
    local casino = Casinos[casinoId]
    if not casino then return false end
    if casino.owner_identifier and casino.owner_identifier == GetIdentifier(source) then return true end
    return false
end

function InitializeCasinoEntity(casinoId, entity, dataOnly)
    entity.settings = EnsureGameSettings(entity.type, entity.settings)
    if entity.type == "blackjack" then
        entity = InitializeBlackjackEntity(casinoId, entity, dataOnly)
    elseif entity.type == "roulette" then
        entity = InitializeRouletteEntity(casinoId, entity, dataOnly)
    elseif entity.type == "baccarat" then
        entity = InitializeBaccaratEntity(casinoId, entity, dataOnly)
    elseif entity.type == "slot" then
        entity = InitializeSlotEntity(casinoId, entity, dataOnly)
    elseif entity.type == "poker" then
        entity = InitializePokerEntity(casinoId, entity, dataOnly)
    elseif entity.type == "wheel" then
        entity = InitializeWheelEntity(casinoId, entity, dataOnly)
    elseif entity.type == "horseracing" then
        entity = InitializeHorseRacingEntity(casinoId, entity, dataOnly)
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
    if tonumber(newSettings.moneyExchangeRate or "a") == nil then newSettings.moneyExchangeRate = 100 end
    if tonumber(newSettings.dirtyExchangeRate or "a") == nil then newSettings.dirtyExchangeRate = 75 end
    return newSettings
end

function EnsureCasinoTransactions(transactions)
    local expireTime = os.time() - (86400 * 7)
    local newTransactions = {}
    -- for i=1, #transactions do
    --     local transaction = transactions[i]
    --     if transaction and transaction.datetime then
    --         if transaction.datetime > expireTime then
    --             table.insert(newTransactions, transaction)
    --         end
    --     end
    -- end
    local time = os.time()
    for i=1, 10 do 
        newTransactions[i] = {
            origin = {
                identifier = "steam:123456789",
                name = "John Doe " .. i,
            },
            type = math.random(1, 2) == 1 and "deposit" or "withdraw",
            amount = math.random(1, 1000),
            datetime = time,
        }
        time = time - 86400
    end
    return newTransactions
end

function RegisterCasino(id, data, dontSync)
    Casinos[id] = {
        id = id,
        balance = data.balance or 0,
        marked_balance = data.marked_balance or 0,
        owner_identifier = data.owner_identifier or nil,
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

function GenerateCard() 
    local classes = {"spd", "club", "dia", "hrt"}
    local values = {"ace", "02", "03", "04", "05", "06", "07", "08", "09", "10", "jack", "queen", "king"}
    -- return { class = classes[1], value = values[1] }
    return { class = classes[math.random(1, #classes)], value = values[math.random(1, #values)] }
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
    }
    if entityType == "blackjack" or entityType == "roulette" or entityType == "baccarat" or entityType == "slot" or entityType == "wheel" or entityType == "horseracing" then
        defaultSettings["maxWager"] = settings.maxWager or 1000
    end
    if entityType == "blackjack" or entityType == "roulette" or entityType == "baccarat" or entityType == "poker" then
        defaultSettings["tableModel"] = settings.tableModel
        defaultSettings["dealerModel"] = settings.dealerModel
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
        })
    end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET entities = ? WHERE id = ?', {json.encode(entities), casinoId})
end

RegisterCallback("pickle_casinos:joinEntity", function(source, casinoId, entityId)
    JoinCasinoEntity(source, casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:initializePlayer", function()
    TriggerClientEvent("pickle_casinos:syncCasinos", source, Casinos)
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
    }
    MySQL.insert('INSERT INTO `pickle_casinos` (settings, entities, transactions) VALUES (?, ?, ?)', {
        json.encode(casinoSettings), "[]", "[]"
    }, function(id)
        RegisterCasino(id, {
            id = id,
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
    elseif variable == "chipItem" then
        casino.settings.chipItem = tostring(value) or "INVALID_CHIP_ITEM"
    elseif variable == "blipEnabled" then
        casino.settings.blipEnabled = value and true or false
    elseif variable == "location" then
        if not value or not value.coords or not value.rotation then return end
        casino.settings.location = value
    elseif variable == "moneyExchangeRate" then
        casino.settings.moneyExchangeRate = tonumber(value) or 100
    elseif variable == "dirtyExchangeRate" then
        casino.settings.dirtyExchangeRate = tonumber(value) or 75
    end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET settings = ? WHERE id = ?', {json.encode(casino.settings), casinoId})
    TriggerClientEvent("pickle_casinos:updateCasinoSetting", -1, casinoId, variable, value)
end)

RegisterNetEvent("pickle_casinos:createCasinoEntity", function(casinoId, entityType, settings)
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    local entityId = GenerateEntityId(casinoId)
    local entity = {
        id = entityId,
        type = entityType,
        settings = EnsureGameSettings(entityType, settings),
    }
    table.insert(casino.entities, entity)
    UpdateCasinoEntitiesSQL(casinoId)
    InitializeCasinoEntity(casinoId, entity)
    TriggerClientEvent("pickle_casinos:createCasinoEntity", -1, casinoId, entity)
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    for i=1, #casino.entities do
        if casino.entities[i].id == entityId then
            table.remove(casino.entities, i)
            break
        end
    end
    UpdateCasinoEntitiesSQL(casinoId)
    TriggerClientEvent("pickle_casinos:deleteCasinoEntity", -1, casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:updateCasinoEntitySetting", function(casinoId, entityId, variable, value)
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
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
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    local targetCasino = Casinos[transferInfo.targetCasinoId]
    if not targetCasino then return end
    casino.balance = casino.balance - transferInfo.amount
    targetCasino.balance = targetCasino.balance + transferInfo.amount
    MySQL.Async.execute('UPDATE `pickle_casinos` SET balance = ? WHERE id = ?', {casino.balance, casinoId})
    MySQL.Async.execute('UPDATE `pickle_casinos` SET balance = ? WHERE id = ?', {targetCasino.balance, transferInfo.targetCasinoId})
    TriggerClientEvent("pickle_casinos:syncCasinos", -1, Casinos)
end)

RegisterCommand("casinos", function(source, args, raw)
    if not CanManageCasino(source) then return ShowNotification(source, _L("no_permission")) end
    TriggerClientEvent("pickle_casinos:casinosMenu", source)
end)

CreateThread(function() 
    MySQL.Async.fetchAll("SELECT * FROM `pickle_casinos`", {}, function(results)
        for i=1, #results do
            local result = results[i]
            local settings = json.decode(result.settings)
            local entities = json.decode(result.entities)
            local transactions = json.decode(result.transactions)
            RegisterCasino(result.id, {
                id = result.id,
                balance = result.balance,
                marked_balance = result.marked_balance,
                owner_identifier = result.owner_identifier,
                settings = settings,
                entities = entities,
                transactions = transactions,
            }, true)
        end
    end)
end)