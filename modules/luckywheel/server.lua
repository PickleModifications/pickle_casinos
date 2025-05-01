function InitializeLuckyWheelEntity(casinoId, data, dataOnly)
    local entity = data or { id = "ERR_NO_ID_POKER" }
    entity.stage = entity.stage or { type = "waiting" }
    return entity
end

RegisterCallback("pickle_casinos:luckywheel:requestSpin", function(source, cb, casinoId, entityId, seatId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local isSpinning = entity.stage.type ~= "waiting"
    local spinPrice = entity.settings.spinPrice or 0
    local balance = GetCasinoChips(source, casinoId)
    if isSpinning or balance < spinPrice then return cb(false, balance < spinPrice) end
    if spinPrice > 0 then
        RemoveCasinoChips(source, casinoId, spinPrice)
    end
    entity.spinner = source
    local result = GetLuckyWheelSafeDegrees(math.random(0, 360))--((1 / #LuckyWheelSections) * 360.0)) --)
    local section = GetLuckyWheelSectionForDegrees(result)
    entity.stage = {type = "spinning", degrees = result}
    TriggerClientEvent("pickle_casinos:luckywheel:updateStage", -1, casinoId, entityId, entity.stage)
    CreateThread(function()
        Wait(15000)
        entity.stage = {type = "winner", section = section}
        TriggerClientEvent("pickle_casinos:luckywheel:updateStage", -1, casinoId, entityId, entity.stage)
        Wait(5000)
        entity.stage = {type = "waiting"}
        entity.spinner = nil
        TriggerClientEvent("pickle_casinos:luckywheel:updateStage", -1, casinoId, entityId, entity.stage)
    end)
end)

function GetRandomMultiplier()
    local wheelBonus = Config.WheelBonus
    local options = {}
    for i=1, #wheelBonus do
        local option = wheelBonus[i]
        for j=1, option.chance do 
            table.insert(options, {index = i, multiplier = option.multiplier})
        end
    end
    local result = options[math.random(1, #options)]
    return result.index, result.multiplier
end