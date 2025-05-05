local BaccaratTables = {}
local LocalBaccaratTables = {}
local PLAY_AREA_OFFSETS = {
    [0] = {
        cards = {
            coords = vector3(0.06, 0.22, 0.0),
            rotation = vector3(0.0, 0.0, 0.0),
        },
        chips = {
            coords = vector3(0.58, 0.24, 0.0),
            rotation = vector3(0.0, 0.0, 67.0),
        },
    },
    [1] = {
        cards = {
            coords = vector3(0.58, 0.24, 0.0),
            rotation = vector3(0.0, 0.0, 67.0),
        },
        chips = {
            coords = vector3(0.58, 0.24, 0.0),
            rotation = vector3(0.0, 0.0, 67.0),
        },
    },
    [2] = {
        cards = {
            coords = vector3(0.235, -0.11, 0.0),
            rotation = vector3(0.0, 0.0, 21.0),
        },
        chips = {
            coords = vector3(0.235, -0.11, 0.0),
            rotation = vector3(0.0, 0.0, 21.0),
        },
    },
    [3] = {
        cards = {
            coords = vector3(-0.235, -0.11, 0.0),
            rotation = vector3(0.0, 0.0, -21.0),
        },
        chips = {
            coords = vector3(-0.235, -0.11, 0.0),
            rotation = vector3(0.0, 0.0, -21.0),
        },
    },
    [4] = {
        cards = {
            coords = vector3(-0.5775, 0.2225, 0.0),
            rotation = vector3(0.0, 0.0, -67.0),
        },
        chips = {
            coords = vector3(-0.5775, 0.2225, 0.0),
            rotation = vector3(0.0, 0.0, -67.0),
        },
    },
}
local CurrentBaccaratTable = nil
local playingBaccaratAnimation = false
local CurrentCamera = nil

function EnsureBaccaratCamera()
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

function DoesBaccaratEntityExist(casinoId, entityId)
    return LocalBaccaratTables[casinoId] and LocalBaccaratTables[casinoId][entityId]
end

function GetBaccaratSeatsForUI(currentHand)
    local seats = {}
    for i=1, 4 do
        local seat = CurrentBaccaratTable.seats[i]
        local wager = 0
        for k,v in pairs(seat.wagers) do
            wager = wager + v
        end
        table.insert(seats, {
            source = seat.source,
            name = seat.name or "Unknown",
            wager = wager,
            wagers = seat.wagers,
        })
    end
    return seats
end

function PlayBaccaratAnimation(ped, animation, data)
    playingBaccaratAnimation = true
    SetTimeout((data and data.time) or 1000, function()
        playingBaccaratAnimation = false
    end)
    local playArea = LocalBaccaratTables[CurrentBaccaratTable.casinoId][CurrentBaccaratTable.entityId].playAreas[CurrentBaccaratTable.seatId]
    local coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.5, 0.05)
    local rotation = GetEntityRotation(playArea.surfaceObject) + vector3(0.0, 0.0, 90.0)
    local netScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, rotation.x, rotation.y, rotation.z, 2, 1, 0, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(ped, netScene, animation.dict, animation.name, 2.0, -2.0, 13, 16, 2.0, 0) -- 8.0, -1.5, 157, 16, 1148846080, 0) ?
    NetworkStartSynchronisedScene(netScene)
end

