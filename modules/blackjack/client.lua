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
local CHIP_VALUATIONS = {
    { value = 10, model = `vw_prop_chip_10dollar_x1` },
    { value = 50, model = `vw_prop_chip_50dollar_x1` },
    { value = 100, model = `vw_prop_chip_100dollar_x1` },
    { value = 500, model = `vw_prop_chip_500dollar_x1` },
    { value = 1000, model = `vw_prop_chip_1kdollar_x1` },
    { value = 5000, model = `vw_prop_plaq_5kdollar_x1` },
    { value = 10000, model = `vw_prop_plaq_10kdollar_x1` },
}
local CurrentBlackjackTable = nil
local playingBlackjackAnimation = false
function DoesBlackjackEntityExist(casinoId, entityId)
    return LocalBlackjackTables[casinoId] and LocalBlackjackTables[casinoId][entityId]
end

function GetCalculatedChips(amount)
    local chips = {}
    local remainingAmount = amount
    repeat
        local highestChip
        for i=1, #CHIP_VALUATIONS do
            local chip = CHIP_VALUATIONS[i]
            if chip.value <= remainingAmount then
                highestChip = chip
            end
        end
        if highestChip then
            table.insert(chips, highestChip)
            remainingAmount = remainingAmount - highestChip.value
        end
        if remainingAmount < CHIP_VALUATIONS[1].value then break end
    until (remainingAmount == 0 or #chips >= 2000)
    return chips
end

function GetSeatsForUI(currentHand)
    local seats = {}
    for i=0, 4 do
        local seat = CurrentBlackjackTable.seats[i]
        table.insert(seats, {
            source = seat.source,
            name = seat.name or "Unknown",
            currentHand = (currentHand or 1) - 1,
            hands = seat.hands,
            wager = seat.wager or 10,
        })
    end
    return seats
end

function DisplayBlackjackUI()
    if not CurrentBlackjackTable then return end
    local casinoId = CurrentBlackjackTable.casinoId
    local entityId = CurrentBlackjackTable.entityId
    local seatId = CurrentBlackjackTable.seatId
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "setCurrentGame",
        game = {
            type = "blackjack",
            data = {
                seatId = seatId,
                seats = GetSeatsForUI(),
                wagerLimit = {10, 100},
                stage = {
                    type = "waiting",
                },
            }
        }
    })
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
        }
        DisplayBlackjackUI()
        local playerPed = PlayerPedId()
        local playArea = blackjackTable.playAreas[seatId]
        PlayBlackjackAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_enter_left"}, {time = 6000})
        SetTableGamesCameraThisUpdate(`CASINO_BLACKJACK_CAMERA`)
        
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
                SetFollowPedCamViewMode(3)
                DisableIdleCamera(true)
                Wait(0)
            end
        end)
    end, casinoId, entityId, closest.seatId)
end

