local LocalThunderRouletteTables = {}
local PLAY_AREA_OFFSETS = {
    [1] = {
        seatOffset = {
            coords = vector3(-0.2, -0.3, 0.0),
            rotation = vector3(0.0, 0.0, 0.0),
        },
    },
    [2] = {
        seatOffset = {
            coords = vector3(0.765, -0.3, 0.0),
            rotation = vector3(0.0, 0.0, 0.0),
        },
    },
    [3] = {
        seatOffset = {
            coords = vector3(0.895, -0.125, 0.0),
            rotation = vector3(0.0, 0.0, 90.0),
        },
    },
    [4] = {
        seatOffset = {
            coords = vector3(0.765, 0.125, 0.0),
            rotation = vector3(0.0, 0.0, 180.0),
        },
    },
}
local CurrentThunderRouletteTable = nil
local playingThunderRouletteAnimation = false
local CurrentCamera = nil

function DoesThunderRouletteEntityExist(casinoId, entityId)
    return LocalThunderRouletteTables[casinoId] and LocalThunderRouletteTables[casinoId][entityId]
end

function GetThunderRouletteSeatsForUI(currentHand)
    local seats = {}
    for i=1, 4 do
        local seat = CurrentThunderRouletteTable.seats[i]
        local wager = 0
        if (seat.connects) then
            for j=1, #seat.connects do
                wager = wager + seat.connects[j].wager
            end
        end
        table.insert(seats, {
            source = seat.source,
            name = seat.name or "Unknown",
            connects = seat.connects or {},
            wager = wager,
        })
    end
    return seats
end

function PlayThunderRouletteAnimation(ped, animation, data)
    playingThunderRouletteAnimation = true
    SetTimeout((data and data.time) or 1000, function()
        playingThunderRouletteAnimation = false
    end)
    local playArea = LocalThunderRouletteTables[CurrentThunderRouletteTable.casinoId][CurrentThunderRouletteTable.entityId].playAreas[CurrentThunderRouletteTable.seatId]
    local coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.5, 0.05)
    local rotation = GetEntityRotation(playArea.surfaceObject) + vector3(0.0, 0.0, 90.0)
    local netScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, rotation.x, rotation.y, rotation.z, 2, 1, 0, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(ped, netScene, animation.dict, animation.name, 2.0, -2.0, 13, 16, 2.0, 0)
    NetworkStartSynchronisedScene(netScene)
end

