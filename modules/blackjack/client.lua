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
        playAreas = {
            [0] = {
                cards = {},
                chips = {},
            },
            {
                cards = {},
                chips = {},
            },
            {
                cards = {},
                chips = {},
            },
            {
                cards = {},
                chips = {},
            },
            {
                cards = {},
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
        -- for j=1, 4 do
        --     local card = CreateProp(GetHashKey("vw_prop_cas_card_club_0".. (j + 2)), GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, vector3((j - 1) * 0.01, 0.0, (j - 1) * 0.001)), false, false, false)
        --     FreezeEntityPosition(card, true)
        --     SetEntityHeading(card, heading + cardOffset.rotation.z)
        --     table.insert(playArea.cards, card)
        -- end
        -- local chipsvalue = math.random(10000, 60000)
        -- local chips = GetCalculatedChips(chipsvalue)
        -- for j=1, #chips do
        --     local chip = chips[j]
        --     local chipOffset = PLAY_AREA_OFFSETS[i].chips
        --     local chipObject = CreateProp(chip.model, GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, vector3(0.0, -0.12, 1 + (j - 1) * 0.0065)), false, false, false)
        --     FreezeEntityPosition(chipObject, true)
        --     SetEntityHeading(chipObject, heading + chipOffset.rotation.z)
        --     table.insert(playArea.chips, chipObject)
        -- end
        -- print( "Chips: " .. chipsvalue, #chips )
    end
end

function DeleteBlackjackEntity(casinoId, entityId)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    DeleteEntity(blackjackTable.dealerPed)
    DeleteEntity(blackjackTable.tableObject)
    DeleteEntity(blackjackTable.surfaceObject)
    for i, v in pairs(blackjackTable.playAreas) do  
        local playArea = blackjackTable.playAreas[i]
        for j=1, #playArea.cards do
            DeleteEntity(playArea.cards[j])
        end
        for j=1, #playArea.chips do
            DeleteEntity(playArea.chips[j])
        end
        DeleteEntity(playArea.surfaceObject)
    end
    LocalBlackjackTables[casinoId][entityId] = nil
end

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

RegisterNetEvent("pickle_casinos:blackjack:updateSeatCards", function(casinoId, entityId, seatId, cards)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    local playArea = blackjackTable.playAreas[seatId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    for i=1, #playArea.cards do
        DeleteEntity(playArea.cards[i])
    end
    playArea.cards = {}
    local heading = casinoEntity.rotation.z
    local cardOffset = PLAY_AREA_OFFSETS[seatId].cards
    for i=1, #cards do
        local card = cards[i]
        local offset = vector3((i - 1) * 0.01, (i - 1) * 0.01, (i - 1) * 0.001)
        if seatId == 0 then
            offset = vector3(((i - 1) * (i <= 2 and -0.07 or -0.018) + (i > 2 and -0.06 or 0)), 0.0, (i <= 2 and 0 or 0.001) * (i - 1))
        end
        local cardProp = CreateProp(GetCardModel(card.class, card.value), GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, offset), false, false, false)
        FreezeEntityPosition(cardProp, true)
        SetEntityRotation(cardProp, 0.0, (card.class == "hidden") and 180.0 or 0.0, heading + cardOffset.rotation.z, 2, true)
        table.insert(playArea.cards, cardProp)
    end
end)

RegisterNetEvent("pickle_casinos:blackjack:updateStage", function(casinoId, entityId, stage)
    if not DoesBlackjackEntityExist(casinoId, entityId) then return end
    local blackjackTable = LocalBlackjackTables[casinoId][entityId]
    if stage.type == "dealing" then
        local dealerPed = blackjackTable.dealerPed
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
        Wait(1000)
        TriggerServerEvent("pickle_casinos:blackjack:performAction", "hit")
    elseif stage.type == "displayCard" then
        local dealerPed = blackjackTable.dealerPed
        local card = blackjackTable.playAreas[0].cards[1]
        local coords = GetEntityCoords(card)
        local rotation = GetEntityRotation(card)
        DeleteEntity(card)
        local card = CreateProp(GetCardModel(stage.card.class, stage.card.value), coords, false, false, false)
        SetEntityRotation(card, rotation.x, rotation.y, rotation.z, 2, true)
        SetEntityCoords(card, coords)
        PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "turn_card", 3.0, 1.0, -1, 2, 0, 0, 0, 0 )
        Wait(500)
        AttachEntityToEntity(card, dealerPed, GetPedBoneIndex(dealerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        Wait(800)
        DetachEntity(card, false, true)
        SetEntityCoords(card, coords)
        SetEntityRotation(card, vector3(0.0, 0.0, rotation.z))
        FreezeEntityPosition(card, true)
        blackjackTable.playAreas[0].cards[1] = card
    elseif stage.type == "cleanup" then
        local dealerPed = blackjackTable.dealerPed
        if stage.seat ~= 0 then
            PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "retrieve_cards_player_0" .. stage.seat, 3.0, 1.0, -1, 2, 0, 0, 0, 0)
            Wait(400)
            for i=1, #blackjackTable.playAreas[stage.seat].cards do
                DeleteEntity(blackjackTable.playAreas[stage.seat].cards[i])
            end
            blackjackTable.playAreas[stage.seat].cards = {}
            for i=1, #blackjackTable.playAreas[stage.seat].chips do
                DeleteEntity(blackjackTable.playAreas[stage.seat].chips[i])
            end
        else
            PlayAnim(dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "retrieve_own_cards_and_remove", 3.0, 1.0, -1, 2, 0, 0, 0, 0)
            Wait(400)
            for i=1, #blackjackTable.playAreas[0].cards do
                DeleteEntity(blackjackTable.playAreas[0].cards[i])
            end
            blackjackTable.playAreas[0].cards = {}
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