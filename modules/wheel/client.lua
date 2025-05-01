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
            betRange = entityInfo.betRange,
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
                    wagerLimit = CurrentWheel.betRange,
                    stage = stage,
                }
            }
        })
        EnsureWheelCamera()
        SetCamParams(CurrentCamera, tickCoords.x, tickCoords.y, tickCoords.z,
            -15.0, 0.0, localWheel.heading + 0.0, 90.0, 
            2000, 0, 0, 2
        )
        CreateThread(function()
            while CurrentWheel do
                if CurrentWheel.waitingTime and CurrentWheel.waitingTime > 1 and CurrentWheel.stage.type == "waiting" then
                    CurrentWheel.waitingTime = CurrentWheel.waitingTime - 1
                    debugPrint("Waiting Time: ", CurrentWheel.waitingTime)
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
                PlaySoundFromEntity(-1, "Spin_Single_Ticks", localWheel.standObject, "dlc_vw_casino_lucky_wheel_sounds", 1, 0)
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
            SetEntityRotation(localWheel.wheelObject, 0.0, rotation, localWheel.heading + 0.0, 2, true)
            local gameSpeed = math.floor((8 * (CLIENT_FPS / 60)) - 8)
            if gameSpeed < 0 then gameSpeed = 0 end
            debugPrint("Game Speed: ", gameSpeed)
            Wait(gameSpeed)
        end
        debugPrint("SPIN COMPLETE")
    end)
end

function CreateWheelEntity(casinoId, entityId)
    if DoesWheelEntityExist(casinoId, entityId) then return end
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z

    if not LocalWheels[casinoId] then
        LocalWheels[casinoId] = {}
    end
    LocalWheels[casinoId][entityId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - coords) < Config.RenderDistance,
        coords = coords,
        heading = heading
    }
    RenderWheelEntity(casinoId, entityId)
    -- AttemptSeatAtWheelEntity(casinoId, entityId)
end

function RenderWheelEntity(casinoId, entityId)
    local wheelEntity = LocalWheels[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not wheelEntity.visible or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    local standObject = CreateProp(`vw_prop_vw_luckywheel_01a`, coords, false, false, false)
    local wheelObject = CreateProp(`fury_p_wheeloff`, coords, false, false, false)
    local tickObject = CreateProp(`vw_prop_vw_jackpot_off`, coords, false, false, false)
    FreezeEntityPosition(standObject, true)
    SetEntityHeading(standObject, heading)
    FreezeEntityPosition(wheelObject, true)
    SetEntityHeading(wheelObject, heading)
    FreezeEntityPosition(tickObject, true)
    SetEntityHeading(tickObject, heading)
    local coordOff = GetOffsetFromEntityInWorldCoords(standObject, 0.0, -0.2, 1.612)
    SetEntityCoords(wheelObject, coordOff.x, coordOff.y, coordOff.z - 0.1)
    local coordOff = GetOffsetFromEntityInWorldCoords(standObject, 0.0, 0.0, 0.1)
    SetEntityCoords(tickObject, coordOff.x, coordOff.y, coordOff.z - 0.1)
    wheelEntity.wheelObject = wheelObject
    wheelEntity.standObject = standObject
    wheelEntity.tickObject = tickObject
    wheelEntity.interact = CreateInteraction({
        label = _L("interact_wheel") .. (casinoEntity.settings.vip and (" " .. _L("casino_vip_game")) or ""),
        icon = Config.TargetIcons and Config.TargetIcons["wheel"] or nil,
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
            AttemptSeatAtWheelEntity(casinoId, entityId)
        end, casinoId, entityId)
    end)
end

function UnrenderWheelEntity(casinoId, entityId)
    local wheelEntity = LocalWheels[casinoId][entityId]
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
    if wheelEntity.interact then
        DeleteInteraction(wheelEntity.interact)
    end
    wheelEntity.interact = nil
    wheelEntity.wheelObject = nil
    wheelEntity.standObject = nil
    wheelEntity.tickObject = nil
end

function DeleteWheelEntity(casinoId, entityId)
    UnrenderWheelEntity(casinoId, entityId)
    LocalWheels[casinoId][entityId] = nil
end

CreateThread(function()
    while true do 
        local coords = GetEntityCoords(PlayerPedId())
        for casinoId, entities in pairs(LocalWheels) do
            for entityId, entity in pairs(entities) do
                if not entity.visible and not entity.hidden then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) <= Config.RenderDistance then
                        entity.visible = true
                        RenderWheelEntity(casinoId, entityId)
                    end
                elseif entity.visible then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) > Config.RenderDistance then
                        entity.visible = false
                        UnrenderWheelEntity(casinoId, entityId)
                    end
                end
            end
        end
        Wait(1500)
    end
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    if not LocalWheels[casinoId] then return end
    if not LocalWheels[casinoId][entityId] then return end
    DeleteWheelEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:setCasinoEntityHidden", function(casinoId, entityId, toggle)
    if not LocalWheels[casinoId] then return end
    if not LocalWheels[casinoId][entityId] then return end
    local localWheel = LocalWheels[casinoId][entityId]
    localWheel.hidden = toggle
    if toggle then
        localWheel.visible = false
        UnrenderWheelEntity(casinoId, entityId)
    else
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - localWheel.coords) <= Config.RenderDistance then
            localWheel.visible = true
            RenderWheelEntity(casinoId, entityId)
        end
    end
end)

RegisterNetEvent("pickle_casinos:refreshCasinoEntity", function(casinoId, entityId)
    if not LocalWheels[casinoId] then return end
    if not LocalWheels[casinoId][entityId] then return end
    local localWheel = LocalWheels[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    localWheel.coords = casinoEntity.settings.location.coords
    localWheel.heading = casinoEntity.settings.location.rotation.z
    if not localWheel.visible then return end
    UnrenderWheelEntity(casinoId, entityId)
    Wait(100)
    RenderWheelEntity(casinoId, entityId)
end)

RegisterNUICallback("setWheelWager", function(data, cb)
    TriggerServerEvent("pickle_casinos:wheel:setWager", data.wager)
end)

RegisterNUICallback("repeatWheelWager", function(data, cb)
    TriggerServerEvent("pickle_casinos:wheel:repeatWager")
end)

RegisterNetEvent("pickle_casinos:updateBalance", function(balance)
    if not CurrentWheel then return end
    CurrentWheel.balance = balance
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
    if not localWheel or not localWheel.visible then return end
    local isCurrentWheel = (CurrentWheel and CurrentWheel.casinoId == casinoId and CurrentWheel.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local targetRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
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
                    -15.0, 0.0, localWheel.heading + 0.0, 90.0, 
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
                    -15.0, 0.0, localWheel.heading + 0.0, 90.0, 
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

RegisterNetEvent("pickle_casinos:exitGame", function()
    if not CurrentWheel then return end
    TriggerServerEvent("pickle_casinos:wheel:leaveTable")
    ExitCasinoCamera(CurrentCamera)
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