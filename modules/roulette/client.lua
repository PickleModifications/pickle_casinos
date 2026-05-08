local RouletteTables = {}
local LocalRouletteTables = {}
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
local CurrentRouletteTable = nil
local playingRouletteAnimation = false
local CurrentCamera = nil

function DoesRouletteEntityExist(casinoId, entityId)
    return LocalRouletteTables[casinoId] and LocalRouletteTables[casinoId][entityId]
end

function GetRouletteSeatsForUI(currentHand)
    local seats = {}
    for i=1, 4 do
        local seat = CurrentRouletteTable.seats[i]
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

function PlayRouletteAnimation(ped, animation, data)
    playingRouletteAnimation = true
    SetTimeout((data and data.time) or 1000, function()
        playingRouletteAnimation = false
    end)
    local playArea = LocalRouletteTables[CurrentRouletteTable.casinoId][CurrentRouletteTable.entityId].playAreas[CurrentRouletteTable.seatId]
    local coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.5, 0.05)
    local rotation = GetEntityRotation(playArea.surfaceObject) + vector3(0.0, 0.0, 90.0)
    local netScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, rotation.x, rotation.y, rotation.z, 2, 1, 0, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(ped, netScene, animation.dict, animation.name, 2.0, -2.0, 13, 16, 2.0, 0) -- 8.0, -1.5, 157, 16, 1148846080, 0) ?
    NetworkStartSynchronisedScene(netScene)
end

function AttemptSeatAtRouletteEntity(casinoId, entityId)
    local ped = PlayerPedId()
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    local closest = {seatId = -1, distance = 100.0}
    for i,playArea in pairs(rouletteTable.playAreas) do
        local coords = GetEntityCoords(playArea.surfaceObject)
        local distance = #(GetEntityCoords(ped) - coords)
        if distance < closest.distance then
            closest = {seatId = i, distance = distance}
        end
    end
    ServerCallback("pickle_casinos:roulette:requestSeat", function(seatId, entityInfo)
        if not seatId then
            return
        end
        if entityInfo and entityInfo.seats then
            for i, seat in pairs(entityInfo.seats) do
                seat.connects = ApplyRouletteWagers(seat.wagers)
                seat.wagers = nil
            end
        end
        CurrentRouletteTable = {
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
        local casinoId = CurrentRouletteTable.casinoId
        local entityId = CurrentRouletteTable.entityId
        local seatId = CurrentRouletteTable.seatId
        if Config.ToggleGameMode then
            Config.ToggleGameMode(true)
        end
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "setCurrentGame",
            game = {
                type = "roulette",
                data = {
                    seatId = seatId,
                    seats = GetRouletteSeatsForUI(),
                    money = CurrentRouletteTable.money,
                    wagerLimit = CurrentRouletteTable.betRange,
                    stage = CurrentRouletteTable.stage,
                    history = CurrentRouletteTable.history,
                }
            }
        })
        if (CurrentRouletteTable.stage.type == "waiting") then
            TriggerEvent("pickle_casinos:roulette:updateStage", casinoId, entityId, CurrentRouletteTable.stage)
        end
        local playerPed = PlayerPedId()
        local playArea = rouletteTable.playAreas[seatId]
        PlayRouletteAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_enter_left"}, {time = 6000})
        local initialCamSettings = {
            coords = GetGameplayCamCoord(),
            rotation = GetGameplayCamRot(),
            fov = GetGameplayCamFov(),
        }
        Wait(6000)
        local coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.5, 0.05)
        local rotation = GetEntityRotation(playArea.surfaceObject) + vector3(0.0, 0.0, 90.0)
        CreateThread(function()
            while CurrentRouletteTable do
                if not playingRouletteAnimation and not IsEntityPlayingAnim(playerPed, "anim_casino_b@amb@casino@games@shared@player@", "idle_cardgames", 3) then
                    local netScene = NetworkCreateSynchronisedScene(coords, rotation, 2, 0, 1, 1065353216, 0, 1065353216)
                    NetworkAddPedToSynchronisedScene(playerPed, netScene, "anim_casino_b@amb@casino@games@shared@player@", "idle_cardgames", 2.0, -2.0, 13, 16, 2.0, 0)
                    NetworkStartSynchronisedScene(netScene)
                end
                -- SetFollowPedCamViewMode(3)
                DisableIdleCamera(true)
                Wait(1500)
            end
        end)
    end, casinoId, entityId, closest.seatId)
end

