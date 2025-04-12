local horses = {}
local raceCenterObject
local raceFinishObject
local CurrentCamera = nil
local isBetting = true
local raceCenter = vector3(1158.0900, 258.6992, 80.8438 + 0.95)
local heading = 147.9117
local raceDistance = 171.15
local winnerSpeed = -1
local defaultSpeed = 0.0012

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

function EnsureRacetrack()
    if not raceCenterObject or not DoesEntityExist(raceCenterObject) then
        raceCenterObject = CreateProp(`prop_tennis_ball`, raceCenter.x, raceCenter.y, raceCenter.z, false, false, false)
        SetEntityHeading(raceCenterObject, heading)
    end
    if not raceFinishObject or not DoesEntityExist(raceFinishObject) then   
        local finishCoords = GetOffsetFromEntityInWorldCoords(raceCenterObject, 0.0, raceDistance, -0.6)
        raceFinishObject = CreateProp(`xs_prop_arena_finish_line`, finishCoords.x, finishCoords.y, finishCoords.z, false, false, false)
        SetEntityHeading(raceFinishObject, heading)
        FreezeEntityPosition(raceFinishObject, true)
    end
    local horseCount = 12
    for i=1, horseCount do
        local startCoords = GetOffsetFromEntityInWorldCoords(raceCenterObject, ((i-1) * 1.0) - (horseCount / 2), 0.0, 0.0)
        if not horses[i] then
            local horse = {}
            horse.ped = CreateNPC(`RaceHorse`, startCoords.x, startCoords.y, startCoords.z, false, false)
            SetPedComponentVariation(horse.ped, 11, 0, i - 1, 0)
            horse.surfaceObject = CreateProp(`prop_tennis_ball`, startCoords.x, startCoords.y, startCoords.z, false, false, false)
            SetEntityHeading(horse.surfaceObject, heading)
            AttachEntityToEntity(horse.ped, horse.surfaceObject, 0, 0, 0, 0, 0, 0, 0, false, false, false, false, 2, true)
            FreezeEntityPosition(horse.surfaceObject, true)
            horse.startCoords = startCoords
            horses[i] = horse
        end
        SetEntityCoords(horses[i].surfaceObject, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
        ClearPedTasksImmediately(horses[i].ped)
    end
    if isBetting then
        local camCoords = GetOffsetFromEntityInWorldCoords(raceCenterObject, 10.0, 2.0, 5.0)
        SetFocusArea(camCoords)
        EnsureHorseRacingCamera()
        SetCamParams(CurrentCamera, camCoords.x, camCoords.y, camCoords.z,
            -30.0, 0.0, heading + 90.0, 45.0, 
            0, 0, 0, 2
        )
    end
end

function StartHorseRace(targetWinner)    
    EnsureRacetrack()
    for i=1, #horses do 
        local horse = horses[i]
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
        local targetCoords = GetEntityCoords(horses[targetWinner].surfaceObject)
        local done = true
        for i=1, #horses do 
            local horse = horses[i]
            if winnerSpeed < 0 and horse.progress > winProgress then
                local targetHorse = horses[targetWinner]
                winnerSpeed = targetHorse.speed + (defaultSpeed / math.random(20, 40))
                targetHorse.speed = winnerSpeed
                print("MAX OVERDRIVE", targetWinner, i, winnerSpeed)
            end
            if i ~= targetWinner and winnerSpeed > 0 and not horse.startedLosing then
                local horseRemainingIterations
                local targetRemainingIterations = (1.0 - horses[targetWinner].progress) / winnerSpeed
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
                    for i=1, #horses do 
                        finishPositions[i] = horses[i].progress
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
        local camCoords = GetOffsetFromEntityInWorldCoords(raceCenterObject, 10.0, raceDistance - closestDistance, 5.0)
        if isBetting then
            -- DrawMarker(0, targetCoords.x, targetCoords.y, targetCoords.z + 1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.5, 255, 0, 0, 255, false, true, false, false, false, false, false, false)
            SetFocusArea(camCoords)
            EnsureHorseRacingCamera()
            SetCamParams(CurrentCamera, camCoords.x, camCoords.y, camCoords.z,
                -30.0, 0.0, heading + 90.0, 45.0, 
                0, 0, 0, 2
            )
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
        Wait(0)
    end
    winnerSpeed = -1
    if isBetting then
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
        CreateThread(function()
            for i=1, #finishPositions do 
                local horse = horses[i]
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
        Wait(100)
    end
end

function StartHorseRaceWaiting()
    EnsureRacetrack()
end

function DeleteHorseRace()
    if raceCenterObject then
        DeleteEntity(raceCenterObject)
    end
    if raceFinishObject then
        DeleteEntity(raceFinishObject)
    end
    for _, horse in pairs(horses) do
        DeleteEntity(horse.ped)
        DeleteEntity(horse.surfaceObject)
    end
end

CreateThread(function()
    Wait(1000)
    while true do
        StartHorseRaceWaiting()
        Wait(5000)
        StartHorseRace(math.random(1, 12)) 
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DeleteHorseRace()
    end
end)