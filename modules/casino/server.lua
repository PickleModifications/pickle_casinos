CurrentPlayers = {}

function InitializeCasinoEntities(casinoId, entities)
    for i=1, #entities do
        local entity = entities[i]
        if entity.type == "blackjack" then
            entity = InitializeBlackjackEntity(casinoId, entity)
        elseif entity.type == "roulette" then
            entity = InitializeRouletteEntity(casinoId, entity)
        elseif entity.type == "baccarat" then
            entity = InitializeBaccaratEntity(casinoId, entity)
        elseif entity.type == "slot" then
            entity = InitializeSlotEntity(casinoId, entity)
        elseif entity.type == "poker" then
            entity = InitializePokerEntity(casinoId, entity)
        elseif entity.type == "wheel" then
            entity = InitializeWheelEntity(casinoId, entity)
        elseif entity.type == "horseracing" then
            entity = InitializeHorseRacingEntity(casinoId, entity)
        end
    end
    return entities
end

function RegisterCasino(id, data, dontSync)
    Casinos[id] = {
        id = id,
        owner_identifier = data.owner_identifier or nil,
        settings = data.settings,
        entities = InitializeCasinoEntities(id, data.entities or {})
    }
    if dontSync then return end
    TriggerClientEvent("pickle_casinos:registerCasino", -1, id, data)
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

local inc = 0

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

RegisterCallback("pickle_casinos:joinEntity", function(source, casinoId, entityId)
    JoinCasinoEntity(source, casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:initializePlayer", function()
    TriggerClientEvent("pickle_casinos:syncCasinos", source, Casinos)
end)

RegisterNetEvent("pickle_casinos:createCasino", function(data)
    if not type(data) == "table" then return end
    if not IsPlayerAdmin(source) then return ShowNotification(source, _L("no_permission")) end
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
            owner_identifier = nil,
            settings = casinoSettings,
            entities = {},
            transactions = {},
        })
    end)
end)

RegisterNetEvent("pickle_casinos:deleteCasino", function(casinoId)
    if not IsPlayerAdmin(source) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    MySQL.Async.execute('DELETE FROM `pickle_casinos` WHERE id = ?', {casinoId})
    Casinos[casinoId] = nil
    TriggerClientEvent("pickle_casinos:deleteCasino", -1, casinoId)
end)

RegisterNetEvent("pickle_casinos:updateCasinoSetting", function(casinoId, variable, value)
    if not IsPlayerAdmin(source) then return ShowNotification(source, _L("no_permission")) end
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
    end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET settings = ? WHERE id = ?', {json.encode(casino.settings), casinoId})
    TriggerClientEvent("pickle_casinos:updateCasinoSetting", -1, casinoId, variable, value)
end)

RegisterCommand("casinos", function(source, args, raw)
    if not IsPlayerAdmin(source) then return ShowNotification(source, _L("no_permission")) end
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
                owner_identifier = result.owner_identifier,
                settings = settings,
                entities = InitializeCasinoEntities(result.id, entities),
                transactions = transactions,
            }, true)
        end
    end)
end)