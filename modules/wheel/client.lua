local LocalWheels = {}
local CurrentWheel = nil
local CurrentCamera = nil

function EnsureWheelCamera()
    if not CurrentCamera then
        local initialCamSettings = {
            coords = GetGameplayCamCoord(),
            rotation = GetGameplayCamRot(),
            fov = GetGameplayCamFov(),
        }
        CurrentCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 
            initialCamSettings.coords.x, initialCamSettings.coords.y, initialCamSettings.coords.z, 
            initialCamSettings.rotation.x, initialCamSettings.rotation.y, initialCamSettings.rotation.z, initialCamSettings.fov
        )
        SetCamActive(CurrentCamera, true)
        RenderScriptCams(true, false, 0, true, true)
    end
end

function DoesWheelEntityExist(casinoId, entityId) 
    return LocalWheels[casinoId] and LocalWheels[casinoId][entityId]
end

function AttemptSeatAtWheelEntity(casinoId, entityId)
    ServerCallback("pickle_casinos:wheel:requestSeat", function(seatId, entityInfo)
        if not seatId then return end
        local localWheel = LocalWheels[casinoId][entityId]
        if not localWheel then return end
        local tickCoords = GetOffsetFromEntityInWorldCoords(localWheel.tickObject, 0.0, -2.25, 1.9)
        CurrentWheel = {
            casinoId = casinoId,
            entityId = entityId,
            money = entityInfo.money,
            history = entityInfo.history or {},
            stage = entityInfo.stage or {type = "waiting", time = 10},
        }
        local casinoId = CurrentWheel.casinoId
        local entityId = CurrentWheel.entityId
        local stage = CurrentWheel.stage
        if (stage.type == "waiting") then
            CurrentWheel.waitingTime = stage.time
        end
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "setCurrentGame",
            game = {
                type = "wheel",
                data = {
                    money = CurrentWheel.money,
                    history = CurrentWheel.history,
                    wagerLimit = {10, 100000},
                    stage = stage,
                }
            }
        })
        EnsureWheelCamera()
        SetCamParams(CurrentCamera, tickCoords.x, tickCoords.y, tickCoords.z,
            -15.0, 0.0, localWheel.heading + 180.0, 90.0, 
            2000, 0, 0, 2
        )
        CreateThread(function()
            while CurrentWheel do
                if CurrentWheel.waitingTime > 1 and CurrentWheel.stage.type == "waiting" then
                    CurrentWheel.waitingTime = CurrentWheel.waitingTime - 1
                    print("Waiting Time: ", CurrentWheel.waitingTime)
                    SendNUIMessage({
                        type = "updateWheelStage",
                        stage = {
                            type = "waiting",
                            time = CurrentWheel.waitingTime
                        }
                    })
                end
                Wait(1000)
            end
        end)
    end, casinoId, entityId, 1)
end

function SpinWheelEntity(casinoId, entityId, targetDegrees)
    local localWheel = LocalWheels[casinoId][entityId]
    if not localWheel then return end
    CreateThread(function()
        local rotation = GetEntityRotation(localWheel.wheelObject, 2).y
        local rotations = 0
        local targetSection = GetSectionForDegrees(targetDegrees)
        local totalDegrees = 0.0
        local maxDegrees = (1 * 360.0)
        local stage = {type = "start", progress = 0.0}
        local baseSpeed = 3.0
        local spinComplete = false
        local reachedSlowdown = false
        local remainingRotation = 360.0
        local lastSection = targetSection
        while not spinComplete do
            local currentSection  = GetSectionForDegrees(rotation)
            if currentSection ~= lastSection then
                lastSection = currentSection
                SendNUIMessage({
                    type = "playAudio",
                    file = "audio/wheel/wheel_tick.mp3",
                })
            end
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
                        if (targetDegrees - 2) > rotation then
                            reachedSlowdown = true
                        end
                    else
                        local speed = lerp(0.02, baseSpeed, remainingRotation / 360.0)
                        rotation = rotation - speed
                        remainingRotation = remainingRotation - speed
                        if degreeDistance <= 0.25 then
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
            SetEntityRotation(localWheel.wheelObject, 0.0, rotation, localWheel.heading + 180.0, 2, true)
            Wait(0)
        end
        print("SPIN COMPLETE")
    end)
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
            coords = GetOffsetFromEntityInWorldCoords(wheelObject, 0.0, -0.5, 0.0),
            heading = heading,
        }, function(selected)
            AttemptSeatAtWheelEntity(casinoId, entityId)
        end)
    }
    -- AttemptSeatAtWheelEntity(casinoId, entityId)