function CreateBlackjackEntity(casinoId, entityId)
    if DoesBlackjackEntityExist(casinoId, entityId) then return end
    local casino = Config.Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.coords
    local heading = casinoEntity.rotation.z
    local tableObject = CreateProp(casinoEntity.settings.tableModel, coords, false, false, false)
    local surfaceObject = CreateProp(`prop_tennis_ball`, coords - vector3(0.0, 0.0, 0.11), false, false, false)
    FreezeEntityPosition(tableObject, true)
    SetEntityHeading(tableObject, heading)
    FreezeEntityPosition(surfaceObject, true)
    SetEntityHeading(surfaceObject, heading)
    local dealerCoords = GetOffsetFromEntityInWorldCoords(surfaceObject, 0.0, 0.75, 0.03)
    local dealerPed = CreateNPC(casinoEntity.settings.dealerModel, dealerCoords, heading + 180.0, false, false)
    SetEntityInvincible(dealerPed, true)
    SetBlockingOfNonTemporaryEvents(dealerPed, true)
    FreezeEntityPosition(dealerPed, true)
    -- local tempCard = CreateProp(`vw_prop_cas_card_club_04`, GetOffsetFromEntityInWorldCoords(surfaceObject, 0.0, 0.0, 0.0), false, false, false)
    -- FreezeEntityPosition(tempCard, true)
    -- SetEntityHeading(tempCard, heading)
    
    if not LocalBlackjackTables[casinoId] then LocalBlackjackTables[casinoId] = {} end
    LocalBlackjackTables[casinoId][entityId] = {
        dealerPed = dealerPed,
        tableObject = tableObject,
        surfaceObject = surfaceObject,
        interacts = {},
        playAreas = {
            [0] = {
                hands = {{}, {}},
                chips = {},
            },
            {
                hands = {{}, {}},
                chips = {},
            },
            {
                hands = {{}, {}},
                chips = {},
            },
            {
                hands = {{}, {}},
                chips = {},
            },
            {
                hands = {{}, {}},
                chips = {},
            },
        }
    }
    for i,v in pairs(LocalBlackjackTables[casinoId][entityId].playAreas) do
        local playArea = LocalBlackjackTables[casinoId][entityId].playAreas[i]
        local cardOffset = PLAY_AREA_OFFSETS[i].cards
        playArea.surfaceObject = CreateProp(`prop_tennis_ball`, GetOffsetFromEntityInWorldCoords(surfaceObject, cardOffset.coords - vector3(0.0, 0.0, 0.05)), false, false, false)
        FreezeEntityPosition(playArea.surfaceObject, true)
        SetEntityHeading(playArea.surfaceObject, heading + cardOffset.rotation.z)
    end
    for i,playArea in pairs(LocalBlackjackTables[casinoId][entityId].playAreas) do
        if i > 0 then
            LocalBlackjackTables[casinoId][entityId].interacts[#LocalBlackjackTables[casinoId][entityId].interacts + 1] = CreateInteraction({
                label = _L("interact_blackjack"),
                coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.8, 1.0),
                heading = heading,
            }, function(selected)
                AttemptSeatAtBlackjackEntity(casinoId, entityId)
            end)
        end
    end
    AttemptSeatAtBlackjackEntity(casinoId, entityId)
end

function DeleteBlackjackEntity(casinoId, entityId)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    for i=1, #blackjackTable.interacts do
        DeleteInteraction(blackjackTable.interacts[i])
    end
    DeleteEntity(blackjackTable.dealerPed)
    DeleteEntity(blackjackTable.tableObject)
    DeleteEntity(blackjackTable.surfaceObject)
    for i, v in pairs(blackjackTable.playAreas) do  
        local playArea = blackjackTable.playAreas[i]
        for a, b in pairs(playArea.hands) do
            for j=1, #b do
                DeleteEntity(b[j])
            end
        end
        for j=1, #playArea.chips do
            DeleteEntity(playArea.chips[j])
        end
        DeleteEntity(playArea.surfaceObject)
    end
    LocalBlackjackTables[casinoId][entityId] = nil
end

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

RegisterNetEvent("pickle_casinos:blackjack:updateSeatWager", function(casinoId, entityId, seatId, wager)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    local playArea = blackjackTable.playAreas[seatId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local heading = casinoEntity.rotation.z
    local chipOffset = PLAY_AREA_OFFSETS[seatId].chips
    for i=1, #playArea.chips do
        DeleteEntity(playArea.chips[i])
    end
    playArea.chips = {}
    local chips = GetCalculatedChips(wager)
    for i=1, #chips do
        local chip = chips[i]
        local chipObject = CreateProp(chip.model, GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, vector3(0.0, -0.12, 1 + (i - 1) * 0.0065)), false, false, false)
        FreezeEntityPosition(chipObject, true)
        SetEntityRotation(chipObject, 0.0, 0.0, heading + chipOffset.rotation.z, 2, true)
        table.insert(playArea.chips, chipObject)
    end
end)

