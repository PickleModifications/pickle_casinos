local BlackjackTables = {}
local LocalBlackjackTables = {}
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
local CurrentBlackjackTable = nil
local playingBlackjackAnimation = false
local CurrentCamera = nil

function EnsureBlackjackCamera()
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

function DoesBlackjackEntityExist(casinoId, entityId)
    return LocalBlackjackTables[casinoId] and LocalBlackjackTables[casinoId][entityId]
end

function IsBlackjackEntityVisible(casinoId, entityId)
    return DoesBlackjackEntityExist(casinoId, entityId) and LocalBlackjackTables[casinoId][entityId].visible
end

function GetBlackjackSeatsForUI(currentHand)
    local seats = {}
    for i=0, 4 do
        local seat = CurrentBlackjackTable.seats[i]
        local wager = 0
        if (seat.wagers and seat.wagers[1]) then
            wager = seat.wagers[1] + (seat.wagers[2] or 0)
        end
        table.insert(seats, {
            source = seat.source,
            name = seat.name or "Unknown",
            currentHand = (currentHand or 1) - 1,
            hands = seat.hands,
            wager = wager,
        })
    end
    return seats
end

function PlayBlackjackAnimation(ped, animation, data)
    playingBlackjackAnimation = true
    SetTimeout((data and data.time) or 1000, function()
        playingBlackjackAnimation = false
    end)
    local playArea = LocalBlackjackTables[CurrentBlackjackTable.casinoId][CurrentBlackjackTable.entityId].playAreas[CurrentBlackjackTable.seatId]
    local coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.5, 0.05)
    local rotation = GetEntityRotation(playArea.surfaceObject) + vector3(0.0, 0.0, 90.0)
    local netScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, rotation.x, rotation.y, rotation.z, 2, 1, 0, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(ped, netScene, animation.dict, animation.name, 2.0, -2.0, 13, 16, 2.0, 0) -- 8.0, -1.5, 157, 16, 1148846080, 0) ?
    NetworkStartSynchronisedScene(netScene)
end

function AttemptSeatAtBlackjackEntity(casinoId, entityId)
    local ped = PlayerPedId()
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    local closest = {seatId = -1, distance = 100.0}
    for i,playArea in pairs(blackjackTable.playAreas) do
        local coords = GetEntityCoords(playArea.surfaceObject)
        local distance = #(GetEntityCoords(ped) - coords)
        if distance < closest.distance then
            closest = {seatId = i, distance = distance}
        end
    end
    ServerCallback("pickle_casinos:blackjack:requestSeat", function(seatId, entityInfo)
        if not seatId then 
            return 
        end
        CurrentBlackjackTable = {
            casinoId = casinoId,
            entityId = entityId,
            seatId = seatId,
            seats = entityInfo.seats,
            stage = entityInfo.stage,
            wagers = entityInfo.wagers,
            money = entityInfo.money,
            betRange = entityInfo.betRange,
        }
        EnsureBlackjackCamera()
        local tableCoords = GetOffsetFromEntityInWorldCoords(blackjackTable.surfaceObject, 0.0, -1.0, 2.25)
        SetCamParams(CurrentCamera, tableCoords.x, tableCoords.y, tableCoords.z,
            -60.0, 0.0, blackjackTable.heading, 90.0, 
            2000, 0, 0, 2
        )
        local casinoId = CurrentBlackjackTable.casinoId
        local entityId = CurrentBlackjackTable.entityId
        local seatId = CurrentBlackjackTable.seatId
        local stage = CurrentBlackjackTable.stage or {type = "waiting", time = 10}
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "setCurrentGame",
            game = {
                type = "blackjack",
                data = {
                    seatId = seatId,
                    seats = GetBlackjackSeatsForUI(),
                    money = CurrentBlackjackTable.money,
                    wagerLimit = CurrentBlackjackTable.betRange,
                    stage = stage,
                }
            }
        })
        if (stage.type == "waiting") then
            TriggerEvent("pickle_casinos:blackjack:updateStage", casinoId, entityId, stage)
        end
        local playerPed = PlayerPedId()
        local playArea = blackjackTable.playAreas[seatId]
        PlayCasinoDealerSpeech(blackjackTable.dealerPed, "MINIGAME_DEALER_GREET", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
        PlayBlackjackAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_enter_left"}, {time = 6000})
        Wait(6000)
        local coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.5, 0.05)
        local rotation = GetEntityRotation(playArea.surfaceObject) + vector3(0.0, 0.0, 90.0)
        CreateThread(function()
            while CurrentBlackjackTable do
                if not playingBlackjackAnimation and not IsEntityPlayingAnim(playerPed, "anim_casino_b@amb@casino@games@shared@player@", "idle_cardgames", 3) then
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

function CreateBlackjackEntity(casinoId, entityId)
    if DoesBlackjackEntityExist(casinoId, entityId) then return end
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    if not LocalBlackjackTables[casinoId] then LocalBlackjackTables[casinoId] = {} end
    LocalBlackjackTables[casinoId][entityId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - coords) < Config.RenderDistance,
        coords = coords,
        heading = heading,
    }
    RenderBlackjackEntity(casinoId, entityId)