function AttemptSeatAtBaccaratEntity(casinoId, entityId)
    local ped = PlayerPedId()
    local baccaratTable = LocalBaccaratTables[casinoId][entityId]
    local closest = {seatId = -1, distance = 100.0}
    for i,playArea in pairs(baccaratTable.playAreas) do
        local coords = GetEntityCoords(playArea.surfaceObject)
        local distance = #(GetEntityCoords(ped) - coords)
        if distance < closest.distance then
            closest = {seatId = i, distance = distance}
        end
    end
    ServerCallback("pickle_casinos:baccarat:requestSeat", function(seatId, entityInfo)
        debugPrint(json.encode(entityInfo.seats, {indent = true}))
        if not seatId then 
            return 
        end
        CurrentBaccaratTable = {
            casinoId = casinoId,
            entityId = entityId,
            seatId = seatId,
            seats = entityInfo.seats,
            stage = entityInfo.stage,
            wagers = entityInfo.wagers,
            money = entityInfo.money,
            sides = {player = {}, banker = {}},
            betRange = entityInfo.betRange,
        }
        EnsureBaccaratCamera()
        local tableCoords = GetOffsetFromEntityInWorldCoords(baccaratTable.surfaceObject, 0.0, -1.0, 2.25)
        SetCamParams(CurrentCamera, tableCoords.x, tableCoords.y, tableCoords.z,
            -60.0, 0.0, baccaratTable.heading, 90.0, 
            2000, 0, 0, 2
        )
        local casinoId = CurrentBaccaratTable.casinoId
        local entityId = CurrentBaccaratTable.entityId
        local seatId = CurrentBaccaratTable.seatId
        local stage = CurrentBaccaratTable.stage or {type = "waiting", time = GetWaitingTime("baccarat")}
        if Config.ToggleGameMode then
            Config.ToggleGameMode(true)
        end
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "setCurrentGame",
            game = {
                type = "baccarat",
                data = {
                    seatId = seatId,
                    seats = GetBaccaratSeatsForUI(),
                    money = CurrentBaccaratTable.money,
                    wagerLimit = CurrentBaccaratTable.betRange,
                    stage = stage,
                }
            }
        })
        if (stage.type == "waiting") then
            TriggerEvent("pickle_casinos:baccarat:updateStage", casinoId, entityId, stage)
        end
        local playerPed = PlayerPedId()
        local playArea = baccaratTable.playAreas[seatId]
        PlayBaccaratAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_enter_left"}, {time = 6000})
        CreateThread(function()
            while CurrentBaccaratTable do
                if CurrentBaccaratTable.waitingTime > 1 and CurrentBaccaratTable.stage.type == "waiting" then
                    CurrentBaccaratTable.waitingTime = CurrentBaccaratTable.waitingTime - 1
                    SendNUIMessage({
                        type = "updateBaccaratStage",
                        stage = {
                            type = "waiting",
                            time = CurrentBaccaratTable.waitingTime
                        }
                    })
                end
                Wait(1000)
            end
        end)
        Wait(6000)
        local coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.5, 0.05)
        local rotation = GetEntityRotation(playArea.surfaceObject) + vector3(0.0, 0.0, 90.0)
        CreateThread(function()
            while CurrentBaccaratTable do
                if not playingBaccaratAnimation and not IsEntityPlayingAnim(playerPed, "anim_casino_b@amb@casino@games@shared@player@", "idle_cardgames", 3) then
                    local netScene = NetworkCreateSynchronisedScene(coords, rotation, 2, 0, 1, 1065353216, 0, 1065353216)
                    NetworkAddPedToSynchronisedScene(playerPed, netScene, "anim_casino_b@amb@casino@games@shared@player@", "idle_cardgames", 2.0, -2.0, 13, 16, 2.0, 0)
                    NetworkStartSynchronisedScene(netScene)
                    Wait(100)
                end
                DisableIdleCamera(true)
                Wait(0)
            end
        end)
    end, casinoId, entityId, closest.seatId)
end

function CreateBaccaratEntity(casinoId, entityId)
    if DoesBaccaratEntityExist(casinoId, entityId) then return end
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    -- local tempCard = CreateProp(`vw_prop_cas_card_club_04`, GetOffsetFromEntityInWorldCoords(surfaceObject, 0.0, 0.0, 0.0), false, false, false)
    -- FreezeEntityPosition(tempCard, true)
    -- SetEntityHeading(tempCard, heading)
    
    if not LocalBaccaratTables[casinoId] then LocalBaccaratTables[casinoId] = {} end
    LocalBaccaratTables[casinoId][entityId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - coords) < Config.RenderDistance,
        coords = coords,
        heading = heading,
    }
    RenderBaccaratEntity(casinoId, entityId)
    -- AttemptSeatAtBaccaratEntity(casinoId, entityId)
end

