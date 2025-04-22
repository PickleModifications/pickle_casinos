local horses = {}

local CurrentCamera = nil
local raceCenter = vector3(1158.0900, 258.6992, 80.8438)
local heading = 147.9117
local raceDistance = 171.15
local winnerSpeed = -1
local defaultSpeed = 0.0012

local Tracks = {}
local LocalHorseRacingMachines = {}
local LocalHorseRacingTracks = {}
local viewingHorseRacingMenu = nil
local CurrentTrack = nil


-- Machines

function DisplayHorseRacingMenu(casinoId, entityId)
    if viewingHorseRacingMenu then return end
    ServerCallback("pickle_casinos:horseracing:getHorseRacingInfo", function(result)
        local casinoEntity = GetCasinoEntity(casinoId, entityId)
        if not casinoEntity then return end
        if not result then return end
        viewingHorseRacingMenu = {casinoId = casinoId, entityId = entityId}
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "setCurrentGame",
            game = {
                type = "horseracing",
                data = {
                    money = result.money,
                    tracks = result.tracks,
                    wagerLimit = casinoEntity.betRange,
                }
            }
        })
        CreateThread(function()
            while viewingHorseRacingMenu do
                if CurrentTrack and CurrentTrack.waitingTime > 0 and Tracks[CurrentTrack.id].stage.type == "waiting" then
                    CurrentTrack.waitingTime = CurrentTrack.waitingTime - 1
                    SendNUIMessage({
                        type = "updateHorseRacingStage",
                        stage = {
                            type = "waiting",
                            time = CurrentTrack.waitingTime,
                        },
                    })
                end 
                Wait(1000)
            end
        end)
    end, casinoId, entityId)
end

function CreateHorseRacingEntity(casinoId, entityId)
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    if not LocalHorseRacingMachines[casinoId] then
        LocalHorseRacingMachines[casinoId] = {}
    end
    LocalHorseRacingMachines[casinoId][entityId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - coords) < Config.RenderDistance,
        coords = coords,
        heading = heading,
    }
    RenderHorseRacingEntity(casinoId, entityId)
end

function RenderHorseRacingEntity(casinoId, entityId)
    local localHorseRacingMachine = LocalHorseRacingMachines[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not localHorseRacingMachine.visible or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    local machineObject = CreateProp(Config.HorseRacing.machineModel, coords.x, coords.y, coords.z, false, false, false)
    SetEntityRotation(machineObject, 0.0, 0.0, heading, 2, true)
    localHorseRacingMachine.machineObject = machineObject
    localHorseRacingMachine.interact = CreateInteraction({
        label = _L("interact_horseracing"),
        coords = GetOffsetFromEntityInWorldCoords(machineObject, 0.0, 0.0, 1.0),
        heading = heading,
    }, function(selected)
        DisplayHorseRacingMenu(casinoId, entityId)
    end)
end

function UnrenderHorseRacingEntity(casinoId, entityId)
    local localHorseRacingMachine = LocalHorseRacingMachines[casinoId][entityId]
    if not localHorseRacingMachine then return end
    if localHorseRacingMachine.machineObject then
        DeleteObject(localHorseRacingMachine.machineObject)
    end
    if localHorseRacingMachine.interact then
        DeleteInteraction(localHorseRacingMachine.interact)
    end
    localHorseRacingMachine.machineObject = nil
    localHorseRacingMachine.interact = nil
end

function DeleteHorseRacingEntity(casinoId, entityId)
    UnrenderHorseRacingEntity(casinoId, entityId)
    LocalHorseRacingMachines[casinoId][entityId] = nil
end

function GenerateHorseRacingTrackArray(newTrack)
    local track = {}
    for k,v in pairs(newTrack) do
        track[k] = v
    end
    for i=1, #track.horses do 
        track.horses[i].progress = 0.0
        track.horses[i].odds = Config.HorseRacing.odds[track.horses[i].oddsIndex].label
    end
    print(json.encode(track, {indent = true}))
    return track
end

RegisterNetEvent("pickle_casinos:horseracing:updateWager", function(casinoId, trackId, wagers)
    if not CurrentTrack or not viewingHorseRacingMenu or viewingHorseRacingMenu.casinoId ~= casinoId or CurrentTrack.id ~= trackId then return end
    SendNUIMessage({
        type = "updateHorseRacingWager",
        wagers = wagers,
    })
end)

RegisterNUICallback("setHorseRacingWager", function(data, cb)
    TriggerServerEvent("pickle_casinos:horseracing:setWager", viewingHorseRacingMenu.casinoId, viewingHorseRacingMenu.entityId, CurrentTrack.id, data.wager)
    cb("ok")
end)

RegisterNUICallback("repeatHorseRacingWager", function()
    TriggerServerEvent("pickle_casinos:horseracing:setWager", viewingHorseRacingMenu.casinoId, viewingHorseRacingMenu.entityId, CurrentTrack.id, "repeat")
    cb("ok")
end)

RegisterNUICallback("setHorseRacingTrack", function(data, cb)
    local trackId = data.trackId
    ServerCallback("pickle_casinos:horseracing:getHorseRacingInfo", function(result)
        local localTrack = LocalHorseRacingTracks[trackId]
        local newTrack = result.tracks[trackId]
        CurrentTrack = {id = trackId, waitingTime = Config.WaitingTime}
        if result.tracks[trackId].stage.type == "waiting" then
            CurrentTrack.waitingTime = newTrack.stage.time
        end
        localTrack.visible = true
        RenderHorseRacingTrack(trackId)
        SendNUIMessage({
            type = "setHorseRacingTrack",
            track = GenerateHorseRacingTrackArray(result.tracks[trackId]),
        })
        StartHorseRaceCamera()
    end)
    cb("ok")
end)

CreateThread(function()
    while true do 
        local coords = GetEntityCoords(PlayerPedId())
        for casinoId, entities in pairs(LocalHorseRacingMachines) do
            for entityId, entity in pairs(entities) do
                if not entity.visible and not entity.hidden then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) <= Config.RenderDistance then
                        entity.visible = true
                        RenderHorseRacingEntity(casinoId, entityId)
                    end
                elseif entity.visible then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) > Config.RenderDistance then
                        entity.visible = false
                        UnrenderHorseRacingEntity(casinoId, entityId)
                    end
                end
            end
        end
        Wait(1500)
    end
