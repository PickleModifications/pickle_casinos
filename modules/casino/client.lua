LOCAL_MONEY = 0

function CreateCasinoEntity(casinoId, entityId)
    local casino = Config.Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    if casinoEntity.type == "blackjack" then
        CreateBlackjackEntity(casinoId, entityId)
    elseif casinoEntity.type == "roulette" then
        CreateRouletteEntity(casinoId, entityId)
    elseif casinoEntity.type == "baccarat" then
        CreateBaccaratEntity(casinoId, entityId)
    elseif casinoEntity.type == "slot" then
        CreateSlotEntity(casinoId, entityId)
    elseif casinoEntity.type == "poker" then
        CreatePokerEntity(casinoId, entityId)
    elseif casinoEntity.type == "wheel" then
        CreateWheelEntity(casinoId, entityId)
    elseif casinoEntity.type == "horseracing" then
        CreateHorseRacingEntity(casinoId, entityId)
    end
end

function GetCasinoEntity(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    for i=1, #casino.entities do
        if casino.entities[i].id == entityId then
            return casino.entities[i], i
        end
    end
end

function UpdateCasinoEntity(casinoId, entity)
    local casino = Casinos[casinoId]
    if not casino then return end
    local casinoEntity, index = GetCasinoEntity(casinoId, entity.id)
    if not casinoEntity then return end
    print("Updating casino entity", casinoId, entity.id, index)
    casino.entities[index] = entity
end

function GenerateWheelBonusConfig()
    local entries = {}
    for i=1, #Config.WheelBonus do 
        entries[i] = {
            id = "bonus_" .. i,
            multiplier = Config.WheelBonus[i].multiplier,
            chance = Config.WheelBonus[i].chance,
        }
    end
    return entries
end

RegisterNUICallback("pageLoaded", function(data, cb)
    SendNUIMessage({
        type = "setConfig",
        config = {
            currency = "USD",
            countryCode = "en-US",
            bonusWheelMultipliers = GenerateWheelBonusConfig(),
        }
    })
    TriggerServerEvent("pickle_casinos:initializePlayer")
end)

RegisterNUICallback("exitGame", function(data, cb)
    TriggerEvent("pickle_casinos:exitGame")
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "setCurrentGame",
        game = nil
    })
end)

RegisterNetEvent("pickle_casinos:syncCasinos", function(data)
    for k,v in pairs(data) do
        Casinos[k] = v
        for i=1, #v.entities do
            CreateCasinoEntity(k, v.entities[i].id)
        end
    end
end)

RegisterNetEvent("pickle_casinos:displayResults", function(totalWin, balance)
    SendNUIMessage({
        type = "displayResults",
        results = {winnings = totalWin},
    })
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)

RegisterNetEvent("pickle_casinos:updateCasinoEntity", function(casinoId, entity)
    local casino = Casinos[casinoId]
    if not casino then return end
    local casinoEntity = GetCasinoEntity(casinoId, entity.id)
    if not casinoEntity then return end
    UpdateCasinoEntity(casinoId, entity)
end)

RegisterNetEvent("pickle_casinos:updateMoney", function(money)
    LOCAL_MONEY = money
    SendNUIMessage({
        type = "updateMoney",
        money = money
    })
end)