function PerformRouletteSpin(casinoId, entityId, numberString)
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
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    local targetCoords = GetWorldPositionOfEntityBone(rouletteTable.tableObject, GetEntityBoneIndexByName(rouletteTable.tableObject, "Roulette_Wheel"))
    local ballObject = rouletteTable.ballObject
    if (not ballObject or not DoesEntityExist(ballObject)) then
        ballObject = CreateProp(`vw_prop_roulette_ball`, targetCoords, false, false, false)
        rouletteTable.ballObject = ballObject
    end
    SetEntityCoordsNoOffset(ballObject, targetCoords, false, false, false)
    SetEntityRotation(ballObject, 0.0, 0.0, heading + 90.0, 2, true)
    if CurrentRouletteTable and CurrentRouletteTable.casinoId == casinoId and CurrentRouletteTable.entityId == entityId then
        EnsureRouletteCamera()
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

function CreateRouletteEntity(casinoId, entityId)
    if DoesRouletteEntityExist(casinoId, entityId) then return end
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    -- local tempCard = CreateProp(`vw_prop_cas_card_club_04`, GetOffsetFromEntityInWorldCoords(surfaceObject, 0.0, 0.0, 0.0), false, false, false)
    -- FreezeEntityPosition(tempCard, true)
    -- SetEntityHeading(tempCard, heading)
    
    if not LocalRouletteTables[casinoId] then LocalRouletteTables[casinoId] = {} end
    LocalRouletteTables[casinoId][entityId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - coords) < Config.RenderDistance,
        coords = coords,
        heading = heading,
    }
    RenderRouletteEntity(casinoId, entityId)
    -- AttemptSeatAtRouletteEntity(casinoId, entityId)
end

function IsRouletteEntityVisible(casinoId, entityId)
    return DoesRouletteEntityExist(casinoId, entityId) and LocalRouletteTables[casinoId][entityId].visible
end

function RenderRouletteEntity(casinoId, entityId)
    local localRouletteTable = LocalRouletteTables[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not IsRouletteEntityVisible(casinoId, entityId) or not casinoEntity then return end
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
    localRouletteTable.connects = CreateEmptyRouletteConnections()
    localRouletteTable.interacts = {}
    localRouletteTable.playAreas = {{},{},{},{}}
    for i,v in pairs(LocalRouletteTables[casinoId][entityId].playAreas) do
        local playArea = LocalRouletteTables[casinoId][entityId].playAreas[i]
        local seatOffset = PLAY_AREA_OFFSETS[i].seatOffset
        playArea.surfaceObject = CreateTennisBall(GetOffsetFromEntityInWorldCoords(surfaceObject, seatOffset.coords - vector3(0.0, 0.0, 0.05)), false, false, false)
        FreezeEntityPosition(playArea.surfaceObject, true)
        SetEntityHeading(playArea.surfaceObject, heading + seatOffset.rotation.z)
    end
    LocalRouletteTables[casinoId][entityId].interacts[1] = CreateInteraction({
        label = _L("interact_roulette") .. (casinoEntity.settings.vip and (" " .. _L("casino_vip_game")) or ""),
        coords = GetOffsetFromEntityInWorldCoords(surfaceObject, 0.0, 0.0, 1.0),
        icon = Config.TargetIcons and Config.TargetIcons["roulette"] or nil,
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
            AttemptSeatAtRouletteEntity(casinoId, entityId)
        end, casinoId, entityId)
    end)
    SetTimeout(1000, function()
        local casinoEntity = GetCasinoEntity(casinoId, entityId)
        local positions = GetRouletteConnectPositions()
        RenderRouletteChips(casinoId, entityId)
    end)
end

function UnrenderRouletteEntity(casinoId, entityId)
    if not DoesRouletteEntityExist(casinoId, entityId) then return end
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
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
end

function DeleteRouletteEntity(casinoId, entityId)
    UnrenderRouletteEntity(casinoId, entityId)
    LocalRouletteTables[casinoId][entityId] = nil
end

function RenderRouletteChips(casinoId, entityId)
    local positions = GetRouletteConnectPositions()
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    for i=1, #rouletteTable.connects do
        for j=1, #rouletteTable.connects[i] do
            DeleteScriptObject(rouletteTable.connects[i][j])
        end
    end
    local wagerPositions = {}
    for i=1, #casinoEntity.seats do
        local wagers = ConvertWagersToPositions(casinoEntity.seats[i].connects)
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
        local coords = GetEntityCoords(PlayerPedId())
        for casinoId, entities in pairs(LocalRouletteTables) do
            for entityId, entity in pairs(entities) do
                if not entity.visible and not entity.hidden then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) <= Config.RenderDistance then
                        entity.visible = true
                        RenderRouletteEntity(casinoId, entityId)
                    end
                else
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) > Config.RenderDistance then
                        entity.visible = false
                        UnrenderRouletteEntity(casinoId, entityId)
                    end
                end
            end
        end
        Wait(1500)
    end
end)

RegisterNUICallback("updateRouletteWagers", function(data, cb)
    TriggerServerEvent("pickle_casinos:roulette:updateRouletteWagers", GetRouletteWagersOnly(data.data.connects))
    cb("ok")
end)