end)


RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    if not LocalHorseRacingMachines[casinoId] then return end
    if not LocalHorseRacingMachines[casinoId][entityId] then return end
    DeleteHorseRacingEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:setCasinoEntityHidden", function(casinoId, entityId, toggle)
    if not LocalHorseRacingMachines[casinoId] then return end
    if not LocalHorseRacingMachines[casinoId][entityId] then return end
    local horseMachine = LocalHorseRacingMachines[casinoId][entityId]
    horseMachine.hidden = toggle
    if toggle then
        horseMachine.visible = false
        UnrenderHorseRacingEntity(casinoId, entityId)
    else
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - horseMachine.coords) <= Config.RenderDistance then
            horseMachine.visible = true
            RenderHorseRacingEntity(casinoId, entityId)
        end
    end
end)

RegisterNetEvent("pickle_casinos:refreshCasinoEntity", function(casinoId, entityId)
    if not LocalHorseRacingMachines[casinoId] then return end
    if not LocalHorseRacingMachines[casinoId][entityId] then return end
    local horseMachine = LocalHorseRacingMachines[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    horseMachine.coords = casinoEntity.settings.location.coords
    horseMachine.heading = casinoEntity.settings.location.rotation.z
    if not horseMachine.visible then return end
    UnrenderHorseRacingEntity(casinoId, entityId)
    Wait(100)
    RenderHorseRacingEntity(casinoId, entityId)
end)

-- Tracks

function CreateHorseRacingTrack(trackId)
    local track = Tracks[trackId]
    if not track then return end
    if LocalHorseRacingTracks[trackId] then return end
    LocalHorseRacingTracks[trackId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - track.coords) < track.renderDistance,
        renderDistance = track.renderDistance,
        coords = track.coords,
        heading = track.heading,
    }
    RenderHorseRacingTrack(trackId)
end

