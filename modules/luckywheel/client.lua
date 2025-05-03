local LocalLuckyWheels = {}
local CurrentLuckyWheel = nil

function DoesLuckyWheelEntityExist(casinoId, entityId) 
    return LocalLuckyWheels[casinoId] and LocalLuckyWheels[casinoId][entityId]
end

function PlayLuckyWheelAnimation(ped, animation, data)
    playingLuckyWheelAnimation = true
    SetTimeout((data and data.time) or 1000, function()
        playingLuckyWheelAnimation = false
    end)
    local coords = data.coords
    local rotation = data.rotation
    local netScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, rotation.x, rotation.y, rotation.z, 2, 1, 0, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(ped, netScene, animation.dict, animation.name, 2.0, -2.0, 13, 16, 2.0, 0) -- 8.0, -1.5, 157, 16, 1148846080, 0) ?
    NetworkStartSynchronisedScene(netScene)
end

function AttemptSeatAtLuckyWheelEntity(casinoId, entityId)
    ServerCallback("pickle_casinos:luckywheel:requestSpin", function(seatId, entityInfo)
        if not seatId then return end
        local localWheel = LocalLuckyWheels[casinoId][entityId]
        if not localWheel then return end
        local ped = PlayerPedId()
        local coords = GetOffsetFromEntityInWorldCoords(localWheel.standObject, -0.85, -0.85, 0.0)
        local dict = "anim_casino_a@amb@casino@games@lucky7wheel@" .. (IsPedMale(ped) and "male" or "female")
        TaskGoStraightToCoord(ped, coords.x, coords.y, coords.z, 1.0, -1, localWheel.heading, 0.0)
        Wait(1000)
        while GetEntitySpeed(ped) > 0.5 do
            Wait(0)
        end
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, localWheel.heading)
        PlayAnim(ped, dict, "enter_right_to_baseidle", 8.0, -1.0, -1, 0, 0.0, false, false, false, false)
        while IsEntityPlayingAnim(ped, dict, "enter_right_to_baseidle", 3) do
            Wait(0)
        end
        PlayAnim(ped, dict, "enter_to_armraisedidle", 8.0, -1.0, -1, 0, 0.0, false, false, false, false)
        while IsEntityPlayingAnim(ped, dict, "enter_to_armraisedidle", 3) do
            Wait(0)
        end
        Wait(2000)
        PlayAnim(ped, dict, "armraisedidle_to_spinningidle_high", 8.0, -1.0, -1, 0, 0.0, false, false, false, false)
        TriggerServerEvent("pickle_casinos:luckywheel:startSpin")
    end, casinoId, entityId, 1)
end

function SpinLuckyWheelEntity(casinoId, entityId, targetDegrees)
    local localWheel = LocalLuckyWheels[casinoId][entityId]
    if not localWheel then return end
    CreateThread(function()
        local rotation = GetEntityRotation(localWheel.wheelObject, 2).y
        local rotations = 0
        local targetSection = GetLuckyWheelSectionForDegrees(targetDegrees)
        local totalDegrees = 0.0
        local maxDegrees = (1 * 360.0)
        local stage = {type = "start", progress = 0.0}
        local baseSpeed = 3.0
        local spinComplete = false
        local reachedSlowdown = false
        local remainingRotation = 360.0
        local lastSection = targetSection
        while not spinComplete do
            local currentSection  = GetLuckyWheelSectionForDegrees(rotation)
            if currentSection ~= lastSection then
                lastSection = currentSection
                PlaySoundFromEntity(-1, "Spin_Single_Ticks", localWheel.standObject, "dlc_vw_casino_lucky_wheel_sounds", 1, 0)
            end
            if stage.type == "start" then
                stage.progress = stage.progress + 0.01
                rotation = rotation - lerp(2.0, baseSpeed, stage.progress)
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
            SetEntityRotation(localWheel.wheelObject, 0.0, rotation, localWheel.heading + 0.0, 2, true)
            local gameSpeed = math.floor((8 * (CLIENT_FPS / 60)) - 8)
            if gameSpeed < 0 then gameSpeed = 0 end
            debugPrint("Game Speed: ", gameSpeed)
            Wait(gameSpeed)
        end
        debugPrint("SPIN COMPLETE")
    end)
end