end

function RenderBlackjackEntity(casinoId, entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casinoEntity or not IsBlackjackEntityVisible(casinoId, entityId) then return end
    local localBlackjackTable = LocalBlackjackTables[casinoId][entityId]
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
    localBlackjackTable.dealerPed = dealerPed
    localBlackjackTable.tableObject = tableObject
    localBlackjackTable.surfaceObject = surfaceObject
    localBlackjackTable.interacts = {}
    localBlackjackTable.playAreas = {
        [0] = {
            hands = {{}, {}},
            wagers = {{}, {}},
        },
        {
            hands = {{}, {}},
            wagers = {{}, {}},
        },
        {
            hands = {{}, {}},
            wagers = {{}, {}},
        },
        {
            hands = {{}, {}},
            wagers = {{}, {}},
        },
        {
            hands = {{}, {}},
            wagers = {{}, {}},
        },
    }
    for i,v in pairs(LocalBlackjackTables[casinoId][entityId].playAreas) do
        local playArea = LocalBlackjackTables[casinoId][entityId].playAreas[i]
        local cardOffset = PLAY_AREA_OFFSETS[i].cards
        playArea.surfaceObject = CreateTennisBall(GetOffsetFromEntityInWorldCoords(surfaceObject, cardOffset.coords - vector3(0.0, 0.0, 0.05)), false, false, false)
        FreezeEntityPosition(playArea.surfaceObject, true)
        SetEntityHeading(playArea.surfaceObject, heading + cardOffset.rotation.z)
    end
    for i,playArea in pairs(LocalBlackjackTables[casinoId][entityId].playAreas) do
        if i > 0 then
            LocalBlackjackTables[casinoId][entityId].interacts[#LocalBlackjackTables[casinoId][entityId].interacts + 1] = CreateInteraction({
                label = _L("interact_blackjack") .. (casinoEntity.settings.vip and (" " .. _L("casino_vip_game")) or ""),
                icon = Config.TargetIcons and Config.TargetIcons["blackjack"] or nil,
                coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.8, 1.0),
                heading = heading,
            }, function(selected)
                local casino = Casinos[casinoId]
                if not casino then return end
                if not casino.settings.isOpen then
                    return ShowNotification(_L("casino_closed"))
                end
                ServerCallback("pickle_casinos:getVIPStatus", function(isVIP)
                    if casinoEntity.settings.vip and not isVIP then return ShowNotification(_L("casino_vip_required")) end
                    AttemptSeatAtBlackjackEntity(casinoId, entityId)
                end, casinoId, entityId)
            end)
        end
    end
end

function UnrenderBlackjackEntity(casinoId, entityId)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    if blackjackTable.interacts then
        for i=1, #blackjackTable.interacts do
            DeleteInteraction(blackjackTable.interacts[i])
        end
    end
    if blackjackTable.dealerPed then DeleteScriptObject(blackjackTable.dealerPed) end
    if blackjackTable.tableObject then DeleteScriptObject(blackjackTable.tableObject) end
    if blackjackTable.surfaceObject then DeleteScriptObject(blackjackTable.surfaceObject) end
    if blackjackTable.playAreas then
        for i, v in pairs(blackjackTable.playAreas) do  
            local playArea = blackjackTable.playAreas[i]
            for a, b in pairs(playArea.hands) do
                for j=1, #b do
                    DeleteScriptObject(b[j])
                end
            end
            for j=1, #playArea.wagers do
                for k=1, #playArea.wagers[j] do
                    DeleteScriptObject(playArea.wagers[j][k])
                end
            end
            DeleteScriptObject(playArea.surfaceObject)
        end
    end
    blackjackTable.interacts = {}
    blackjackTable.playAreas = {}
    blackjackTable.dealerPed = nil
    blackjackTable.tableObject = nil
    blackjackTable.surfaceObject = nil