function RenderBaccaratEntity(casinoId, entityId)
    local localBaccaratTable = LocalBaccaratTables[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casinoEntity or not localBaccaratTable.visible then return end
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
    localBaccaratTable.dealerPed = dealerPed
    localBaccaratTable.tableObject = tableObject
    localBaccaratTable.surfaceObject = surfaceObject
    localBaccaratTable.interacts = {}
    localBaccaratTable.playAreas = {
        [0] = {
            sides = {player = {}, banker = {}},
            wagers = {player = {}, banker = {}, tie = {}},
        },
        {
            sides = {player = {}, banker = {}},
            wagers = {player = {}, banker = {}, tie = {}},
        },
        {
            sides = {player = {}, banker = {}},
            wagers = {player = {}, banker = {}, tie = {}},
        },
        {
            sides = {player = {}, banker = {}},
            wagers = {player = {}, banker = {}, tie = {}},
        },
        {
            sides = {player = {}, banker = {}},
            wagers = {player = {}, banker = {}, tie = {}},
        },
    }
    for i,v in pairs(LocalBaccaratTables[casinoId][entityId].playAreas) do
        local playArea = LocalBaccaratTables[casinoId][entityId].playAreas[i]
        local cardOffset = PLAY_AREA_OFFSETS[i].cards
        playArea.surfaceObject = CreateTennisBall(GetOffsetFromEntityInWorldCoords(surfaceObject, cardOffset.coords - vector3(0.0, 0.0, 0.05)), false, false, false)
        FreezeEntityPosition(playArea.surfaceObject, true)
        SetEntityHeading(playArea.surfaceObject, heading + cardOffset.rotation.z)
    end
    for i,playArea in pairs(LocalBaccaratTables[casinoId][entityId].playAreas) do
        if i > 0 then
            LocalBaccaratTables[casinoId][entityId].interacts[#LocalBaccaratTables[casinoId][entityId].interacts + 1] = CreateInteraction({
                label = _L("interact_baccarat") .. (casinoEntity.settings.vip and (" " .. _L("casino_vip_game")) or ""),
                icon = Config.TargetIcons and Config.TargetIcons["baccarat"] or nil,
                coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.8, 1.0),
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
                    AttemptSeatAtBaccaratEntity(casinoId, entityId)
                end, casinoId, entityId)
            end)
        end
    end
end

function UnrenderBaccaratEntity(casinoId, entityId)
    if not DoesBaccaratEntityExist(casinoId, entityId) then return end
    local baccaratTable = LocalBaccaratTables[casinoId][entityId]
    if not baccaratTable then return end
    if baccaratTable.interacts then
        for i=1, #baccaratTable.interacts do
            DeleteInteraction(baccaratTable.interacts[i])
        end
    end
    if baccaratTable.dealerPed then
        DeleteScriptObject(baccaratTable.dealerPed)
    end
    if baccaratTable.tableObject then
        DeleteScriptObject(baccaratTable.tableObject)
    end
    if baccaratTable.surfaceObject then
        DeleteScriptObject(baccaratTable.surfaceObject)
    end
    if baccaratTable.playAreas then
        for i, v in pairs(baccaratTable.playAreas) do  
            local playArea = baccaratTable.playAreas[i]
            for a, b in pairs(playArea.sides) do
                for j=1, #b do
                    DeleteScriptObject(b[j])
                end
            end
            for a, b in pairs(playArea.wagers) do
                for j=1, #b do
                    DeleteScriptObject(b[j])
                end
            end
            DeleteScriptObject(playArea.surfaceObject)
        end
    end
    baccaratTable.interacts = nil
    baccaratTable.dealerPed = nil
    baccaratTable.tableObject = nil
    baccaratTable.surfaceObject = nil
    baccaratTable.playAreas = nil
end

function DeleteBaccaratEntity(casinoId, entityId)
    UnrenderBaccaratEntity(casinoId, entityId)
    LocalBaccaratTables[casinoId][entityId] = nil
end

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    if not LocalBaccaratTables[casinoId] then return end
    if not LocalBaccaratTables[casinoId][entityId] then return end
    DeleteBaccaratEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:setCasinoEntityHidden", function(casinoId, entityId, toggle)
    if not LocalBaccaratTables[casinoId] then return end
    if not LocalBaccaratTables[casinoId][entityId] then return end
    local baccaratTable = LocalBaccaratTables[casinoId][entityId]
    baccaratTable.hidden = toggle
    if toggle then
        baccaratTable.visible = false
        UnrenderBaccaratEntity(casinoId, entityId)
    else
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - baccaratTable.coords) <= Config.RenderDistance then
            baccaratTable.visible = true
            RenderBaccaratEntity(casinoId, entityId)
        end
    end
end)

RegisterNetEvent("pickle_casinos:refreshCasinoEntity", function(casinoId, entityId)
    if not LocalBaccaratTables[casinoId] then return end
    if not LocalBaccaratTables[casinoId][entityId] then return end
    local baccaratTable = LocalBaccaratTables[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    baccaratTable.coords = casinoEntity.settings.location.coords
    baccaratTable.heading = casinoEntity.settings.location.rotation.z
    if not baccaratTable.visible then return end
    UnrenderBaccaratEntity(casinoId, entityId)
    Wait(100)
    RenderBaccaratEntity(casinoId, entityId)
end)

CreateThread(function()
    while true do 
        local coords = GetEntityCoords(PlayerPedId())
        for casinoId, entities in pairs(LocalBaccaratTables) do
            for entityId, entity in pairs(entities) do
                if not entity.visible and not entity.hidden then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) <= Config.RenderDistance then
                        entity.visible = true
                        RenderBaccaratEntity(casinoId, entityId)
                    end
                elseif entity.visible then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) > Config.RenderDistance then
                        entity.visible = false
                        UnrenderBaccaratEntity(casinoId, entityId)
                    end
                end
            end
        end
        Wait(1500)
    end