function RenderHorseRacingTrack(trackId)
    local localTrack = LocalHorseRacingTracks[trackId]
    local track = Tracks[trackId]
    if not localTrack.visible or not track then return end
    UnrenderHorseRacingTrack(trackId)
    local coords = track.coords
    local heading = track.heading
    localTrack.raceCenterObject = CreateProp(`prop_tennis_ball`, coords.x, coords.y, coords.z, false, false, false)
    SetEntityAlpha(localTrack.raceCenterObject, 0, false)
    SetEntityHeading(localTrack.raceCenterObject, heading)
    local finishCoords = GetOffsetFromEntityInWorldCoords(localTrack.raceCenterObject, 0.0, track.distance, 0.3)
    localTrack.raceFinishObject = CreateProp(`xs_prop_arena_finish_line`, finishCoords.x, finishCoords.y, finishCoords.z, false, false, false)
    SetEntityHeading(localTrack.raceFinishObject, heading)
    FreezeEntityPosition(localTrack.raceFinishObject, true)
    localTrack.horses = {}
    local horseCount = 12
    for i=1, horseCount do
        local startCoords = GetOffsetFromEntityInWorldCoords(localTrack.raceCenterObject, ((i-1) * 1.0) - (horseCount / 2), 0.0, 0.0)
        local horse = {}
        horse.ped = CreateNPC(`RaceHorse`, startCoords.x, startCoords.y, startCoords.z, false, false)
        SetPedComponentVariation(horse.ped, 11, 0, i - 1, 0)
        horse.surfaceObject = CreateProp(`prop_tennis_ball`, startCoords.x, startCoords.y, startCoords.z, false, false, false)
        SetEntityAlpha(horse.surfaceObject, 0, false)
        SetEntityHeading(horse.surfaceObject, heading)
        AttachEntityToEntity(horse.ped, horse.surfaceObject, 0, 0, 0, 0.95, 0, 0, 0, false, false, false, false, 2, true)
        FreezeEntityPosition(horse.surfaceObject, true)
        horse.startCoords = startCoords
        localTrack.horses[i] = horse
        SetEntityCoords(localTrack.horses[i].surfaceObject, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
        ClearPedTasksImmediately(localTrack.horses[i].ped)
    end
end

function UnrenderHorseRacingTrack(trackId)
    local localTrack = LocalHorseRacingTracks[trackId]
    if not localTrack then return end
    if localTrack.raceCenterObject then
        DeleteScriptObject(localTrack.raceCenterObject)
    end
    if localTrack.raceFinishObject then
        DeleteScriptObject(localTrack.raceFinishObject)
    end
    if localTrack.horses then
        for i=1, #localTrack.horses do
            local horse = localTrack.horses[i]
            if horse.surfaceObject then
                DeleteScriptObject(horse.surfaceObject)
            end
            if horse.ped then
                DeleteScriptObject(horse.ped)
            end
        end
    end
    localTrack.raceCenterObject = nil
    localTrack.raceFinishObject = nil
end

function ResetHorseTrackPositions(trackId)
    local localTrack = LocalHorseRacingTracks[trackId]
    if not localTrack or not localTrack.visible then return end
    for i=1, #localTrack.horses do
        local startCoords = GetOffsetFromEntityInWorldCoords(localTrack.raceCenterObject, ((i-1) * 1.0) - (#localTrack.horses / 2), 0.0, 0.0)
        SetEntityCoords(localTrack.horses[i].surfaceObject, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
        ClearPedTasksImmediately(localTrack.horses[i].ped)
    end
end

function StartHorseRaceCamera()
    if not CurrentTrack then return end
    local track = Tracks[CurrentTrack.id]
    if not track then return end
    local localTrack = LocalHorseRacingTracks[CurrentTrack.id]
    if not localTrack or not localTrack.visible then return end
    local camCoords = GetOffsetFromEntityInWorldCoords(localTrack.raceCenterObject, 11.0, 2.0, 6.0)
    SetFocusArea(camCoords)
    EnsureHorseRacingCamera()
    SetCamParams(CurrentCamera, camCoords.x, camCoords.y, camCoords.z,
        -35.0, 0.0, localTrack.heading + 90.0, 45.0, 
        0, 0, 0, 2
    )
end

function EnsureHorseRacingCamera()
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

function StartHorseRace(trackId, targetWinner)    
    local localTrack = LocalHorseRacingTracks[trackId]
    local track = Tracks[trackId]
    if not track or not localTrack or not localTrack.visible then return end
    local raceDistance = track.distance
    for i=1, #localTrack.horses do 
        local horse = localTrack.horses[i]
        horse.destination = GetOffsetFromEntityInWorldCoords(horse.surfaceObject, 0.0, raceDistance - 2.1, 0.0)
        horse.speed = defaultSpeed
        horse.targetSpeed = defaultSpeed * 2
        horse.progress = 0.0
        horse.startedLosing = false
        PlayAnim(horse.ped, "creatures@deer@move", "gallop", 1.0, 1.0, -1, 1, 1.0)
    end
    local raceFinish = false
    local closestDistance = 1000.0
    local winProgress = math.random(35, 85) / 100
    local finishPositions = {}
    while true do
        local pedDistance = 1000.0
        local pedCoords = GetEntityCoords(PlayerPedId())
        local targetCoords = GetEntityCoords(localTrack.horses[targetWinner].surfaceObject)
        local done = true
        for i=1, #localTrack.horses do 
            local horse = localTrack.horses[i]
            if winnerSpeed < 0 and horse.progress > winProgress then
                local targetHorse = localTrack.horses[targetWinner]
                winnerSpeed = targetHorse.speed + (defaultSpeed / math.random(20, 40))
                targetHorse.speed = winnerSpeed
                print("MAX OVERDRIVE", targetWinner, i, winnerSpeed)
            end
            if i ~= targetWinner and winnerSpeed > 0 and not horse.startedLosing then
                local horseRemainingIterations
                local targetRemainingIterations = (1.0 - localTrack.horses[targetWinner].progress) / winnerSpeed
                repeat 
                    horse.speed = horse.speed - (defaultSpeed / 100)
                    horseRemainingIterations = (1.0 - horse.progress) / horse.speed
                until targetRemainingIterations < horseRemainingIterations - 2
                horse.startedLosing = true
            end
            if winnerSpeed < 0 or raceFinish then
                if horse.targetSpeed < horse.speed then
                    horse.speed = horse.speed - (defaultSpeed / 10)
                    if horse.speed <= horse.targetSpeed then
                        horse.speed = horse.targetSpeed
                        generateNewSpeed = true
                    end
                elseif horse.targetSpeed > horse.speed then
                    horse.speed = horse.speed + (defaultSpeed / 10)
                    if horse.speed >= horse.targetSpeed then
                        horse.speed = horse.targetSpeed
                        generateNewSpeed = true
                    end
                end
                if generateNewSpeed then
                    generateNewSpeed = false
                    horse.targetSpeed = defaultSpeed * (math.random(100, 150) / 100)
                end
            end
            horse.progress = horse.progress + horse.speed
            if horse.progress >= 1.0 then 
                if not raceFinish then
                    raceFinish = true
                    for i=1, #localTrack.horses do 
                        finishPositions[i] = localTrack.horses[i].progress
                    end
                end
                if horse.progress < 1.15 then
                    done = false
                end
            else
                done = false
            end
            local startCoords = horse.startCoords
            local destination = horse.destination
            local coords = lerp(startCoords, destination, horse.progress)
            local pedDist = #(coords - pedCoords)
            if pedDist < pedDistance then
                pedDistance = pedDist
            end
            if not raceFinish then
                local dist = #(coords - destination)
                if dist < closestDistance then
                    closestDistance = dist
                end
            end
            SetEntityCoords(horse.surfaceObject, coords.x, coords.y, coords.z, false, false, false, false)
        end
        local camCoords = GetOffsetFromEntityInWorldCoords(localTrack.raceCenterObject, 11.0, raceDistance - closestDistance, 6.0)
        DrawMarker(0, targetCoords.x, targetCoords.y, targetCoords.z + 1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.5, 255, 0, 0, 255, false, true, false, false, false, false, false, false)
        if viewingHorseRacingMenu and CurrentTrack and CurrentTrack.id == trackId then
            SetFocusArea(camCoords)
            EnsureHorseRacingCamera()
            SetCamParams(CurrentCamera, camCoords.x, camCoords.y, camCoords.z,
                -35.0, 0.0, heading + 90.0, 45.0, 
                0, 0, 0, 2
            )
            SendNUIMessage({
                type = "updateHorseRacingHorses",
                horses = localTrack.horses,
            })
        end
        if pedDistance < 2.0 then
            local entity = PlayerPedId()
            if IsPedInAnyVehicle(entity, true) then
                entity = GetVehiclePedIsIn(entity, false)
            end
            SetEntityVelocity(entity, math.random(10, 100) * 1.1, math.random(10, 100) * 1.1, math.random(10, 100) * 1.1)
            SetPedToRagdoll(entity, 5000, 5000, 0, false, false, false)
        end
        if done then break end
        local gameSpeed = math.floor((8 * (CLIENT_FPS / 60)) - 8)
        if gameSpeed < 0 then gameSpeed = 0 end
        Wait(gameSpeed)
    end
    winnerSpeed = -1
    if viewingHorseRacingMenu and CurrentTrack and CurrentTrack.id == trackId then
        local opacity = 0.0
        while opacity < 1.0 do 
            local op = math.floor(opacity * 255)
            if op > 255 then
                op = 255
            end
            DrawRect(0.5, 0.5, 1.0, 1.0, 255, 255, 255, op)
            opacity = opacity + 0.01
            Wait(0)
        end
        opacity = 1.0
        SendNUIMessage({
            type = "updateHorseRacingStage",
            stage = {
                type = "winner",
                winner = targetWinner,
            },
        })
        CreateThread(function()
            for i=1, #finishPositions do 
                local horse = localTrack.horses[i]
                local startCoords = horse.startCoords
                local destination = horse.destination
                local coords = lerp(startCoords, destination, finishPositions[i])
                SetEntityCoords(horse.surfaceObject, coords.x, coords.y, coords.z, false, false, false, false)
                ClearPedTasks(horse.ped)
                PlayAnim(horse.ped, "creatures@deer@move", "gallop", 8.0, 8.0, -1, 2, 1.0)
            end
        end)
        while opacity > 0.0 do 
            local op = math.floor(opacity * 255)
            if op > 255 then
                op = 255
            end
            DrawRect(0.5, 0.5, 1.0, 1.0, 255, 255, 255, op)
            opacity = opacity - 0.01
            Wait(0)
        end
        Wait(5000)
    else
        ResetHorseTrackPositions(trackId)
    end
end

function DeleteHorseRace()
    if raceCenterObject then
        DeleteScriptObject(raceCenterObject)
    end
    if raceFinishObject then
        DeleteScriptObject(raceFinishObject)
    end
    for _, horse in pairs(horses) do
        DeleteScriptObject(horse.ped)
        DeleteScriptObject(horse.surfaceObject)
    end
end

function ExitHorseTrackView()
    if CurrentTrack then 
        TriggerServerEvent("pickle_casinos:horseracing:setWager", viewingHorseRacingMenu.casinoId, viewingHorseRacingMenu.entityId, CurrentTrack.id, "clear")
    end
    if CurrentTrack then
        LocalHorseRacingTracks[CurrentTrack.id].visible = false
        UnrenderHorseRacingTrack(CurrentTrack.id)
        CurrentTrack = nil
    end
    if CurrentCamera then
        SetFocusEntity(PlayerPedId())
        DestroyCam(CurrentCamera, false)
        RenderScriptCams(false, true, 0, false, false) 
        CurrentCamera = nil
    end
end

CreateThread(function()
    while true do 
        local coords = GetEntityCoords(PlayerPedId())
        for trackId, track in pairs(LocalHorseRacingTracks) do
            if not track.visible then
                if #(GetEntityCoords(PlayerPedId()) - track.coords) <= track.renderDistance then
                    track.visible = true
                    RenderHorseRacingTrack(trackId)
                end
            else
                if not viewingHorseRacingMenu and #(GetEntityCoords(PlayerPedId()) - track.coords) > track.renderDistance then
                    track.visible = false
                    UnrenderHorseRacingTrack(trackId)
                end
            end
        end
        Wait(1500)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DeleteHorseRace()
        for k,v in pairs(LocalHorseRacingMachines) do
            for k2,v2 in pairs(v) do
                UnrenderHorseRacingEntity(k, k2)
            end
        end
        for k,v in pairs(LocalHorseRacingTracks) do
            UnrenderHorseRacingTrack(k)
        end
    end
end)

RegisterNetEvent("pickle_casinos:horseracing:updateTracks", function(tracks)
    Tracks = tracks
    for k, v in pairs(tracks) do
        CreateHorseRacingTrack(k)
    end
end)

RegisterNetEvent("pickle_casinos:horseracing:updateTrackStage", function(trackId, stage, horses)
    local localTrack = LocalHorseRacingTracks[trackId]
    local isCurrentTrack = (CurrentTrack and CurrentTrack.id == trackId)
    if Tracks[trackId] then
        Tracks[trackId].stage = stage
    end
    if not localTrack then return end
    if viewingHorseRacingMenu and isCurrentTrack and horses then
        local uiHorses = {}
        for i=1, #horses do 
            uiHorses[i] = {}
            uiHorses[i].progress = 0.0
            uiHorses[i].odds = Config.HorseRacing.odds[horses[i].oddsIndex].label
        end
        SendNUIMessage({
            type = "updateHorseRacingHorses",
            horses = uiHorses,
        })
    end
    if stage.type == "waiting" then
        if localTrack.visible then
            ResetHorseTrackPositions(trackId)
        end 
        if isCurrentTrack then
            CurrentTrack.waitingTime = stage.time
            StartHorseRaceCamera()   
        end
    elseif stage.type == "racing" and localTrack.visible then
        if isCurrentTrack then
            SendNUIMessage({
                type = "updateHorseRacingStage",
                stage = {
                    type = "racing",
                },
            })
        end
        StartHorseRace(trackId, stage.winner)
    end
end)

RegisterNUICallback("changeHorseRacingTrack", function(data, cb)
    ExitHorseTrackView()
    cb("ok")
end)

AddEventHandler("pickle_casinos:exitGame", function()
    ExitHorseTrackView()
    viewingHorseRacingMenu = nil
end)