function AttemptSeatAtThunderRouletteEntity(casinoId, entityId)
    local ped = PlayerPedId()
    local rouletteTable = LocalThunderRouletteTables[casinoId][entityId]
    local closest = {seatId = -1, distance = 100.0}
    for i,playArea in pairs(rouletteTable.playAreas) do
        local coords = GetEntityCoords(playArea.surfaceObject)
        local distance = #(GetEntityCoords(ped) - coords)
        if distance < closest.distance then
            closest = {seatId = i, distance = distance}
        end
    end
    ServerCallback("pickle_casinos:thunder_roulette:requestSeat", function(seatId, entityInfo)
        if not seatId then
            return
        end
        if entityInfo and entityInfo.seats then
            for i, seat in pairs(entityInfo.seats) do
                seat.connects = ApplyThunderRouletteWagers(seat.wagers)
                seat.wagers = nil
            end
        end
        CurrentThunderRouletteTable = {
            casinoId = casinoId,
            entityId = entityId,
            seatId = seatId,
            seats = entityInfo.seats,
            stage = entityInfo.stage,
            connects = entityInfo.connects,
            money = entityInfo.money,
            betRange = entityInfo.betRange,
            history = entityInfo.history,
        }
        local casinoId = CurrentThunderRouletteTable.casinoId
        local entityId = CurrentThunderRouletteTable.entityId
        local seatId = CurrentThunderRouletteTable.seatId
        if Config.ToggleGameMode then
            Config.ToggleGameMode(true)
        end
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "setCurrentGame",
            game = {
                type = "thunder_roulette",
                data = {
                    seatId = seatId,
                    seats = GetThunderRouletteSeatsForUI(),
                    money = CurrentThunderRouletteTable.money,
                    wagerLimit = CurrentThunderRouletteTable.betRange,
                    stage = CurrentThunderRouletteTable.stage,
                    history = CurrentThunderRouletteTable.history,
                }
            }
        })
        if (CurrentThunderRouletteTable.stage.type == "waiting") then
            TriggerEvent("pickle_casinos:thunder_roulette:updateStage", casinoId, entityId, CurrentThunderRouletteTable.stage)
        end
        local playerPed = PlayerPedId()
        local playArea = rouletteTable.playAreas[seatId]
        PlayThunderRouletteAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_enter_left"}, {time = 6000})
        local initialCamSettings = {
            coords = GetGameplayCamCoord(),
            rotation = GetGameplayCamRot(),
            fov = GetGameplayCamFov(),
        }
        Wait(6000)
        local coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.5, 0.05)
        local rotation = GetEntityRotation(playArea.surfaceObject) + vector3(0.0, 0.0, 90.0)
        CreateThread(function()
            while CurrentThunderRouletteTable do
                if not playingThunderRouletteAnimation and not IsEntityPlayingAnim(playerPed, "anim_casino_b@amb@casino@games@shared@player@", "idle_cardgames", 3) then
                    local netScene = NetworkCreateSynchronisedScene(coords, rotation, 2, 0, 1, 1065353216, 0, 1065353216)
                    NetworkAddPedToSynchronisedScene(playerPed, netScene, "anim_casino_b@amb@casino@games@shared@player@", "idle_cardgames", 2.0, -2.0, 13, 16, 2.0, 0)
                    NetworkStartSynchronisedScene(netScene)
                end
                DisableIdleCamera(true)
                Wait(1500)
            end
        end)
    end, casinoId, entityId, closest.seatId)
end

function PerformThunderRouletteSpin(casinoId, entityId, numberString)
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local numberTranslation = {"00", "27", "10", "25", "29", "12", "8", "19", "31", "18", "6", "21", "33", "16", "4", "23", "35", "14", "2", "0", "28", "9", "26", "30", "11", "7", "20", "32", "17", "5", "22", "34", "15", "3", "24", "36", "13", "1"}
    local numberIndex = 1
    for i=1, #numberTranslation do
        if numberTranslation[i] == numberString then
            numberIndex = i
            break;
        end
    end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    local rouletteTable = LocalThunderRouletteTables[casinoId][entityId]
    local targetCoords = GetWorldPositionOfEntityBone(rouletteTable.tableObject, GetEntityBoneIndexByName(rouletteTable.tableObject, "Roulette_Wheel"))
    local ballObject = rouletteTable.ballObject
    if (not ballObject or not DoesEntityExist(ballObject)) then
        ballObject = CreateProp(`vw_prop_roulette_ball`, targetCoords, false, false, false)
        rouletteTable.ballObject = ballObject
    end
    SetEntityCoordsNoOffset(ballObject, targetCoords, false, false, false)
    SetEntityRotation(ballObject, 0.0, 0.0, heading + 90.0, 2, true)
    if CurrentThunderRouletteTable and CurrentThunderRouletteTable.casinoId == casinoId and CurrentThunderRouletteTable.entityId == entityId then
        EnsureThunderRouletteCamera()
        local wheelOffset = GetOffsetFromEntityGivenWorldCoords(rouletteTable.tableObject, targetCoords.x, targetCoords.y, targetCoords.z)
        local camTarget = GetOffsetFromEntityInWorldCoords(rouletteTable.tableObject, wheelOffset + vector3(0.0, -0.12, 0.65))
        SetCamParams(CurrentCamera, camTarget.x, camTarget.y, camTarget.z,
            -90.0, 0.0, heading, 80.0,
            2000, 0, 0, 2
        )
    end

    local tableDict = "anim_casino_b@amb@casino@games@roulette@table"
    RequestAnimDict(tableDict)
    while not HasAnimDictLoaded(tableDict) do
        Wait(0)
    end
    local rouletteAnimation = function(object, animation)
        PlayEntityAnim(object, animation, tableDict, 1000.0, false, true, false, 0.0, 136704)
    end
    rouletteAnimation(ballObject, "intro_ball")
    rouletteAnimation(ballObject, "loop_ball")
    rouletteAnimation(rouletteTable.tableObject, "intro_wheel")
    rouletteAnimation(rouletteTable.tableObject, "loop_wheel")
    rouletteAnimation(ballObject, "exit_"..numberIndex.."_ball")
    rouletteAnimation(rouletteTable.tableObject, "exit_"..numberIndex.."_wheel")