function CreateLuckyWheelEntity(casinoId, entityId)
    if not Config.LuckyWheel then
        print("^1ERROR: Lucky Wheel is not defined in config! Download the latest update and copy over Config.LuckyWheel.^0")
        return
    end
    if DoesLuckyWheelEntityExist(casinoId, entityId) then return end
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z

    if not LocalLuckyWheels[casinoId] then
        LocalLuckyWheels[casinoId] = {}
    end
    LocalLuckyWheels[casinoId][entityId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - coords) < Config.RenderDistance,
        coords = coords,
        heading = heading
    }
    RenderLuckyWheelEntity(casinoId, entityId)
    -- AttemptSeatAtLuckyWheelEntity(casinoId, entityId)
end

function RenderLuckyWheelEntity(casinoId, entityId)
    local wheelEntity = LocalLuckyWheels[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not wheelEntity.visible or not casinoEntity then return end
    local wheelModel = casinoEntity.settings.wheelModel or `vw_prop_vw_luckywheel_02a`
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    local standObject = CreateProp(`vw_prop_vw_luckywheel_01a`, coords, false, false, false)
    local wheelObject = CreateProp(wheelModel, coords, false, false, false)
    local tickObject = CreateProp(`vw_prop_vw_jackpot_off`, coords, false, false, false)
    FreezeEntityPosition(standObject, true)
    SetEntityHeading(standObject, heading)
    FreezeEntityPosition(wheelObject, true)
    SetEntityHeading(wheelObject, heading)
    FreezeEntityPosition(tickObject, true)
    SetEntityHeading(tickObject, heading)
    local coordOff = GetOffsetFromEntityInWorldCoords(standObject, 0.0, 0.0, 1.612)
    SetEntityCoords(wheelObject, coordOff.x, coordOff.y, coordOff.z - 0.1)
    local coordOff = GetOffsetFromEntityInWorldCoords(standObject, 0.0, 0.0, 0.1)
    SetEntityCoords(tickObject, coordOff.x, coordOff.y, coordOff.z - 0.1)
    wheelEntity.wheelObject = wheelObject
    wheelEntity.standObject = standObject
    wheelEntity.tickObject = tickObject
    if Config.LuckyWheel.sections["vehicle"] and #Config.LuckyWheel.sections["vehicle"].rewards > 0 then
        local coords = casinoEntity.settings.vehicleLocation.coords
        local heading = casinoEntity.settings.vehicleLocation.rotation.z
        local rewardCfg = Config.LuckyWheel.sections["vehicle"].rewards[1]
        local vehicle = CreateVeh(rewardCfg.model, coords, 0.0, false, false)
        FreezeEntityPosition(vehicle, true)
        SetEntityHeading(vehicle, heading)
        if Config.LuckyWheel.rotateVehicle then
            CreateThread(function()
                local heading = heading or 0.0
                while DoesLuckyWheelEntityExist(casinoId, entityId) do
                    heading = heading + 0.5
                    SetEntityRotation(vehicle, 0.0, 0.0, heading, 2, true)
                    Wait(0)
                end
            end)
        end
        wheelEntity.vehicle = vehicle
    end
    wheelEntity.interact = CreateInteraction({
        label = (casinoEntity.settings.spinPrice > 0 and _L("interact_luckywheel_cost", NumberWithCommas(casinoEntity.settings.spinPrice, true)) or _L("interact_luckywheel")) .. (casinoEntity.settings.vip and (" " .. _L("casino_vip_game")) or ""),
        icon = Config.TargetIcons and Config.TargetIcons["luckywheel"] or nil,
        coords = GetOffsetFromEntityInWorldCoords(wheelObject, 0.0, -0.5, 0.0),
        heading = heading,
    }, function(selected)
        local casino = Casinos[casinoId]
        if not casino then return end
        if not casino.settings.isOpen then
            return ShowNotification(_L("casino_closed"))
        end
        ServerCallback("pickle_casinos:getVIPStatus", function(isVIP)
            if casinoEntity.settings.vip and not isVIP then return ShowNotification(_L("casino_vip_required")) end
            AttemptSeatAtLuckyWheelEntity(casinoId, entityId)
        end, casinoId, entityId)
    end)
end

function UnrenderLuckyWheelEntity(casinoId, entityId)
    local wheelEntity = LocalLuckyWheels[casinoId][entityId]
    if not wheelEntity then return end
    if wheelEntity.wheelObject then
        DeleteObject(wheelEntity.wheelObject)
    end
    if wheelEntity.standObject then
        DeleteObject(wheelEntity.standObject)
    end
    if wheelEntity.tickObject then
        DeleteObject(wheelEntity.tickObject)
    end
    if wheelEntity.vehicle then
        DeleteEntity(wheelEntity.vehicle)
    end
    if wheelEntity.interact then
        DeleteInteraction(wheelEntity.interact)
    end
    wheelEntity.interact = nil
    wheelEntity.wheelObject = nil
    wheelEntity.standObject = nil
    wheelEntity.tickObject = nil
    wheelEntity.vehicle = nil
end

function DeleteLuckyWheelEntity(casinoId, entityId)
    UnrenderLuckyWheelEntity(casinoId, entityId)
    LocalLuckyWheels[casinoId][entityId] = nil
end

CreateThread(function()
    while true do 
        local coords = GetEntityCoords(PlayerPedId())
        for casinoId, entities in pairs(LocalLuckyWheels) do
            for entityId, entity in pairs(entities) do
                if not entity.visible and not entity.hidden then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) <= Config.RenderDistance then
                        entity.visible = true
                        RenderLuckyWheelEntity(casinoId, entityId)
                    end
                elseif entity.visible then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) > Config.RenderDistance then
                        entity.visible = false
                        UnrenderLuckyWheelEntity(casinoId, entityId)
                    end
                end
            end
        end
        Wait(1500)
    end
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    if not LocalLuckyWheels[casinoId] then return end
    if not LocalLuckyWheels[casinoId][entityId] then return end
    DeleteLuckyWheelEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:setCasinoEntityHidden", function(casinoId, entityId, toggle)
    if not LocalLuckyWheels[casinoId] then return end
    if not LocalLuckyWheels[casinoId][entityId] then return end
    local localWheel = LocalLuckyWheels[casinoId][entityId]
    localWheel.hidden = toggle
    if toggle then
        localWheel.visible = false
        UnrenderLuckyWheelEntity(casinoId, entityId)
    else
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - localWheel.coords) <= Config.RenderDistance then
            localWheel.visible = true
            RenderLuckyWheelEntity(casinoId, entityId)
        end
    end