end)

RegisterNUICallback("performBaccaratAction", function(data, cb)
    local animations = {
        ["hit"] = { dict = "anim_casino_b@amb@casino@games@baccarat@player", name = "request_card" },
        ["stand"] = { dict = "anim_casino_b@amb@casino@games@baccarat@player", name = "decline_card_001" },
        ["double"] = { dict = "anim_casino_b@amb@casino@games@baccarat@player", name = "place_bet_small" },
        ["split"] = { dict = "anim_casino_b@amb@casino@games@baccarat@player", name = "place_bet_small" },
    }
    TriggerServerEvent("pickle_casinos:baccarat:performAction", data.action)
    PlayBaccaratAnimation(PlayerPedId(), {dict = animations[data.action].dict, name = animations[data.action].name}, {time = 1000})
    cb("ok")
end)

RegisterNUICallback("setBaccaratWager", function(data, cb)
    TriggerServerEvent("pickle_casinos:baccarat:setWager", data.wager)
    cb("ok")
end)

RegisterNUICallback("repeatBaccaratWager", function(data, cb)
    TriggerServerEvent("pickle_casinos:baccarat:repeatWager")
    cb("ok")
end)

RegisterNetEvent("pickle_casinos:exitGame", function()
    if not CurrentBaccaratTable then return end
    if DoesBaccaratEntityExist(CurrentBaccaratTable.casinoId, CurrentBaccaratTable.entityId) then
        local baccaratTable = LocalBaccaratTables[CurrentBaccaratTable.casinoId][CurrentBaccaratTable.entityId]
        PlayCasinoDealerSpeech(baccaratTable.dealerPed, "MINIGAME_DEALER_LEAVE_NEUTRAL_GAME", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
    end
    local casinoId = CurrentBaccaratTable.casinoId
    local entityId = CurrentBaccaratTable.entityId
    local seatId = CurrentBaccaratTable.seatId
    local playerPed = PlayerPedId()
    PlayBaccaratAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_exit_left"}, {time = 4000})
    TriggerServerEvent("pickle_casinos:baccarat:leaveTable", casinoId, entityId, seatId)
    ExitCasinoCamera(CurrentCamera)
    CurrentBaccaratTable = nil
    CurrentCamera = nil
    Wait(4000)
    ClearPedTasks(playerPed)
end)

RegisterNetEvent("pickle_casinos:updateBalance", function(balance)
    if not CurrentBaccaratTable then return end
    CurrentBaccaratTable.money = balance
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)

RegisterNetEvent("pickle_casinos:baccarat:updateSeatWager", function(casinoId, entityId, seatId, wagers)
    if not DoesBaccaratEntityExist(casinoId, entityId) then return end
    if CurrentBaccaratTable and CurrentBaccaratTable.casinoId == casinoId and CurrentBaccaratTable.entityId == entityId then
        CurrentBaccaratTable.seats[seatId].wagers = wagers
        SendNUIMessage({
            type = "updateBaccaratSeats",
            seats = GetBaccaratSeatsForUI(),
        })
    end
    local baccaratTable = LocalBaccaratTables[casinoId][entityId]
    if not baccaratTable or not baccaratTable.visible then return end
    local playArea = baccaratTable.playAreas[seatId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local heading = casinoEntity.settings.location.rotation.z
    local chipOffset = PLAY_AREA_OFFSETS[seatId].chips
    for a, b in pairs(playArea.wagers) do
        for j=1, #b do
            DeleteScriptObject(b[j])
        end
        playArea.wagers[a] = {}
    end
    local sideWagers = {player = wagers.player, banker = wagers.banker, tie = wagers.tie}
    local offsets = {player = 0.05, banker = -0.05, tie = 0.0}
    for k,v in pairs(sideWagers) do 
        local chips = GetCalculatedChips(v)
        for i=1, #chips do
            local chip = chips[i]
            local chipObject = CreateProp(chip.model, GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, vector3(0.0, -0.13 + offsets[k], 1 + (i - 1) * 0.0065)), false, false, false)
            FreezeEntityPosition(chipObject, true)
            SetEntityRotation(chipObject, 0.0, 0.0, heading + chipOffset.rotation.z, 2, true)
            table.insert(playArea.wagers[k], chipObject)
        end
    end

end)

RegisterNetEvent("pickle_casinos:baccarat:updateCards", function(casinoId, entityId, side, cards)
    if not DoesBaccaratEntityExist(casinoId, entityId) then return end
    if CurrentBaccaratTable and CurrentBaccaratTable.casinoId == casinoId and CurrentBaccaratTable.entityId == entityId then
        CurrentBaccaratTable.sides[side] = cards
        SendNUIMessage({
            type = "updateBaccaratCards",
            cards = CurrentBaccaratTable.sides,
        })
    end
    local baccaratTable = LocalBaccaratTables[casinoId][entityId]
    if not baccaratTable or not baccaratTable.visible then return end
    local playArea = baccaratTable.playAreas[0]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    for i=1, #playArea.sides[side] do
        DeleteScriptObject(playArea.sides[side][i])
    end
    playArea.sides[side] = {}
    local heading = casinoEntity.settings.location.rotation.z
    local cardOffset = PLAY_AREA_OFFSETS[0].cards
    if #cards > 0 then
        local value = GetBaccaratCardsValue(cards)
        PlayCasinoDealerSpeech(baccaratTable.dealerPed, (value <= 1 and ("MINIGAME_ROULETTE_BALL_" .. value) or ("MINIGAME_BJACK_DEALER_" .. value)), "SPEECH_PARAMS_FORCE_NORMAL_CLEAR", 1)
    end
    for i=1, #cards do
        local card = cards[i]
        local factor = (side == "player" and 1 or -1)
        local offset = vector3(((i * -0.07) * factor) - 0.06, 0.0, (i <= 2 and 0 or 0.001) * (i - 1))
        local cardProp = CreateProp(GetCardModel(card.class, card.value), GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, offset ), false, false, false)
        FreezeEntityPosition(cardProp, true)
        SetEntityRotation(cardProp, 0.0, (card.class == "hidden") and 180.0 or 0.0, heading + cardOffset.rotation.z, 2, true)
        table.insert(playArea.sides[side], cardProp)
    end
end)