end

function CreateThunderRouletteEntity(casinoId, entityId)
    if DoesThunderRouletteEntityExist(casinoId, entityId) then return end
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z

    if not LocalThunderRouletteTables[casinoId] then LocalThunderRouletteTables[casinoId] = {} end
    LocalThunderRouletteTables[casinoId][entityId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - coords) < Config.RenderDistance,
        coords = coords,
        heading = heading,
    }
    RenderThunderRouletteEntity(casinoId, entityId)
end

function IsThunderRouletteEntityVisible(casinoId, entityId)
    return DoesThunderRouletteEntityExist(casinoId, entityId) and LocalThunderRouletteTables[casinoId][entityId].visible
end

function RenderThunderRouletteEntity(casinoId, entityId)
    local localRouletteTable = LocalThunderRouletteTables[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not IsThunderRouletteEntityVisible(casinoId, entityId) or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    local tableObject = CreateProp(casinoEntity.settings.tableModel, coords, false, false, false)
    local surfaceObject = CreateTennisBall(coords - vector3(0.0, 0.0, 0.11), false, false, false)
    FreezeEntityPosition(tableObject, true)
    SetEntityHeading(tableObject, heading)
    FreezeEntityPosition(surfaceObject, true)
    SetEntityHeading(surfaceObject, heading)
    local dealerCoords = GetOffsetFromEntityInWorldCoords(surfaceObject, 0.0, 0.75, 0.03)
    local dealerPed = CreateDealerPed(casinoEntity.settings.dealerModel, dealerCoords, heading + 180.0)
    SetEntityInvincible(dealerPed, true)
    SetBlockingOfNonTemporaryEvents(dealerPed, true)
    FreezeEntityPosition(dealerPed, true)
    localRouletteTable.dealerPed = dealerPed
    localRouletteTable.tableObject = tableObject
    localRouletteTable.surfaceObject = surfaceObject
    localRouletteTable.connects = CreateEmptyThunderRouletteConnections()
    localRouletteTable.interacts = {}
    localRouletteTable.playAreas = {{},{},{},{}}
    for i,v in pairs(LocalThunderRouletteTables[casinoId][entityId].playAreas) do
        local playArea = LocalThunderRouletteTables[casinoId][entityId].playAreas[i]
        local seatOffset = PLAY_AREA_OFFSETS[i].seatOffset
        playArea.surfaceObject = CreateTennisBall(GetOffsetFromEntityInWorldCoords(surfaceObject, seatOffset.coords - vector3(0.0, 0.0, 0.05)), false, false, false)
        FreezeEntityPosition(playArea.surfaceObject, true)
        SetEntityHeading(playArea.surfaceObject, heading + seatOffset.rotation.z)
    end
    LocalThunderRouletteTables[casinoId][entityId].interacts[1] = CreateInteraction({
        label = _L("interact_thunder_roulette") .. (casinoEntity.settings.vip and (" " .. _L("casino_vip_game")) or ""),
        coords = GetOffsetFromEntityInWorldCoords(surfaceObject, 0.0, 0.0, 1.0),
        icon = Config.TargetIcons and Config.TargetIcons["thunder_roulette"] or nil,
        radius = 2.5,
        distance = 2.5,
        heading = heading,
    }, function(selected)
        local casino = Casinos[casinoId]
        if not casino then return end
        if not casino.settings.isOpen then
            return ShowNotification(_L("casino_closed"))
        end
        local casinoEntity = GetCasinoEntity(casinoId, entityId)
        if casinoEntity.owner_info and LOCAL_IDENTIFIER == casinoEntity.owner_info.identifier and RequestCasinoEntityMenu(casinoId, entityId) then return end
        ServerCallback("pickle_casinos:getVIPStatus", function(isVIP)
            if casinoEntity.settings.vip and not isVIP then return ShowNotification(_L("casino_vip_required")) end
            AttemptSeatAtThunderRouletteEntity(casinoId, entityId)
        end, casinoId, entityId)
    end)
    SetTimeout(1000, function()
        RenderThunderRouletteChips(casinoId, entityId)
    end)
end

function UnrenderThunderRouletteEntity(casinoId, entityId)
    if not DoesThunderRouletteEntityExist(casinoId, entityId) then return end
    local rouletteTable = LocalThunderRouletteTables[casinoId][entityId]
    if rouletteTable.interacts then
        for i=1, #rouletteTable.interacts do
            DeleteInteraction(rouletteTable.interacts[i])
        end
    end
    if rouletteTable.dealerPed then DeleteScriptObject(rouletteTable.dealerPed) end
    if rouletteTable.tableObject then DeleteScriptObject(rouletteTable.tableObject) end
    if rouletteTable.surfaceObject then DeleteScriptObject(rouletteTable.surfaceObject) end
    if rouletteTable.ballObject then DeleteScriptObject(rouletteTable.ballObject) end
    if rouletteTable.playAreas then
        for i, v in pairs(rouletteTable.playAreas) do
            local playArea = rouletteTable.playAreas[i]
            DeleteScriptObject(playArea.surfaceObject)
        end
    end
    if rouletteTable.connects then
        for i=1, #rouletteTable.connects do
            for j=1, #rouletteTable.connects[i] do
                DeleteScriptObject(rouletteTable.connects[i][j])
            end
        end
    end
    rouletteTable.interacts = nil
    rouletteTable.tableObject = nil
    rouletteTable.surfaceObject = nil
    rouletteTable.dealerPed = nil
    rouletteTable.ballObject = nil
    rouletteTable.playAreas = nil
    rouletteTable.thunder = nil
end

function DeleteThunderRouletteEntity(casinoId, entityId)
    UnrenderThunderRouletteEntity(casinoId, entityId)
    LocalThunderRouletteTables[casinoId][entityId] = nil
end

function RenderThunderRouletteChips(casinoId, entityId)
    local positions = GetThunderRouletteConnectPositions()
    local rouletteTable = LocalThunderRouletteTables[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    for i=1, #rouletteTable.connects do
        for j=1, #rouletteTable.connects[i] do
            DeleteScriptObject(rouletteTable.connects[i][j])
        end
    end
    local wagerPositions = {}
    for i=1, #casinoEntity.seats do
        local wagers = ConvertThunderWagersToPositions(casinoEntity.seats[i].connects)
        for j=1, #wagers do
            wagerPositions[j] = wagers[j].wager + (wagerPositions[j] or 0)
        end
    end
    for i=1, #wagerPositions do
        local chipStack = {}
        if wagerPositions[i] > 0 then
            local chips = GetCalculatedChips(wagerPositions[i], 1)
            for j=1, #chips do
                local chip = chips[j]
                local chipObject = CreateProp(chip.model, GetOffsetFromEntityInWorldCoords(rouletteTable.surfaceObject, positions[i].x, positions[i].y, 1.0), false, false, false)
                SetEntityHeading(chipObject, rouletteTable.heading)
                table.insert(chipStack, chipObject)
            end
        end
        rouletteTable.connects[i] = chipStack
    end
end

CreateThread(function()
    while true do
        for casinoId, entities in pairs(LocalThunderRouletteTables) do
            for entityId, entity in pairs(entities) do
                if not entity.visible and not entity.hidden then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) <= Config.RenderDistance then
                        entity.visible = true
                        RenderThunderRouletteEntity(casinoId, entityId)
                    end
                else
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) > Config.RenderDistance then
                        entity.visible = false
                        UnrenderThunderRouletteEntity(casinoId, entityId)
                    end
                end
            end
        end
        Wait(1500)
    end
end)