end

function DeleteWheelEntity(casinoId, entityId)
    local slotEntity = LocalWheels[casinoId][entityId]
    if not slotEntity then return end
    DeleteObject(slotEntity.wheelObject)
    DeleteObject(slotEntity.standObject)
    DeleteObject(slotEntity.tickObject)
    LocalWheels[casinoId][entityId] = nil
end

RegisterNUICallback("setWheelWager", function(data, cb)
    TriggerServerEvent("pickle_casinos:wheel:setWager", data.wager)
end)

RegisterNUICallback("repeatWheelWager", function(data, cb)
    TriggerServerEvent("pickle_casinos:wheel:repeatWager")
end)

RegisterNetEvent("pickle_casinos:wheel:updateBalance", function(balance)
    if not CurrentWheel then return end
    CurrentWheel.money = balance
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)

RegisterNetEvent("pickle_casinos:wheel:updateWager", function(wagers)
    if not CurrentWheel then return end
    SendNUIMessage({
        type = "updateWheelWager",
        wager = wagers,
    })
end)

RegisterNetEvent("pickle_casinos:wheel:updateStage", function(casinoId, entityId, stage)
    if not DoesWheelEntityExist(casinoId, entityId) then return end
    local localWheel = LocalWheels[casinoId][entityId]
    if not localWheel then return end
    local isCurrentWheel = (CurrentWheel and CurrentWheel.casinoId == casinoId and CurrentWheel.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local targetRotation = casinoEntity.rotation + vector3(0.0, 0.0, 180.0)
    local isAlreadyWaiting = (CurrentWheel and CurrentWheel.stage and CurrentWheel.stage.type == "waiting")
    if (isCurrentWheel) then
        CurrentWheel.stage = stage
    end
    if stage.type == "waiting" then
        if isCurrentWheel then
            CurrentWheel.waitingTime = stage.time
            if not isAlreadyWaiting then
                EnsureWheelCamera()
                local tickCoords = GetOffsetFromEntityInWorldCoords(localWheel.tickObject, 0.0, -2.25, 1.9)
                SetCamParams(CurrentCamera, tickCoords.x, tickCoords.y, tickCoords.z,
                    -15.0, 0.0, localWheel.heading + 180.0, 90.0, 
                    2000, 0, 0, 2
                )
            end
        end
    elseif stage.type == "spinning" then 
        SpinWheelEntity(casinoId, entityId, stage.degrees)
        if isCurrentWheel then
            CurrentWheel.stage = stage
            SendNUIMessage({
                type = "updateWheelStage",
                stage = {
                    type = "spinning",
                }
            })
            SetTimeout(3000, function()
                local tickCoords = GetOffsetFromEntityInWorldCoords(localWheel.tickObject, 0.0, -0.8, 2.65)
                SetCamParams(CurrentCamera, tickCoords.x, tickCoords.y, tickCoords.z,
                    -15.0, 0.0, localWheel.heading + 180.0, 90.0, 
                    2000, 0, 0, 2
                )
            end)
        end
    elseif stage.type == "bonus" then
        if isCurrentWheel then 
            CurrentWheel.stage = stage
            SendNUIMessage({
                type = "updateWheelStage",
                stage = {
                    type = "bonus",
                    prizeId = stage.prizeId,
                }
            })
        end
    elseif stage.type == "winner" then
        if isCurrentWheel then
            CurrentWheel.stage = stage
            SendNUIMessage({
                type = "updateWheelStage",
                stage = {
                    type = "winner",
                    section = stage.section,
                    multiplier = stage.multiplier,
                }
            })
        end
    end
end)

RegisterNetEvent("pickle_casinos:wheel:updateHistory", function(casinoId, entityId, history)
    if not DoesWheelEntityExist(casinoId, entityId) then return end
    if not CurrentWheel then return end
    CurrentWheel.history = history
    SendNUIMessage({
        type = "updateWheelHistory",
        history = history,
    })
end)

AddEventHandler("pickle_casinos:exitGame", function()
    if not CurrentWheel then return end
    TriggerServerEvent("pickle_casinos:wheel:leaveTable")
    DestroyCam(CurrentCamera)
    RenderScriptCams(false, true, 2000, false, false) 
    CurrentWheel = nil
    CurrentCamera = nil
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