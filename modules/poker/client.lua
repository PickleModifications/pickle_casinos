local LocalPokerTables = {}
local CurrentPokerTable = nil

function DoesPokerEntityExist(casinoId, entityId) 
    return LocalPokerTables[casinoId] and LocalPokerTables[casinoId][entityId]
end

function AttemptSeatAtPokerEntity(casinoId, entityId)
    ServerCallback("pickle_casinos:poker:requestSeat", function(seatId, entityInfo)
        print(seatId, entityInfo)
        if not seatId then return end
        CurrentPokerTable = {
            casinoId = casinoId,
            entityId = entityId,
            seatId = seatId,
            game = entityInfo.game,
            bets = entityInfo.bets,
            money = entityInfo.money,
        }
        local casinoId = CurrentPokerTable.casinoId
        local entityId = CurrentPokerTable.entityId
        local seatId = CurrentPokerTable.seatId
        print("SITTING")
    end, casinoId, entityId, 1)
end

function CreatePokerEntity(casinoId, entityId)
    if DoesPokerEntityExist(casinoId, entityId) then return end
    local casino = Config.Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.coords
    local heading = casinoEntity.rotation.z
    local tableObject = CreateProp(casinoEntity.settings.tableModel, coords, false, false, false)
    local surfaceObject = CreateProp(`prop_tennis_ball`, coords - vector3(0.0, 0.0, 0.11), false, false, false)
    FreezeEntityPosition(tableObject, true)
    SetEntityHeading(tableObject, heading)
    FreezeEntityPosition(surfaceObject, true)
    SetEntityHeading(surfaceObject, heading)
    local dealerCoords = GetOffsetFromEntityInWorldCoords(surfaceObject, 0.0, -0.75, 0.27)
    local dealerPed = CreateNPC(casinoEntity.settings.dealerModel, dealerCoords, heading, false, false)
    SetEntityInvincible(dealerPed, true)
    SetBlockingOfNonTemporaryEvents(dealerPed, true)
    FreezeEntityPosition(dealerPed, true)
    if not LocalPokerTables[casinoId] then
        LocalPokerTables[casinoId] = {}
    end
    LocalPokerTables[casinoId][entityId] = {
        coords = coords,
        heading = heading,
        tableObject = tableObject,
        surfaceObject = surfaceObject,
        dealerPed = dealerPed,
        interact = CreateInteraction({
            label = _L("interact_poker"),
            coords = GetOffsetFromEntityInWorldCoords(tableObject, 0.0, 0.0, 1.0),
            heading = heading,
        }, function(selected)
            AttemptSeatAtPokerEntity(casinoId, entityId)
        end)
    }
    AttemptSeatAtPokerEntity(casinoId, entityId)
end

function DeletePokerEntity(casinoId, entityId)
    local slotEntity = LocalPokerTables[casinoId][entityId]
    if not slotEntity then return end
    DeleteObject(slotEntity.tableObject)
    DeleteObject(slotEntity.surfaceObject)
    DeleteEntity(slotEntity.dealerPed)
    LocalPokerTables[casinoId][entityId] = nil
end

RegisterNetEvent("pickle_casinos:poker:updateBalance", function(balance)
    if not CurrentPokerTable then return end
    CurrentPokerTable.money = balance
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)
AddEventHandler("pickle_casinos:exitGame", function()
    if not CurrentPokerTable then return end
    TriggerServerEvent("pickle_casinos:poker:leaveTable")
    CurrentPokerTable = nil
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k,v in pairs(LocalPokerTables) do
            for id, _ in pairs(v) do
                DeletePokerEntity(k, id)
            end
        end
    end
end)