end

function DeleteBlackjackEntity(casinoId, entityId)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    UnrenderBlackjackEntity(casinoId, entityId)
    LocalBlackjackTables[casinoId][entityId] = nil
end

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    if not LocalBlackjackTables[casinoId] then return end
    if not LocalBlackjackTables[casinoId][entityId] then return end
    DeleteBlackjackEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:setCasinoEntityHidden", function(casinoId, entityId, toggle)
    if not LocalBlackjackTables[casinoId] then return end
    if not LocalBlackjackTables[casinoId][entityId] then return end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    blackjackTable.hidden = toggle
    if toggle then
        blackjackTable.visible = false
        UnrenderBlackjackEntity(casinoId, entityId)
    else
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - blackjackTable.coords) <= Config.RenderDistance then
            blackjackTable.visible = true
            RenderBlackjackEntity(casinoId, entityId)
        end
    end
end)

RegisterNetEvent("pickle_casinos:refreshCasinoEntity", function(casinoId, entityId)
    if not LocalBlackjackTables[casinoId] then return end
    if not LocalBlackjackTables[casinoId][entityId] then return end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    blackjackTable.coords = casinoEntity.settings.location.coords
    blackjackTable.heading = casinoEntity.settings.location.rotation.z
    if not blackjackTable.visible then return end
    UnrenderBlackjackEntity(casinoId, entityId)
    Wait(100)
    RenderBlackjackEntity(casinoId, entityId)
end)

CreateThread(function()
    while true do 
        local coords = GetEntityCoords(PlayerPedId())
        for casinoId, entities in pairs(LocalBlackjackTables) do
            for entityId, entity in pairs(entities) do
                if not entity.visible and not entity.hidden then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) <= Config.RenderDistance then
                        entity.visible = true
                        RenderBlackjackEntity(casinoId, entityId)
                    end
                elseif entity.visible then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) > Config.RenderDistance then
                        entity.visible = false
                        UnrenderBlackjackEntity(casinoId, entityId)
                    end
                end
            end
        end
        Wait(1500)
    end
end)

RegisterNUICallback("performBlackjackAction", function(data, cb)
    local animations = {
        ["hit"] = { dict = "anim_casino_b@amb@casino@games@blackjack@player", name = "request_card" },
        ["stand"] = { dict = "anim_casino_b@amb@casino@games@blackjack@player", name = "decline_card_001" },
        ["double"] = { dict = "anim_casino_b@amb@casino@games@blackjack@player", name = "place_bet_small" },
        ["split"] = { dict = "anim_casino_b@amb@casino@games@blackjack@player", name = "place_bet_small" },
    }
    TriggerServerEvent("pickle_casinos:blackjack:performAction", data.action)
    PlayBlackjackAnimation(PlayerPedId(), {dict = animations[data.action].dict, name = animations[data.action].name}, {time = 1000})
    cb("ok")
end)

RegisterNUICallback("setBlackjackWager", function(data, cb)
    TriggerServerEvent("pickle_casinos:blackjack:setWager", data.wager)
    cb("ok")
end)

RegisterNUICallback("repeatWager", function(data, cb)
    TriggerServerEvent("pickle_casinos:blackjack:repeatWager")
    cb("ok")
end)

