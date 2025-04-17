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

CreateThread(function() 
    for k,v in pairs(Casinos) do 
        RegisterCasino(k, {
            entities = v.entities
        }, true)
    end
end)