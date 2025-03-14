function CreateCasinoEntity(casinoId, entityId)
    local casino = Config.Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    if casinoEntity.type == "blackjack" then
        CreateBlackjackEntity(casinoId, entityId)
    end
end

RegisterNUICallback("pageLoaded", function(data, cb)
    SendNUIMessage({
        type = "setConfig",
        config = {
            currency = "USD",
            countryCode = "en-US",
        }
    })
    TriggerServerEvent("pickle_casinos:initializePlayer")
end)

RegisterNetEvent("pickle_casinos:syncCasinos", function(data)
    for k,v in pairs(data) do
        Casinos[k] = v
        for i=1, #v.entities do
            CreateCasinoEntity(k, v.entities[i].id)
        end
    end
end)