RegisterNetEvent("pickle_casinos:baccarat:updateSeat", function(casinoId, entityId, seatId, seatData)
    if not DoesBaccaratEntityExist(casinoId, entityId) then return end
    if CurrentBaccaratTable and CurrentBaccaratTable.casinoId == casinoId and CurrentBaccaratTable.entityId == entityId then
        CurrentBaccaratTable.seats[seatId] = seatData
        SendNUIMessage({
            type = "updateBaccaratSeats",
            seats = GetBaccaratSeatsForUI(),
        })
    end
end)

RegisterNetEvent("pickle_casinos:baccarat:performAction", function(casinoId, entityId, action)
    if not DoesBaccaratEntityExist(casinoId, entityId) then return end
    local baccaratTable = LocalBaccaratTables[casinoId][entityId]
    if not baccaratTable or not baccaratTable.visible then return end
    local isCurrentTable = (CurrentBaccaratTable and CurrentBaccaratTable.casinoId == casinoId and CurrentBaccaratTable.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local dealerPed = baccaratTable.dealerPed
    if not baccaratTable.lastDealerRotation then
        baccaratTable.lastDealerRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
    end
    local targetRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
    if (action.handId and action.handId == 2) then
        targetRotation = targetRotation + vector3(0.0, 0.0, 10.0)
    end
    SetEntitySmoothRotation(dealerPed, baccaratTable.lastDealerRotation, targetRotation) 
    baccaratTable.lastDealerRotation = targetRotation
    if (action.type == "split") then
        PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@baccarat@dealer", "split_card_player_0" .. action.seat, 3.0, 1.0, -1, 2, 0, 0, 0, 0 )
        Wait(800)
        for i=1, #action.hands do
            TriggerEvent("pickle_casinos:baccarat:updateSeatCards", casinoId, entityId, action.seat, i, action.hands[i])
        end
    end
end)

RegisterNetEvent("pickle_casinos:baccarat:updateResults", function(casinoId, entityId, results, seatResults)
    if not DoesBaccaratEntityExist(casinoId, entityId) then return end
    local baccaratTable = LocalBaccaratTables[casinoId][entityId]
    if not baccaratTable or not baccaratTable.visible then return end
    if not results.winningWagers.tie then
        local speech = (results.winningWagers.banker and "MINIGAME_BJACK_DEALER_PLAYER_BUST" or "MINIGAME_DEALER_BUSTS")
        PlayCasinoDealerSpeech(baccaratTable.dealerPed, speech, "SPEECH_PARAMS_FORCE_NORMAL_CLEAR", 1)
    end
    if CurrentBaccaratTable and CurrentBaccaratTable.casinoId == casinoId and CurrentBaccaratTable.entityId == entityId then
        SendNUIMessage({
            type = "updateBaccaratStage",
            stage = {
                type = "results",
                winningWagers = results.winningWagers,
            }
        })
        local won = seatResults[CurrentBaccaratTable.seatId].won
        if won > 0 then
            SendNUIMessage({
                type = "displayResults",
                results = {winnings = won},
            })
        end
    end
end)

RegisterNetEvent("pickle_casinos:baccarat:updateStage", function(casinoId, entityId, stage)
    if not DoesBaccaratEntityExist(casinoId, entityId) then return end
    local baccaratTable = LocalBaccaratTables[casinoId][entityId]
    if not baccaratTable or not baccaratTable.visible then return end
    local isCurrentTable = (CurrentBaccaratTable and CurrentBaccaratTable.casinoId == casinoId and CurrentBaccaratTable.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local dealerPed = baccaratTable.dealerPed
    if not baccaratTable.lastDealerRotation then
        baccaratTable.lastDealerRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
    end
    local targetRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
    if (stage.side) then
        local targetHeading = 0
        if (stage.side == "player") then
            targetHeading = -8.0 + (-8.0 * (stage.cardIndex - 1 / 2))
        else
            targetHeading = 0.0 + (6.0 * (stage.cardIndex - 1 / 2))
        end
        targetRotation = targetRotation + vector3(0.0, 0.0, targetHeading)
    end
    if (isCurrentTable) then
        CurrentBaccaratTable.stage = stage
    end
    SetEntitySmoothRotation(dealerPed, baccaratTable.lastDealerRotation, targetRotation) 
    baccaratTable.lastDealerRotation = targetRotation
    if stage.type == "waiting" then
        PlayCasinoDealerSpeech(baccaratTable.dealerPed, "MINIGAME_DEALER_PLACE_BET", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
        if isCurrentTable then
            CurrentBaccaratTable.waitingTime = stage.time
        end
    elseif stage.type == "dealing" then
        if isCurrentTable then
            SendNUIMessage({
                type = "updateBaccaratStage",
                stage = {
                    type = "dealing",
                    seat = stage.seat,
                    handId = stage.handId,
                    card = stage.card,
                }
            })
        end
        if stage.isFirstCard then
            PlayCasinoDealerSpeech(baccaratTable.dealerPed, "MINIGAME_DEALER_CLOSED_BETS", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
            Wait(3000)
        end
        local animation = {
            dict = "anim_casino_b@amb@casino@games@blackjack@dealer",
            name = "deal_card_self",
            wait = 750,
        }
        PlayAnim(dealerPed, animation.dict, animation.name, 3.0, 1.0, -1, 2, 0, 0, 0, 0 )
        SetTimeout(600, function()
            local cardModel = GetCardModel(stage.card.class, stage.card.value)
            local card = CreateProp(cardModel, GetOffsetFromEntityInWorldCoords(baccaratTable.surfaceObject, 0.0, 0.0, 0.1), false, false, false)
            AttachEntityToEntity(card, dealerPed, GetPedBoneIndex(dealerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            Wait(animation.wait or 0)
            DeleteScriptObject(card)
        end)
    elseif stage.type == "cleanup" then
        local dealerPed = baccaratTable.dealerPed
        PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "retrieve_own_cards_and_remove", 3.0, 1.0, -1, 2, 0, 0, 0, 0)
        Wait(400)
        for k,v in pairs(baccaratTable.playAreas[0].sides) do   
            for i=1, #v do
                DeleteScriptObject(v[i])
            end
        end
        baccaratTable.playAreas[0].sides = {player = {}, banker = {}}
        if isCurrentTable then
            CurrentBaccaratTable.sides = {player = {}, banker = {}}
            SendNUIMessage({
                type = "updateBaccaratSeats",
                seats = GetBaccaratSeatsForUI(),
            })
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k,v in pairs(LocalBaccaratTables) do
            for id, _ in pairs(v) do
                DeleteBaccaratEntity(k, id)
            end
        end
    end
end)