end)

RegisterNetEvent("pickle_casinos:refreshCasinoEntity", function(casinoId, entityId)
    if not LocalLuckyWheels[casinoId] then return end
    if not LocalLuckyWheels[casinoId][entityId] then return end
    local localWheel = LocalLuckyWheels[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    localWheel.coords = casinoEntity.settings.location.coords
    localWheel.heading = casinoEntity.settings.location.rotation.z
    if not localWheel.visible then return end
    UnrenderLuckyWheelEntity(casinoId, entityId)
    Wait(100)
    RenderLuckyWheelEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:luckywheel:updateStage", function(casinoId, entityId, stage)
    if not DoesLuckyWheelEntityExist(casinoId, entityId) then return end
    local localWheel = LocalLuckyWheels[casinoId][entityId]
    if not localWheel or not localWheel.visible then return end
    local isCurrentLuckyWheel = (CurrentLuckyWheel and CurrentLuckyWheel.casinoId == casinoId and CurrentLuckyWheel.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local targetRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
    local isAlreadyWaiting = (CurrentLuckyWheel and CurrentLuckyWheel.stage and CurrentLuckyWheel.stage.type == "waiting")
    if (isCurrentLuckyWheel) then
        CurrentLuckyWheel.stage = stage
    end
    if stage.type == "waiting" then
        if isCurrentLuckyWheel then
            CurrentLuckyWheel.waitingTime = stage.time
        end
    elseif stage.type == "spinning" then 
        SpinLuckyWheelEntity(casinoId, entityId, stage.degrees)
        if isCurrentLuckyWheel then
            CurrentLuckyWheel.stage = stage
        end
    elseif stage.type == "bonus" then
        if isCurrentLuckyWheel then 
            CurrentLuckyWheel.stage = stage
            SendNUIMessage({
                type = "updateWheelStage",
                stage = {
                    type = "bonus",
                    prizeId = stage.prizeId,
                }
            })
        end
    elseif stage.type == "winner" then
        if isCurrentLuckyWheel then
            CurrentLuckyWheel.stage = stage
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

RegisterNetEvent("pickle_casinos:exitGame", function()
    if not CurrentLuckyWheel then return end
    TriggerServerEvent("pickle_casinos:luckywheel:leaveTable")
    CurrentLuckyWheel = nil
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k,v in pairs(LocalLuckyWheels) do
            for id, _ in pairs(v) do
                DeleteLuckyWheelEntity(k, id)
            end
        end
    end
end)