-- Continuously draws glow markers over the thunder cells of the betting felt while the
-- ball is rolling. Terminates as soon as `localTable.thunder` is cleared (stage flips).
function StartThunderRouletteHighlightLoop(casinoId, entityId)
    local localTable = LocalThunderRouletteTables[casinoId] and LocalThunderRouletteTables[casinoId][entityId]
    if not localTable or localTable.highlightActive then return end
    localTable.highlightActive = true
    CreateThread(function()
        local numberPositions = GetThunderRouletteNumberPositions()
        while localTable.thunder and localTable.surfaceObject and DoesEntityExist(localTable.surfaceObject) do
            for number, _ in pairs(localTable.thunder) do
                local pos = numberPositions[number]
                if pos then
                    -- surfaceObject sits 0.11 below the table coords; +0.13 puts the base ~2cm above the felt.
                    local world = GetOffsetFromEntityInWorldCoords(localTable.surfaceObject, pos.x, pos.y, 0.13)
                    -- Type 28 = glowing vertical cylinder. Args mirror modules/casino/client.lua:697 layout.
                    DrawMarker(28, world.x, world.y, world.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.07, 0.07, 0.5, 100, 200, 255, 220, false, true, false, true)
                end
            end
            Wait(0)
        end
        localTable.highlightActive = false
    end)
