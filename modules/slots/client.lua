local LocalSlotMachines = {}
local CurrentSlotMachine = nil
local CurrentCamera

function EnsureSlotCamera()
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

function PlaySlotAnimation(ped, animation, data)
    playingSlotAnimation = true
    SetTimeout((data and data.time) or 1000, function()
        playingSlotAnimation = false
    end)
    local surfaceObject = LocalSlotMachines[CurrentSlotMachine.casinoId][CurrentSlotMachine.entityId].slotObject
    local coords = GetOffsetFromEntityInWorldCoords(surfaceObject, 0.0, -0.75, 0.0275)
    local rotation = GetEntityRotation(surfaceObject) + vector3(0.0, 0.0, 90.0)
    local netScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, rotation.x, rotation.y, rotation.z, 2, 1, 0, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(ped, netScene, animation.dict, animation.name, 2.0, -2.0, 13, 16, 2.0, 0) -- 8.0, -1.5, 157, 16, 1148846080, 0) ?
    NetworkStartSynchronisedScene(netScene)
end

function AttemptSeatAtSlotEntity(casinoId, entityId)
    ServerCallback("pickle_casinos:slots:requestSeat", function(seatId, entityInfo)
        if not seatId then return end
        local localSlotMachine = LocalSlotMachines[casinoId][entityId]
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
        local playerPed = PlayerPedId()
        local camCoords = GetOffsetFromEntityInWorldCoords(localSlotMachine.slotObject, 0.0, -0.5, 1.3)
        EnsureSlotCamera()
        SetCamParams(CurrentCamera, camCoords.x, camCoords.y, camCoords.z,
            -20.0, 0.0, localSlotMachine.heading, 65.0, 
            2000, 0, 0, 2
        )
        PlaySlotAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_enter_left"}, {time = 6000})
        SetTimeout(2000, function()
            local slotStructure = GetSlotStructure()
            if not slotStructure then return end
            SetNuiFocus(true, true)
            SendNUIMessage({
                type = "setCurrentGame",
                game = {
                    type = "slot",
                    data = slotStructure
                }
            })
        end)
    end, casinoId, entityId)
end

function CreateSlotEntity(casinoId, entityId)
    if DoesSlotEntityExist(casinoId, entityId) then return end
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    local slotCfg = Config.Slots[casinoEntity.settings.game]
    if not slotCfg then return end
    if not LocalSlotMachines[casinoId] then
        LocalSlotMachines[casinoId] = {}
    end
    LocalSlotMachines[casinoId][entityId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - coords) < Config.RenderDistance,
        coords = coords,
        heading = heading,
    }
    RenderSlotEntity(casinoId, entityId)
end

function RenderSlotEntity(casinoId, entityId)
    local localSlotMachine = LocalSlotMachines[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not localSlotMachine.visible or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    local slotCfg = Config.Slots[casinoEntity.settings.game]
    local slotObject = CreateProp(slotCfg.model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityRotation(slotObject, 0.0, 0.0, heading, 2, true)
    localSlotMachine.slotObject = slotObject
    localSlotMachine.interact = CreateInteraction({
        label = _L("casino_slot_play") .. " " .. slotCfg.label  .. (casinoEntity.settings.vip and (" " .. _L("casino_vip_game")) or ""),
        coords = GetOffsetFromEntityInWorldCoords(slotObject, 0.0, 0.0, 1.0),
        heading = heading,
        radius = 0.5
    }, function(selected)
        ServerCallback("pickle_casinos:getVIPStatus", function(isVIP)
            if casinoEntity.settings.vip and not isVIP then return ShowNotification(_L("casino_vip_required")) end
            AttemptSeatAtSlotEntity(casinoId, entityId)
        end, casinoId, entityId)
    end)
end

function UnrenderSlotEntity(casinoId, entityId)
    local slotEntity = LocalSlotMachines[casinoId][entityId]
    if not slotEntity then return end
    if slotEntity.slotObject then
        DeleteObject(slotEntity.slotObject)
    end
    if slotEntity.interact then
        DeleteInteraction(slotEntity.interact)
    end
    slotEntity.interact = nil
    slotEntity.slotObject = nil
end

function DeleteSlotEntity(casinoId, entityId)
    UnrenderSlotEntity(casinoId, entityId)
    LocalSlotMachines[casinoId][entityId] = nil
end

CreateThread(function()
    while true do 
        local coords = GetEntityCoords(PlayerPedId())
        for casinoId, entities in pairs(LocalSlotMachines) do
            for entityId, entity in pairs(entities) do
                if not entity.visible and not entity.hidden then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) <= Config.RenderDistance then
                        entity.visible = true
                        RenderSlotEntity(casinoId, entityId)
                    end
                elseif entity.visible then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) > Config.RenderDistance then
                        entity.visible = false
                        UnrenderSlotEntity(casinoId, entityId)
                    end
                end
            end
        end
        Wait(1500)
    end
end)

RegisterNetEvent("pickle_casinos:slots:updateBalance", function(balance)
    if not CurrentSlotMachine then return end
    CurrentSlotMachine.money = balance
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    debugPrint("deleteCasinoEntity slot", casinoId, entityId)
    if not LocalSlotMachines[casinoId] then return end
    debugPrint("CASINO EXISTS")
    if not LocalSlotMachines[casinoId][entityId] then return end
    debugPrint("CASINO ENTITY EXISTS")
    DeleteSlotEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:setCasinoEntityHidden", function(casinoId, entityId, toggle)
    if not LocalSlotMachines[casinoId] then return end
    if not LocalSlotMachines[casinoId][entityId] then return end
    local slotMachine = LocalSlotMachines[casinoId][entityId]
    slotMachine.hidden = toggle
    if toggle then
        slotMachine.visible = false
        UnrenderSlotEntity(casinoId, entityId)
    else
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - slotMachine.coords) <= Config.RenderDistance then
            slotMachine.visible = true
            RenderSlotEntity(casinoId, entityId)
        end
    end
end)

RegisterNetEvent("pickle_casinos:refreshCasinoEntity", function(casinoId, entityId)
    if not LocalSlotMachines[casinoId] then return end
    if not LocalSlotMachines[casinoId][entityId] then return end
    local slotMachine = LocalSlotMachines[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    slotMachine.coords = casinoEntity.settings.location.coords
    slotMachine.heading = casinoEntity.settings.location.rotation.z
    if not slotMachine.visible then return end
    UnrenderSlotEntity(casinoId, entityId)
    Wait(100)
    RenderSlotEntity(casinoId, entityId)
end)

RegisterNUICallback("finishSpin", function(data, cb)
    TriggerServerEvent("pickle_casinos:slots:redeemSpin", data.id, data.spinIndex or 1)
    cb("ok")
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

RegisterNetEvent("pickle_casinos:exitGame", function()
    if not CurrentSlotMachine then return end
    local playerPed = PlayerPedId()
    PlaySlotAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_exit_left"}, {time = 4000})
    TriggerServerEvent("pickle_casinos:slots:leaveSlotMachine")
    SetTimeout(4000, function()
        ClearPedTasks(playerPed)
    end)
    DestroyCam(CurrentCamera)
    RenderScriptCams(false, true, 2000, false, false) 
    CurrentCamera = nil
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