RegisterNetEvent("pickle_casinos:blackjack:updateSeatCards", function(casinoId, entityId, seatId, handId, cards)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    CurrentBlackjackTable.seats[seatId].hands[handId] = cards
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    local playArea = blackjackTable.playAreas[seatId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    for i=1, #playArea.hands[handId] do
        DeleteEntity(playArea.hands[handId][i])
    end
    playArea.hands[handId] = {}
    local heading = casinoEntity.rotation.z
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
        local cardProp = CreateProp(GetCardModel(card.class, card.value), GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, offset), false, false, false)
        FreezeEntityPosition(cardProp, true)
        SetEntityRotation(cardProp, 0.0, (card.class == "hidden") and 180.0 or 0.0, heading + cardOffset.rotation.z, 2, true)
        table.insert(playArea.hands[handId], cardProp)
    end
    SendNUIMessage({
        type = "updateBlackjackSeats",
        seats = GetSeatsForUI(handId),
    })
end)

RegisterNetEvent("pickle_casinos:blackjack:updateStage", function(casinoId, entityId, stage)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    local isCurrentTable = (CurrentBlackjackTable and CurrentBlackjackTable.casinoId == casinoId and CurrentBlackjackTable.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local dealerPed = blackjackTable.dealerPed
    local heading = casinoEntity.rotation.z + 180.0
    if (stage.handId == 2) then
        heading = heading + 10.0
    end
    SetEntityRotation(dealerPed, 0.0, 0.0, heading, 2, true)
    if stage.type == "dealing" then
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
            print(stage.card.class, stage.card.value)
            Wait(animation.wait or 0)
            DeleteEntity(card)
        end)
    elseif stage.type == "turn" then
        if not stage.hasHit then 
            PlayAnim(blackjackTable.dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "dealer_focus_player_0" .. stage.seat .. "_idle_intro", 3.0, 1.0, -1, 2, 0, 0, 0, 0 )
        end
        if isCurrentTable then
            SendNUIMessage({
                type = "updateBlackjackStage",
                stage = {
                    type = "turn",
                    seatId = stage.seat,
                    timeLeft = 10,
                }
            })
            SendNUIMessage({
                type = "updateBlackjackSeats",
                seats = GetSeatsForUI(stage.handId),
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
        DeleteEntity(card)
        local card = CreateProp(GetCardModel(stage.card.class, stage.card.value), coords, false, false, false)
        SetEntityRotation(card, rotation.x, rotation.y, rotation.z + 180.0, 2, true)
        SetEntityCoords(card, coords)
        PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "turn_card", 3.0, 1.0, -1, 2, 0, 0, 0, 0 )
        Wait(500)
        AttachEntityToEntity(card, dealerPed, GetPedBoneIndex(dealerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        Wait(800)
        DeleteEntity(card)
    elseif stage.type == "cleanup" then
        if isCurrentTable then
            SendNUIMessage({
                type = "updateBlackjackStage",
                stage = {
                    type = "results",
                    won = 0,
                }
            })
        end
        local dealerPed = blackjackTable.dealerPed
        if stage.seat ~= 0 then
            PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "retrieve_cards_player_0" .. stage.seat, 3.0, 1.0, -1, 2, 0, 0, 0, 0)
            Wait(600)
            for i=1, #blackjackTable.playAreas[stage.seat].hands do
                for j=1, #blackjackTable.playAreas[stage.seat].hands[i] do
                    DeleteEntity(blackjackTable.playAreas[stage.seat].hands[i][j])
                end
                blackjackTable.playAreas[stage.seat].hands[i] = {}
            end
            for i=1, #blackjackTable.playAreas[stage.seat].chips do
                DeleteEntity(blackjackTable.playAreas[stage.seat].chips[i])
            end
        else
            PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "retrieve_own_cards_and_remove", 3.0, 1.0, -1, 2, 0, 0, 0, 0)
            Wait(400)
            for i=1, #blackjackTable.playAreas[0].hands do
                for j=1, #blackjackTable.playAreas[0].hands[i] do
                    DeleteEntity(blackjackTable.playAreas[0].hands[i][j])
                end
                blackjackTable.playAreas[0].hands[i] = {}
            end
        end
        if isCurrentTable then
            CurrentBlackjackTable.seats[stage.seat].hands = {{}, {}}
            SendNUIMessage({
                type = "updateBlackjackSeats",
                seats = GetSeatsForUI(),
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