end

RegisterNUICallback("updateThunderRouletteWagers", function(data, cb)
    TriggerServerEvent("pickle_casinos:thunder_roulette:updateThunderRouletteWagers", GetThunderRouletteWagersOnly(data.data.connects))
    cb("ok")
end)

RegisterNUICallback("repeatThunderRouletteWager", function(data, cb)
    if not CurrentThunderRouletteTable then return end
    ServerCallback("pickle_casinos:repeatThunderRouletteWager", function(data)
        local connects = ApplyThunderRouletteWagers(data and data.wagers)
        SendNUIMessage({
            type = "updateThunderRouletteWagers",
            data = {
                connects = connects,
                wager = (data and data.wager) or GetThunderRouletteTotalWager(connects),
            },
        })
    end)
    cb("ok")
end)

RegisterNetEvent("pickle_casinos:exitGame", function()
    if not CurrentThunderRouletteTable then return end
    if DoesThunderRouletteEntityExist(CurrentThunderRouletteTable.casinoId, CurrentThunderRouletteTable.entityId) then
        local rouletteTable = LocalThunderRouletteTables[CurrentThunderRouletteTable.casinoId][CurrentThunderRouletteTable.entityId]
        PlayCasinoDealerSpeech(rouletteTable.dealerPed, "MINIGAME_DEALER_LEAVE_NEUTRAL_GAME", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
    end
    local casinoId = CurrentThunderRouletteTable.casinoId
    local entityId = CurrentThunderRouletteTable.entityId
    local seatId = CurrentThunderRouletteTable.seatId
    local playerPed = PlayerPedId()
    PlayThunderRouletteAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_exit_left"}, {time = 4000})
    TriggerServerEvent("pickle_casinos:thunder_roulette:leaveTable", casinoId, entityId, seatId)
    ExitCasinoCamera(CurrentCamera)
    CurrentThunderRouletteTable = nil
    CurrentCamera = nil
    Wait(4000)
    ClearPedTasks(playerPed)
end)

RegisterNetEvent("pickle_casinos:thunder_roulette:updateHistory", function(casinoId, entityId, history)
    if not DoesThunderRouletteEntityExist(casinoId, entityId) then return end
    if not CurrentThunderRouletteTable then return end
    CurrentThunderRouletteTable.history = history
    SendNUIMessage({
        type = "updateThunderRouletteHistory",
        history = history,
    })
end)

RegisterNetEvent("pickle_casinos:updateBalance", function(balance)
    if not CurrentThunderRouletteTable then return end
    CurrentThunderRouletteTable.balance = balance
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)

RegisterNetEvent("pickle_casinos:thunder_roulette:updateSeatWager", function(casinoId, entityId, seatId, wagers)
    if not DoesThunderRouletteEntityExist(casinoId, entityId) then return end
    local connects = ApplyThunderRouletteWagers(wagers)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if casinoEntity and casinoEntity.seats and casinoEntity.seats[seatId] then
        casinoEntity.seats[seatId].connects = connects
    end
    if CurrentThunderRouletteTable and CurrentThunderRouletteTable.casinoId == casinoId and CurrentThunderRouletteTable.entityId == entityId then
        CurrentThunderRouletteTable.seats[seatId].connects = connects
        SendNUIMessage({
            type = "updateThunderRouletteSeats",
            seats = GetThunderRouletteSeatsForUI(),
        })
        if seatId == CurrentThunderRouletteTable.seatId then
            SendNUIMessage({
                type = "updateThunderRouletteWagers",
                data = {
                    connects = connects,
                    wager = GetThunderRouletteTotalWager(connects),
                },
            })
        end
    end
    local rouletteTable = LocalThunderRouletteTables[casinoId][entityId]
    if not rouletteTable or not rouletteTable.visible then return end
    RenderThunderRouletteChips(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:thunder_roulette:updateSeat", function(casinoId, entityId, seatId, seatData)
    if not DoesThunderRouletteEntityExist(casinoId, entityId) then return end
    if seatData then
        seatData.connects = ApplyThunderRouletteWagers(seatData.wagers)
        seatData.wagers = nil
    end
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if casinoEntity and casinoEntity.seats then
        casinoEntity.seats[seatId] = seatData
    end
    if CurrentThunderRouletteTable and CurrentThunderRouletteTable.casinoId == casinoId and CurrentThunderRouletteTable.entityId == entityId then
        SendNUIMessage({
            type = "updateThunderRouletteSeats",
            seats = GetThunderRouletteSeatsForUI(),
        })
        CurrentThunderRouletteTable.seats[seatId] = seatData
    end
    local rouletteTable = LocalThunderRouletteTables[casinoId][entityId]
    if not rouletteTable or not rouletteTable.visible then return end
    RenderThunderRouletteChips(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    if not LocalThunderRouletteTables[casinoId] then return end
    if not LocalThunderRouletteTables[casinoId][entityId] then return end
    DeleteThunderRouletteEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:setCasinoEntityHidden", function(casinoId, entityId, toggle)
    if not LocalThunderRouletteTables[casinoId] then return end
    if not LocalThunderRouletteTables[casinoId][entityId] then return end
    local rouletteTable = LocalThunderRouletteTables[casinoId][entityId]
    rouletteTable.hidden = toggle
    if toggle then
        rouletteTable.visible = false
        UnrenderThunderRouletteEntity(casinoId, entityId)
    else
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - rouletteTable.coords) <= Config.RenderDistance then
            rouletteTable.visible = true
            RenderThunderRouletteEntity(casinoId, entityId)
        end
    end
end)

RegisterNetEvent("pickle_casinos:refreshCasinoEntity", function(casinoId, entityId)
    if not LocalThunderRouletteTables[casinoId] then return end
    if not LocalThunderRouletteTables[casinoId][entityId] then return end
    local rouletteTable = LocalThunderRouletteTables[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    rouletteTable.coords = casinoEntity.settings.location.coords
    rouletteTable.heading = casinoEntity.settings.location.rotation.z
    if not rouletteTable.visible then return end
    UnrenderThunderRouletteEntity(casinoId, entityId)
    Wait(100)
    RenderThunderRouletteEntity(casinoId, entityId)
end)

function EnsureThunderRouletteCamera()
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

RegisterNetEvent("pickle_casinos:thunder_roulette:updateStage", function(casinoId, entityId, stage)
    if not DoesThunderRouletteEntityExist(casinoId, entityId) then return end
    local rouletteTable = LocalThunderRouletteTables[casinoId][entityId]
    if not rouletteTable or not rouletteTable.visible then return end
    local isCurrentTable = (CurrentThunderRouletteTable and CurrentThunderRouletteTable.casinoId == casinoId and CurrentThunderRouletteTable.entityId == entityId)
    local dealerPed = rouletteTable.dealerPed
    if stage.type == "waiting" then
        rouletteTable.thunder = nil
        PlayCasinoDealerSpeech(rouletteTable.dealerPed, "MINIGAME_DEALER_PLACE_BET", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
        if isCurrentTable then
            EnsureThunderRouletteCamera()
            local tableCoords = GetOffsetFromEntityInWorldCoords(rouletteTable.surfaceObject, 0.0, -0.5, 3.0)
            SetCamParams(CurrentCamera, tableCoords.x, tableCoords.y, tableCoords.z,
                -90.0, 0.0, rouletteTable.heading, 80.0,
                2000, 0, 0, 2
            )
            CreateThread(function()
                while stage.time > 1 do
                    stage.time = stage.time - 1
                    SendNUIMessage({
                        type = "updateThunderRouletteStage",
                        stage = {
                            type = "waiting",
                            time = stage.time,
                        }
                    })
                    Wait(1000)
                end
            end)
        end
    elseif stage.type == "rolling" then
        rouletteTable.thunder = stage.thunder
        StartThunderRouletteHighlightLoop(casinoId, entityId)
        PlayCasinoDealerSpeech(rouletteTable.dealerPed, "MINIGAME_DEALER_CLOSED_BETS", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
        if isCurrentTable then
            SendNUIMessage({
                type = "updateThunderRouletteStage",
                stage = {
                    type = "rolling",
                    thunder = stage.thunder,
                }
            })
        end
        PerformThunderRouletteSpin(casinoId, entityId, stage.targetNumber)
    elseif stage.type == "winningNumber" then
        -- Keep only the winning number's marker if it was a thunder strike; clear otherwise.
        if stage.thunder and stage.thunder[stage.winningNumber] then
            rouletteTable.thunder = { [stage.winningNumber] = stage.thunder[stage.winningNumber] }
            StartThunderRouletteHighlightLoop(casinoId, entityId)
        else
            rouletteTable.thunder = nil
        end
        PlayCasinoDealerSpeech(rouletteTable.dealerPed, ("MINIGAME_ROULETTE_BALL_" .. stage.winningNumber), "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
        if isCurrentTable then
            SendNUIMessage({
                type = "updateThunderRouletteStage",
                stage = {
                    type = "winningNumber",
                    winningNumber = stage.winningNumber,
                    thunder = stage.thunder,
                }
            })
            if stage.seats and stage.seats[CurrentThunderRouletteTable.seatId] then
                local seatResult = stage.seats[CurrentThunderRouletteTable.seatId]
                if seatResult.totalWin > 0 then
                    SendNUIMessage({
                        type = "displayResults",
                        results = {winnings = seatResult.totalWin},
                    })
                end
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k,v in pairs(LocalThunderRouletteTables) do
            for id, _ in pairs(v) do
                DeleteThunderRouletteEntity(k, id)
            end
        end
    end
end)
