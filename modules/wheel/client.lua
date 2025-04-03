local LocalWheels = {}
local CurrentWheel = nil

function DoesWheelEntityExist(casinoId, entityId) 
    return LocalWheels[casinoId] and LocalWheels[casinoId][entityId]
end

function AttemptSeatAtWheelEntity(casinoId, entityId)
    ServerCallback("pickle_casinos:wheel:requestSeat", function(seatId, entityInfo)
        if not seatId then return end
        CurrentWheel = {
            casinoId = casinoId,
            entityId = entityId,
            seatId = seatId,
            game = entityInfo.game,
            bets = entityInfo.bets,
            money = entityInfo.money,
        }
        local casinoId = CurrentWheel.casinoId
        local entityId = CurrentWheel.entityId
        local seatId = CurrentWheel.seatId
        print("SITTING")
    end, casinoId, entityId, 1)
end

function CreateWheelEntity(casinoId, entityId)
    if DoesWheelEntityExist(casinoId, entityId) then return end
    local casino = Config.Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.coords
    local heading = casinoEntity.rotation.z
    local standObject = CreateProp(`vw_prop_vw_luckywheel_01a`, coords, false, false, false)
    local wheelObject = CreateProp(`fury_p_wheeloff`, coords, false, false, false)
    local tickObject = CreateProp(`vw_prop_vw_jackpot_off`, coords, false, false, false)
    FreezeEntityPosition(standObject, true)
    SetEntityHeading(standObject, heading + 180.0)
    FreezeEntityPosition(wheelObject, true)
    SetEntityHeading(wheelObject, heading + 180.0)
    FreezeEntityPosition(tickObject, true)
    SetEntityHeading(tickObject, heading + 180.0)
    local coordOff = GetOffsetFromEntityInWorldCoords(standObject, 0.0, -0.2, 1.612)
    SetEntityCoords(wheelObject, coordOff.x, coordOff.y, coordOff.z - 0.1)
    local coordOff = GetOffsetFromEntityInWorldCoords(standObject, 0.0, 0.0, 0.1)
    SetEntityCoords(tickObject, coordOff.x, coordOff.y, coordOff.z - 0.1)
    if not LocalWheels[casinoId] then
        LocalWheels[casinoId] = {}
    end
    LocalWheels[casinoId][entityId] = {
        coords = coords,
        heading = heading,
        wheelObject = wheelObject,
        standObject = standObject,
        tickObject = tickObject,
        interact = CreateInteraction({
            label = _L("interact_wheel"),
            coords = GetOffsetFromEntityInWorldCoords(wheelObject, 0.0, 0.0, 1.0),
            heading = heading,
        }, function(selected)
            AttemptSeatAtWheelEntity(casinoId, entityId)
        end)
    }
    AttemptSeatAtWheelEntity(casinoId, entityId)
    CreateThread(function()
        local rotation = 0.0
        local rotations = 0
        local targetDegrees = 13.0
        local totalDegrees = 0.0
        local maxDegrees = (1 * 360.0)
        local stage = {type = "start", progress = 0.0}
        local baseSpeed = 3.0
        local spinComplete = false
        local reachedSlowdown = false
        local remainingRotation = 360.0
        while not spinComplete do
            if stage.type == "start" then
                stage.progress = stage.progress + 0.01
                rotation = rotation - lerp(0.0, baseSpeed, stage.progress)
                if stage.progress >= 1.0 then
                    stage.type = "spin"
                    stage.spins = 1
                end
            elseif stage.type == "spin" then
                if stage.spins > 0 then
                    stage.progress = stage.progress + 0.01
                    rotation = rotation - baseSpeed
                else
                    local degreeDistance = math.abs(rotation - targetDegrees)
                    if not reachedSlowdown then
                        rotation = rotation - baseSpeed
                        print(rotation, targetDegrees, degreeDistance)
                        if (targetDegrees - 2) > rotation then
                            reachedSlowdown = true
                        end
                    else
                        local speed = lerp(0.02, baseSpeed, remainingRotation / 360.0)
                        rotation = rotation - speed
                        remainingRotation = remainingRotation - speed
                        if degreeDistance <= 0.25 then
                            rotation = targetDegrees
                            spinComplete = true
                        end
                    end
                end
            end
            if rotation <= 0 then
                rotation = 360 - math.abs(rotation)
                if stage.spins and stage.spins > 0 then
                    stage.spins = stage.spins - 1
                end
            end
            SetEntityRotation(wheelObject, 0.0, rotation, heading + 180.0, 2, true)
            Wait(0)
        end
        print("SPIN COMPLETE")
    end)
end

function DeleteWheelEntity(casinoId, entityId)
    local slotEntity = LocalWheels[casinoId][entityId]
    if not slotEntity then return end
    DeleteObject(slotEntity.wheelObject)
    DeleteObject(slotEntity.standObject)
    DeleteObject(slotEntity.tickObject)
    LocalWheels[casinoId][entityId] = nil
end

RegisterNetEvent("pickle_casinos:wheel:updateBalance", function(balance)
    if not CurrentWheel then return end
    CurrentWheel.money = balance
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)
AddEventHandler("pickle_casinos:exitGame", function()
    if not CurrentWheel then return end
    TriggerServerEvent("pickle_casinos:wheel:leaveTable")
    CurrentWheel = nil
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k,v in pairs(LocalWheels) do
            for id, _ in pairs(v) do
                DeleteWheelEntity(k, id)
            end
        end
    end
end)