RegisterNUICallback("repeatRouletteWager", function(data, cb)
    if not CurrentRouletteTable then return end
    ServerCallback("pickle_casinos:repeatRouletteWager", function(data)
        local connects = ApplyRouletteWagers(data and data.wagers)
        SendNUIMessage({
            type = "updateRouletteWagers",
            data = {
                connects = connects,
                wager = (data and data.wager) or GetRouletteTotalWager(connects),
            },
        })
    end)
    cb("ok")
end)

RegisterNetEvent("pickle_casinos:exitGame", function()
    if not CurrentRouletteTable then return end
    if DoesRouletteEntityExist(CurrentRouletteTable.casinoId, CurrentRouletteTable.entityId) then
        local rouletteTable = LocalRouletteTables[CurrentRouletteTable.casinoId][CurrentRouletteTable.entityId]
        PlayCasinoDealerSpeech(rouletteTable.dealerPed, "MINIGAME_DEALER_LEAVE_NEUTRAL_GAME", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
    end
    local casinoId = CurrentRouletteTable.casinoId
    local entityId = CurrentRouletteTable.entityId
    local seatId = CurrentRouletteTable.seatId
    local playerPed = PlayerPedId()
    PlayRouletteAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_exit_left"}, {time = 4000})
    TriggerServerEvent("pickle_casinos:roulette:leaveTable", casinoId, entityId, seatId)
    ExitCasinoCamera(CurrentCamera)
    CurrentRouletteTable = nil
    CurrentCamera = nil
    Wait(4000)
    ClearPedTasks(playerPed)
end)

RegisterNetEvent("pickle_casinos:roulette:updateHistory", function(casinoId, entityId, history)
    if not DoesRouletteEntityExist(casinoId, entityId) then return end
    if not CurrentRouletteTable then return end
    CurrentRouletteTable.history = history
    SendNUIMessage({
        type = "updateRouletteHistory",
        history = history,
    })
end)

RegisterNetEvent("pickle_casinos:updateBalance", function(balance)
    if not CurrentRouletteTable then return end
    CurrentRouletteTable.balance = balance
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)

RegisterNetEvent("pickle_casinos:roulette:updateSeatWager", function(casinoId, entityId, seatId, wagers)
    if not DoesRouletteEntityExist(casinoId, entityId) then return end
    local connects = ApplyRouletteWagers(wagers)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if casinoEntity and casinoEntity.seats and casinoEntity.seats[seatId] then
        casinoEntity.seats[seatId].connects = connects
    end
    if CurrentRouletteTable and CurrentRouletteTable.casinoId == casinoId and CurrentRouletteTable.entityId == entityId then
        CurrentRouletteTable.seats[seatId].connects = connects
        SendNUIMessage({
            type = "updateRouletteSeats",
            seats = GetRouletteSeatsForUI(),
        })
        if seatId == CurrentRouletteTable.seatId then
            SendNUIMessage({
                type = "updateRouletteWagers",
                data = {
                    connects = connects,
                    wager = GetRouletteTotalWager(connects),
                },
            })
        end
    end
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    if not rouletteTable or not rouletteTable.visible then return end
    local playArea = rouletteTable.playAreas[seatId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local heading = casinoEntity.settings.location.rotation.z
    local chipOffset = PLAY_AREA_OFFSETS[seatId].chips
    RenderRouletteChips(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:roulette:updateSeat", function(casinoId, entityId, seatId, seatData)
    if not DoesRouletteEntityExist(casinoId, entityId) then return end
    if seatData then
        seatData.connects = ApplyRouletteWagers(seatData.wagers)
        seatData.wagers = nil
    end
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if casinoEntity and casinoEntity.seats then
        casinoEntity.seats[seatId] = seatData
    end
    if CurrentRouletteTable and CurrentRouletteTable.casinoId == casinoId and CurrentRouletteTable.entityId == entityId then
        SendNUIMessage({
            type = "updateRouletteSeats",
            seats = GetRouletteSeatsForUI(),
        })
        CurrentRouletteTable.seats[seatId] = seatData
    end
    if not rouletteTable or not rouletteTable.visible then return end
    RenderRouletteChips(casinoId, entityId)
    -- TriggerEvent("pickle_casinos:roulette:updateSeatWager", casinoId, entityId, seatId, 1, seatData.wagers)
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    if not LocalRouletteTables[casinoId] then return end
    if not LocalRouletteTables[casinoId][entityId] then return end
    DeleteRouletteEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:setCasinoEntityHidden", function(casinoId, entityId, toggle)
    if not LocalRouletteTables[casinoId] then return end
    if not LocalRouletteTables[casinoId][entityId] then return end
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    rouletteTable.hidden = toggle
    if toggle then
        rouletteTable.visible = false
        UnrenderRouletteEntity(casinoId, entityId)
    else
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - rouletteTable.coords) <= Config.RenderDistance then
            rouletteTable.visible = true
            RenderRouletteEntity(casinoId, entityId)
        end
    end
end)

RegisterNetEvent("pickle_casinos:refreshCasinoEntity", function(casinoId, entityId)
    if not LocalRouletteTables[casinoId] then return end
    if not LocalRouletteTables[casinoId][entityId] then return end
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    rouletteTable.coords = casinoEntity.settings.location.coords
    rouletteTable.heading = casinoEntity.settings.location.rotation.z
    if not rouletteTable.visible then return end
    UnrenderRouletteEntity(casinoId, entityId)
    Wait(100)
    RenderRouletteEntity(casinoId, entityId)
end)

function EnsureRouletteCamera()
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

RegisterNetEvent("pickle_casinos:roulette:performAction", function(casinoId, entityId, action)
    if not DoesRouletteEntityExist(casinoId, entityId) then return end
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    if not rouletteTable or not rouletteTable.visible then return end
    local isCurrentTable = (CurrentRouletteTable and CurrentRouletteTable.casinoId == casinoId and CurrentRouletteTable.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local dealerPed = rouletteTable.dealerPed
    if not rouletteTable.lastDealerRotation then
        rouletteTable.lastDealerRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
    end
    local targetRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
    if (action.handId and action.handId == 2) then
        targetRotation = targetRotation + vector3(0.0, 0.0, 10.0)
    end
    SetEntitySmoothRotation(dealerPed, rouletteTable.lastDealerRotation, targetRotation) 
    rouletteTable.lastDealerRotation = targetRotation
    if (action.type == "split") then
        PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@roulette@dealer", "split_card_player_0" .. action.seat, 3.0, 1.0, -1, 2, 0, 0, 0, 0 )
        Wait(800)
        for i=1, #action.hands do
            TriggerEvent("pickle_casinos:roulette:updateSeatCards", casinoId, entityId, action.seat, i, action.hands[i])
        end
    end
end)

RegisterNetEvent("pickle_casinos:roulette:updateResults", function(casinoId, entityId, seatResults)
    if CurrentRouletteTable and CurrentRouletteTable.casinoId == casinoId and CurrentRouletteTable.entityId == entityId then
        SendNUIMessage({
            type = "updateRouletteStage",
            stage = {
                type = "results",
                seatResults = seatResults,
            }
        })
    end
end)

RegisterNetEvent("pickle_casinos:roulette:updateStage", function(casinoId, entityId, stage)
    if not DoesRouletteEntityExist(casinoId, entityId) then return end
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    if not rouletteTable or not rouletteTable.visible then return end
    local isCurrentTable = (CurrentRouletteTable and CurrentRouletteTable.casinoId == casinoId and CurrentRouletteTable.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local dealerPed = rouletteTable.dealerPed
    if stage.type == "waiting" then
        PlayCasinoDealerSpeech(rouletteTable.dealerPed, "MINIGAME_DEALER_PLACE_BET", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
        if isCurrentTable then
            EnsureRouletteCamera()
            local tableCoords = GetOffsetFromEntityInWorldCoords(rouletteTable.surfaceObject, 0.0, -0.5, 3.0)
            SetCamParams(CurrentCamera, tableCoords.x, tableCoords.y, tableCoords.z,
                -90.0, 0.0, rouletteTable.heading, 80.0, 
                2000, 0, 0, 2
            )
            CreateThread(function()
                while stage.time > 1 do
                    stage.time = stage.time - 1
                    SendNUIMessage({
                        type = "updateRouletteStage",
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
        PlayCasinoDealerSpeech(rouletteTable.dealerPed, "MINIGAME_DEALER_CLOSED_BETS", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
        if isCurrentTable then
            SendNUIMessage({
                type = "updateRouletteStage",
                stage = {
                    type = "rolling",
                }
            })
        end
        PerformRouletteSpin(casinoId, entityId, stage.targetNumber)
    elseif stage.type == "winningNumber" then
        PlayCasinoDealerSpeech(rouletteTable.dealerPed, ("MINIGAME_ROULETTE_BALL_" .. stage.winningNumber), "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
        if isCurrentTable then
            SendNUIMessage({
                type = "updateRouletteStage",
                stage = {
                    type = "winningNumber",
                    winningNumber = stage.winningNumber,
                }
            })
            if stage.seats and stage.seats[CurrentRouletteTable.seatId] then
                local seatResult = stage.seats[CurrentRouletteTable.seatId]
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
        for k,v in pairs(LocalRouletteTables) do
            for id, _ in pairs(v) do
                DeleteRouletteEntity(k, id)
            end
        end
    end
end)