RegisterNetEvent("pickle_casinos:exitGame", function()
    if not CurrentBlackjackTable then return end
    if DoesBlackjackEntityExist(CurrentBlackjackTable.casinoId, CurrentBlackjackTable.entityId) then
        local blackjackTable = LocalBlackjackTables[CurrentBlackjackTable.casinoId][CurrentBlackjackTable.entityId]
        PlayCasinoDealerSpeech(blackjackTable.dealerPed, "MINIGAME_DEALER_LEAVE_NEUTRAL_GAME", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
    end
    local casinoId = CurrentBlackjackTable.casinoId
    local entityId = CurrentBlackjackTable.entityId
    local seatId = CurrentBlackjackTable.seatId
    local playerPed = PlayerPedId()
    PlayBlackjackAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_exit_left"}, {time = 4000})
    TriggerServerEvent("pickle_casinos:blackjack:leaveTable", casinoId, entityId, seatId)
    ExitCasinoCamera(CurrentCamera)
    CurrentBlackjackTable = nil
    CurrentCamera = nil
    Wait(4000)
    ClearPedTasks(playerPed)
end)

RegisterNetEvent("pickle_casinos:updateBalance", function(balance)
    if not CurrentBlackjackTable then return end
    CurrentBlackjackTable.balance = money
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)

RegisterNetEvent("pickle_casinos:blackjack:updateSeatWager", function(casinoId, entityId, seatId, handId, wager)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    if CurrentBlackjackTable and CurrentBlackjackTable.casinoId == casinoId and CurrentBlackjackTable.entityId == entityId then
        if CurrentBlackjackTable.seats[seatId].wagers then
            CurrentBlackjackTable.seats[seatId].wagers[handId] = wager
        end
        SendNUIMessage({
            type = "updateBlackjackSeats",
            seats = GetBlackjackSeatsForUI(),
        })
        if CurrentBlackjackTable.seatId == seatId and handId == 1 then
            SendNUIMessage({
                type = "updateBlackjackWager",
                data = {
                    wager = wager,
                },
            })
        end
    end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    if not blackjackTable or not blackjackTable.visible then return end
    local playArea = blackjackTable.playAreas[seatId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local heading = casinoEntity.settings.location.rotation.z
    local chipOffset = PLAY_AREA_OFFSETS[seatId].chips
    for i=1, #playArea.wagers[handId] do
        DeleteScriptObject(playArea.wagers[handId][i])
    end
    playArea.wagers[handId] = {}
    local chips = GetCalculatedChips(wager)
    for i=1, #chips do
        local chip = chips[i]
        local chipObject = CreateProp(chip.model, GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, vector3((handId == 2 and 0.1 or 0.0), -0.12, 1 + (i - 1) * 0.0065)), false, false, false)
        FreezeEntityPosition(chipObject, true)
        SetEntityRotation(chipObject, 0.0, 0.0, heading + chipOffset.rotation.z, 2, true)
        table.insert(playArea.wagers[handId], chipObject)
    end
end)

RegisterNetEvent("pickle_casinos:blackjack:updateSeatCards", function(casinoId, entityId, seatId, handId, cards, extraData)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    local extraData = extraData or {}
    if CurrentBlackjackTable and CurrentBlackjackTable.casinoId == casinoId and CurrentBlackjackTable.entityId == entityId then
        CurrentBlackjackTable.seats[seatId].hands[handId] = cards
        SendNUIMessage({
            type = "updateBlackjackSeats",
            seats = GetBlackjackSeatsForUI(handId),
        })
    end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    if not blackjackTable or not blackjackTable.visible then return end
    local value, secondaryValue = GetValueOfCards(cards)
    local blackjackValue = value
    if secondaryValue > value then
        blackjackValue = secondaryValue
    end
    local speech = (blackjackValue == 21 and "BLACKJACK" or blackjackValue)
    if blackjackValue > 21 then
        speech = seatId == 0 and "DEALER_BUSTS" or "PLAYER_BUST"
    end
    PlayCasinoDealerSpeech(blackjackTable.dealerPed, speech == "DEALER_BUSTS" and "MINIGAME_DEALER_BUSTS" or "MINIGAME_BJACK_DEALER_" .. speech, "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
    local playArea = blackjackTable.playAreas[seatId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    for i=1, #playArea.hands[handId] do
        DeleteScriptObject(playArea.hands[handId][i])
    end
    playArea.hands[handId] = {}
    local heading = casinoEntity.settings.location.rotation.z
    local cardOffset = PLAY_AREA_OFFSETS[seatId].cards
    local isSplit = handId == 2
    for i=1, #cards do
        local card = cards[i]
        local offset = vector3((i - 1) * 0.01, (i - 1) * 0.01, (i - 1) * 0.001)
        if seatId == 0 then
            offset = vector3(((i - 1) * (i <= 2 and -0.07 or -0.018) + (i > 2 and -0.06 or 0)), 0.0, (i <= 2 and 0 or 0.001) * (i - 1))
        end
        if isSplit then
            offset = offset + vector3(0.1, 0.0, 0.0)
        end
        local cardProp = CreateProp(GetCardModel(card.class, card.value), GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, offset + ((extraData.isDouble and i == #cards) and vector3(0.018, 0.02, 0.0) or 0)), false, false, false)
        FreezeEntityPosition(cardProp, true)
        SetEntityRotation(cardProp, 0.0, (card.class == "hidden") and 180.0 or 0.0, (heading + cardOffset.rotation.z) + ((extraData.isDouble and i == #cards) and 90.0 or 0.0), 2, true)
        table.insert(playArea.hands[handId], cardProp)
    end
end)

RegisterNetEvent("pickle_casinos:blackjack:updateSeat", function(casinoId, entityId, seatId, seatData)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    if CurrentBlackjackTable and CurrentBlackjackTable.casinoId == casinoId and CurrentBlackjackTable.entityId == entityId then
        SendNUIMessage({
            type = "updateBlackjackSeats",
            seats = GetBlackjackSeatsForUI(),
        })
        CurrentBlackjackTable.seats[seatId] = seatData
    end
    for i=1, 2 do
        TriggerEvent("pickle_casinos:blackjack:updateSeatWager", casinoId, entityId, seatId, i, seatData.wagers[i])
        TriggerEvent("pickle_casinos:blackjack:updateSeatCards", casinoId, entityId, seatId, i, seatData.hands[i])
    end
end)

RegisterNetEvent("pickle_casinos:blackjack:performAction", function(casinoId, entityId, action)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    local isCurrentTable = (CurrentBlackjackTable and CurrentBlackjackTable.casinoId == casinoId and CurrentBlackjackTable.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local dealerPed = blackjackTable.dealerPed
    if not blackjackTable.lastDealerRotation then
        blackjackTable.lastDealerRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
    end
    local targetRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
    if (action.handId and action.handId == 2) then
        targetRotation = targetRotation + vector3(0.0, 0.0, 10.0)
    end
    SetEntitySmoothRotation(dealerPed, blackjackTable.lastDealerRotation, targetRotation) 
    blackjackTable.lastDealerRotation = targetRotation
    if (action.type == "split") then
        PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "split_card_player_0" .. action.seat, 3.0, 1.0, -1, 2, 0, 0, 0, 0 )
        Wait(800)
        for i=1, #action.hands do
            TriggerEvent("pickle_casinos:blackjack:updateSeatCards", casinoId, entityId, action.seat, i, action.hands[i])
        end
    end
end)

RegisterNetEvent("pickle_casinos:blackjack:updateResults", function(casinoId, entityId, seatResults)
    if CurrentBlackjackTable and CurrentBlackjackTable.casinoId == casinoId and CurrentBlackjackTable.entityId == entityId then
        SendNUIMessage({
            type = "updateBlackjackStage",
            stage = {
                type = "results",
                seatResults = seatResults,
            }
        })
    end
end)

RegisterNetEvent("pickle_casinos:blackjack:updateStage", function(casinoId, entityId, stage)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    if not blackjackTable.visible then return end
    local isCurrentTable = (CurrentBlackjackTable and CurrentBlackjackTable.casinoId == casinoId and CurrentBlackjackTable.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local dealerPed = blackjackTable.dealerPed
    if not blackjackTable.lastDealerRotation then
        blackjackTable.lastDealerRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
    end
    local targetRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 180.0)
    if (stage.handId and stage.handId == 2) then
        targetRotation = targetRotation + vector3(0.0, 0.0, 10.0)
    end
    SetEntitySmoothRotation(dealerPed, blackjackTable.lastDealerRotation, targetRotation) 
    blackjackTable.lastDealerRotation = targetRotation
    if stage.type == "waiting" then
        PlayCasinoDealerSpeech(blackjackTable.dealerPed, "MINIGAME_DEALER_PLACE_BET", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
        CreateThread(function()
            while stage.time > 1 do
                stage.time = stage.time - 1
                if isCurrentTable then
                    SendNUIMessage({
                        type = "updateBlackjackStage",
                        stage = {
                            type = "waiting",
                            time = stage.time,
                        }
                    })
                end
                Wait(1000)
            end
        end)
    elseif stage.type == "dealing" then
        if isCurrentTable then
            SendNUIMessage({
                type = "updateBlackjackStage",
                stage = {
                    type = "dealing",
                    seat = stage.seat,
                    handId = stage.handId,
                    card = stage.card,
                }
            })
        end
        if stage.isFirstCard then
            PlayCasinoDealerSpeech(blackjackTable.dealerPed, "MINIGAME_DEALER_CLOSED_BETS", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
            Wait(3000)
        end
        local animation
        -- if cardIndex == 1 then 
        --     cardAnim = "deal_card_self_second_card"
        -- elseif cardIndex == 2 then 
        --     cardAnim = "deal_card_self"
        -- else 
        --     cardAnim = "deal_card_self_card_10"
        -- end
        if stage.seat < 1 then
            animation = {
                dict = "anim_casino_b@amb@casino@games@blackjack@dealer",
                name = stage.card.class == "hidden" and "deal_card_self" or "deal_card_self_second_card",
                wait = 750,
            }
        else
            animation = {
                dict = "anim_casino_b@amb@casino@games@blackjack@dealer",
                name = (stage.isHit and "hit" or "deal") .. "_card_player_0" .. stage.seat,
                wait = 750,
            }
        end
        PlayAnim(dealerPed, animation.dict, animation.name, 3.0, 1.0, -1, 2, 0, 0, 0, 0 )
        SetTimeout(600, function()
            local cardModel = GetCardModel(stage.card.class, stage.card.value)
            local card = CreateProp(cardModel, GetOffsetFromEntityInWorldCoords(blackjackTable.surfaceObject, 0.0, 0.0, 0.1), false, false, false)
            AttachEntityToEntity(card, dealerPed, GetPedBoneIndex(dealerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            Wait(animation.wait or 0)
            DeleteScriptObject(card)
        end)
    elseif stage.type == "turn" then
        PlayCasinoDealerSpeech(blackjackTable.dealerPed, "MINIGAME_BJACK_DEALER_ANOTHER_CARD", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
        if not stage.hasHit and not IsEntityPlayingAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "dealer_focus_player_0" .. stage.seat .. "_idle_intro", 3) then 
            PlayAnim(blackjackTable.dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "dealer_focus_player_0" .. stage.seat .. "_idle_intro", 3.0, 1.0, -1, 2, 0, 0, 0, 0 )
        end
        if isCurrentTable then
            SendNUIMessage({
                type = "updateBlackjackStage",
                stage = {
                    type = "turn",
                    seat = stage.seat,
                    timeLeft = 10,
                }
            })
            SendNUIMessage({
                type = "updateBlackjackSeats",
                seats = GetBlackjackSeatsForUI(stage.handId),
            })
        end
    elseif stage.type == "displayCard" then 
        if isCurrentTable then
            SendNUIMessage({
                type = "updateBlackjackStage",
                stage = {
                    type = "displayCard",
                }
            })
        end
        local dealerPed = blackjackTable.dealerPed
        local card = blackjackTable.playAreas[0].hands[1][1]
        local coords = GetEntityCoords(card)
        local rotation = GetEntityRotation(card)
        DeleteScriptObject(card)
        local card = CreateProp(GetCardModel(stage.card.class, stage.card.value), coords, false, false, false)
        SetEntityRotation(card, rotation.x, rotation.y, rotation.z + 180.0, 2, true)
        SetEntityCoords(card, coords)
        PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "turn_card", 3.0, 1.0, -1, 2, 0, 0, 0, 0 )
        Wait(500)
        AttachEntityToEntity(card, dealerPed, GetPedBoneIndex(dealerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        Wait(800)
        DeleteScriptObject(card)
    elseif stage.type == "cleanup" then
        local dealerPed = blackjackTable.dealerPed
        if stage.seat ~= 0 then
            PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "retrieve_cards_player_0" .. stage.seat, 3.0, 1.0, -1, 2, 0, 0, 0, 0)
            Wait(600)
            for i=1, #blackjackTable.playAreas[stage.seat].hands do
                for j=1, #blackjackTable.playAreas[stage.seat].hands[i] do
                    DeleteScriptObject(blackjackTable.playAreas[stage.seat].hands[i][j])
                end
                blackjackTable.playAreas[stage.seat].hands[i] = {}
            end
            for i=1, #blackjackTable.playAreas[stage.seat].wagers do
                for j=1, #blackjackTable.playAreas[stage.seat].wagers[i] do
                    DeleteScriptObject(blackjackTable.playAreas[stage.seat].wagers[i][j])
                end
                blackjackTable.playAreas[stage.seat].wagers[i] = {}
            end
        else
            PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "retrieve_own_cards_and_remove", 3.0, 1.0, -1, 2, 0, 0, 0, 0)
            Wait(400)
            for i=1, #blackjackTable.playAreas[0].hands do
                for j=1, #blackjackTable.playAreas[0].hands[i] do
                    DeleteScriptObject(blackjackTable.playAreas[0].hands[i][j])
                end
                blackjackTable.playAreas[0].hands[i] = {}
            end
        end
        if isCurrentTable then
            CurrentBlackjackTable.seats[stage.seat].hands = {{}, {}}
            SendNUIMessage({
                type = "updateBlackjackSeats",
                seats = GetBlackjackSeatsForUI(),
            })
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k,v in pairs(LocalBlackjackTables) do
            for id, _ in pairs(v) do
                DeleteBlackjackEntity(k, id)
            end
        end
    end
end)