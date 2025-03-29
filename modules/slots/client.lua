local LocalSlotMachines = {}
local CurrentSlotMachine = nil

function DoesSlotEntityExist(casinoId, entityId) 
    return LocalSlotMachines[casinoId] and LocalSlotMachines[casinoId][entityId]
end

function GetSlotStructure()
    if not CurrentSlotMachine then return end
    local game = Config.Slots[CurrentSlotMachine.game]
    if not game then return end
    local slotStructure = {}
    for k,v in pairs(game) do 
        slotStructure[k] = v
    end
    slotStructure.money = CurrentSlotMachine.money
    slotStructure.bets = CurrentSlotMachine.bets
    return slotStructure
end

function AttemptSeatAtSlotEntity(casinoId, entityId)
    ServerCallback("pickle_casinos:slots:requestSeat", function(seatId, entityInfo)
        if not seatId then return end
        CurrentSlotMachine = {
            casinoId = casinoId,
            entityId = entityId,
            seatId = seatId,
            game = entityInfo.game,
            bets = entityInfo.bets,
            money = entityInfo.money,
        }
        local casinoId = CurrentSlotMachine.casinoId
        local entityId = CurrentSlotMachine.entityId
        local seatId = CurrentSlotMachine.seatId
        local slotStructure = GetSlotStructure()
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "setCurrentGame",
            game = {
                type = "slots",
                data = slotStructure
            }
        })
    end, casinoId, entityId)
end

function CreateSlotEntity(casinoId, entityId)
    if DoesSlotEntityExist(casinoId, entityId) then return end
    local casino = Config.Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.coords
    local heading = casinoEntity.rotation.z
    local slotCfg = Config.Slots[casinoEntity.settings.game]
    if not slotCfg then return end
    local slotObject = CreateObject(slotCfg.model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityRotation(slotObject, 0.0, 0.0, heading, 2, true)
    if not LocalSlotMachines[casinoId] then
        LocalSlotMachines[casinoId] = {}
    end
    LocalSlotMachines[casinoId][entityId] = {
        coords = coords,
        heading = heading,
        slotObject = slotObject,
        interact = CreateInteraction({
            label = _L("interact_roulette"),
            coords = GetOffsetFromEntityInWorldCoords(slotObject, 0.0, 0.0, 1.0),
            heading = heading,
        }, function(selected)
            AttemptSeatAtSlotEntity(casinoId, entityId)
        end)
    }
end

function DeleteSlotEntity(casinoId, entityId)
    local slotEntity = LocalSlotMachines[casinoId][entityId]
    if not slotEntity then return end
    DeleteObject(slotEntity.slotObject)
    LocalSlotMachines[casinoId][entityId] = nil
end

RegisterNetEvent("pickle_casinos:slots:updateBalance", function(balance)
    if not CurrentSlotMachine then return end
    CurrentSlotMachine.money = balance
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)

RegisterNUICallback("finishSpin", function(data, cb)
    TriggerServerEvent("pickle_casinos:slots:redeemSpin", data.id, data.spinIndex or 1)
end)

RegisterNUICallback("spinSlot", function(data, cb)
    ServerCallback("pickle_casinos:slots:spinSlot", function(result, balance)
        if not result then return cb(nil) end
        SendNUIMessage({
            type = "updateBalance",
            balance = balance,
        })
        cb(result)
    end, data.betIndex)
end)

AddEventHandler("pickle_casinos:exitGame", function()
    if not CurrentSlotMachine then return end
    TriggerServerEvent("pickle_casinos:slots:leaveSlotMachine")
    CurrentSlotMachine = nil
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k,v in pairs(LocalSlotMachines) do
            for id, _ in pairs(v) do
                DeleteSlotEntity(k, id)
            end
        end
    end
end)