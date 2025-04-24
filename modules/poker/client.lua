local LocalPokerTables = {}
local CurrentPokerTable = nil
local POKER_SEATS = {
    {
        coords = vector3(0.76999998092651, -0.30000004172325, 0.0), rotation = vector3(0.0, 0.0, 25.5),
    },
    {
        coords = vector3(0.9399995803833, -0.090000063180923, 0.0), rotation = vector3(0.0, 0.0, 65.5)
    },
    {
        coords = vector3(0.91999959945679, 0.13999992609024, 0.0), rotation = vector3(0.0, 0.0, 112.0)
    },
    {
        coords = vector3(0.70999981880188, 0.32999988555908, 0.0), rotation = vector3(0.0, 0.0, 148.0)
    },
    {
        coords = vector3(0.25000022768974, 0.36999988555908, 0.0), rotation = vector3(0.0, 0.0, 180.01)
    },
    {
        coords = vector3(-0.28999981284142, 0.36999988555908, 0.0), rotation = vector3(0.0, 0.0, 180.01)
    },
    {
        coords = vector3(-0.72999942302704, 0.32999992370605, 0.0), rotation = vector3(0.0, 0.0, 205.5)
    },
    {
        coords = vector3(-0.95999920368195, 0.13999992609024, 0.0), rotation = vector3(0.0, 0.0, 246.5)
    },
    {
        coords = vector3(-0.94999921321869, -0.14000006020069, 0.0), rotation = vector3(0.0, 0.0, 296.5)
    },
    {
        coords = vector3(-0.7399994134903, -0.31000006198883, 0.0), rotation = vector3(0.0, 0.0, 339.5)
    },
}
local CurrentCamera

function EnsurePokerCamera()
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

function DoesPokerEntityExist(casinoId, entityId) 
    return LocalPokerTables[casinoId] and LocalPokerTables[casinoId][entityId]
end

function PlayPokerAnimation(ped, animation, data)
    playingPokerAnimation = true
    SetTimeout((data and data.time) or 1000, function()
        playingPokerAnimation = false
    end)
    local playArea = LocalPokerTables[CurrentPokerTable.casinoId][CurrentPokerTable.entityId].playAreas[CurrentPokerTable.seatId]
    local coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.5, 0.0275)
    local rotation = GetEntityRotation(playArea.surfaceObject) + vector3(0.0, 0.0, 90.0)
    local netScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, rotation.x, rotation.y, rotation.z, 2, 1, 0, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(ped, netScene, animation.dict, animation.name, 2.0, -2.0, 13, 16, 2.0, 0) -- 8.0, -1.5, 157, 16, 1148846080, 0) ?
    NetworkStartSynchronisedScene(netScene)
end

function GetPokerSeatsForUI()
    if not CurrentPokerTable then return {} end
    return CurrentPokerTable.seats
end

function AttemptSeatAtPokerEntity(casinoId, entityId)
    local closestSeat = nil
    local closestDistance = 1000.0
    for i=1, #POKER_SEATS do
        local seatOffset = POKER_SEATS[i]
        local playArea = LocalPokerTables[casinoId][entityId].playAreas[i]
        local distance = #(GetEntityCoords(PlayerPedId()) - GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.8, 1.0))
        if distance < closestDistance then
            closestDistance = distance
            closestSeat = i
        end
    end
    if closestDistance > 1.5 then return ShowNotification(_L("interact_far")) end
    ServerCallback("pickle_casinos:poker:requestSeat", function(seatId, entityInfo)
        local playerPed = PlayerPedId()
        print("POKER SIT", seatId, entityInfo)
        if not seatId then return end
        CurrentPokerTable = {
            casinoId = casinoId,
            entityId = entityId,
            seatId = seatId,
            game = entityInfo.game,
            bets = entityInfo.bets,
            money = entityInfo.money,
            seats = entityInfo.seats,
            stage = entityInfo.stage,
        }
        local casinoId = CurrentPokerTable.casinoId
        local entityId = CurrentPokerTable.entityId
        local seatId = CurrentPokerTable.seatId
        local localPokerTable = LocalPokerTables[casinoId][entityId]
        ClearPedTasksImmediately(playerPed)
        PlayPokerAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_enter_left"}, {time = 6000})
        EnsurePokerCamera()
        local camCoords = GetOffsetFromEntityInWorldCoords(localPokerTable.surfaceObject, 0.0, 0.0, 3.0)
        SetFocusArea(camCoords)
        EnsurePokerCamera()
        SetCamParams(CurrentCamera, camCoords.x, camCoords.y, camCoords.z,
            -90.0, 0.0, localPokerTable.heading + 180.0, 45.0, 
            0, 0, 0, 2
        )
        SendNUIMessage({
            type = "setCurrentGame",
            game = {
                type = "poker",
                data = {
                    seatId = seatId,
                    seats = GetPokerSeatsForUI(),
                    money = CurrentPokerTable.money,
                    wagerLimit = {10, 100000},
                    stage = CurrentPokerTable.stage,
                }
            }
        })
        SetNuiFocus(true, true)
        CreateThread(function()
            while CurrentPokerTable do
                if CurrentPokerTable.stage and CurrentPokerTable.stage.type == "waiting" and CurrentPokerTable.stage.time > 1 then
                    CurrentPokerTable.stage.time = CurrentPokerTable.stage.time - 1
                    SendNUIMessage({
                        type = "updatePokerStage",
                        stage = CurrentPokerTable.stage,
                    })
                end
                Wait(1000)
            end
        end)
        -- CreateThread(function()
        --     local seatId = 2
        --     local playArea = LocalPokerTables[casinoId][entityId].playAreas[seatId]
        --     local cardOffset = POKER_SEATS[seatId]
        --     local first = true
        --     while true do 
        --         local changed = false
        --         if IsControlPressed(0, 32) then
        --             changed = true
        --             cardOffset.coords = cardOffset.coords + vector3(0.0, 0.01, 0.0)
        --         end
        --         if IsControlPressed(0, 33) then
        --             changed = true
        --             cardOffset.coords = cardOffset.coords - vector3(0.0, 0.01, 0.0)
        --         end
        --         if IsControlPressed(0, 34) then
        --             changed = true
        --             cardOffset.coords = cardOffset.coords + vector3(0.01, 0.0, 0.0)
        --         end
        --         if IsControlPressed(0, 35) then
        --             changed = true
        --             cardOffset.coords = cardOffset.coords - vector3(0.01, 0.0, 0.0)
        --         end
        --         if IsControlPressed(0, 174) then
        --             changed = true
        --             cardOffset.rotation = cardOffset.rotation - vector3(0.0, 0.0, 0.5)
        --         end
        --         if IsControlPressed(0, 175) then
        --             changed = true
        --             cardOffset.rotation = cardOffset.rotation + vector3(0.0, 0.0, 0.5)
        --         end
        --         if IsControlPressed(0, 51) then
        --             lib.setClipboard("coords = vector3(" .. cardOffset.coords.x .. ", " .. cardOffset.coords.y .. ", " .. cardOffset.coords.z .. "), rotation = vector3(" .. cardOffset.rotation.x .. ", " .. cardOffset.rotation.y .. ", " .. cardOffset.rotation.z .. ")")
        --         end 
        --         if changed or first then
        --             first= false
        --             SetEntityCoords(playArea.surfaceObject, GetOffsetFromEntityInWorldCoords(localPokerTable.surfaceObject, cardOffset.coords), false, false, false, false)
        --             SetEntityHeading(playArea.surfaceObject, localPokerTable.heading + cardOffset.rotation.z)
        --             PlayPokerAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "idle_cardgames"}, {time = 6000})
        --         end
        --         Wait(0)
        --     end
        -- end)
    end, casinoId, entityId, closestSeat)
end

function CreatePokerEntity(casinoId, entityId)
    if DoesPokerEntityExist(casinoId, entityId) then return end
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    if not LocalPokerTables[casinoId] then
        LocalPokerTables[casinoId] = {}
    end
    LocalPokerTables[casinoId][entityId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - coords) <= Config.RenderDistance,
        coords = coords,
        heading = heading,
    }
    RenderPokerEntity(casinoId, entityId)
    -- AttemptSeatAtPokerEntity(casinoId, entityId)
end

function RenderPokerEntity(casinoId, entityId)
    local localPokerTable = LocalPokerTables[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not localPokerTable.visible or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords - vector3(0.0, 0.0, 0.38)
    local heading = casinoEntity.settings.location.rotation.z
    local tableObject = CreateProp(casinoEntity.settings.tableModel, coords, false, false, false)
    local surfaceObject = CreateProp(`prop_tennis_ball`, coords + vector3(0.0, 0.0, 1.05), false, false, false)
    FreezeEntityPosition(tableObject, true)
    SetEntityHeading(tableObject, heading)
    FreezeEntityPosition(surfaceObject, true)
    SetEntityHeading(surfaceObject, heading)
    local dealerCoords = GetOffsetFromEntityInWorldCoords(surfaceObject, 0.0, -0.75, -0.9)
    local dealerPed = CreateDealerPed(casinoEntity.settings.dealerModel, dealerCoords, heading)
    if not LocalPokerTables[casinoId] then
        LocalPokerTables[casinoId] = {}
    end
    local defaultPlayAreas = {}
    local defaultInteracts = {}
    local dealerCards = {}
    -- for i=1, 5 do 
    --     local card = CreateProp(GetCardModel("hidden"), GetOffsetFromEntityInWorldCoords(surfaceObject, -0.12 + ((i - 1) * 0.075), -0.15, -0.9), false, false, false)
    --     SetEntityRotation(card, 0.0, 180.0, heading, 2, true)
    --     table.insert(dealerCards, card)
    -- end
    for i=1, #POKER_SEATS do
        local seatOffset = POKER_SEATS[i]
        local playSurface = CreateProp(`prop_tennis_ball`, GetOffsetFromEntityInWorldCoords(surfaceObject, seatOffset.coords - vector3(0.0, 0.0, 1.0)), false, false, false)
        FreezeEntityPosition(playSurface, true)
        SetEntityHeading(playSurface, heading + seatOffset.rotation.z)
        local cards = {}
        local chips = {}
        local betChips = {}
        -- local funds = 100000
        -- local calculatedChips = GetCalculatedChips(funds, 1)
        -- local folded = true
        -- for j=1, #calculatedChips do
        --     local chip = calculatedChips[j]
        --     local chipObject = CreateProp(chip.model, GetOffsetFromEntityInWorldCoords(playSurface, 0.0, -0.12, 1.0 + ((j - 1) * 0.0065)), false, false, false)
        --     SetEntityHeading(chipObject, heading + seatOffset.rotation.z)
        --     table.insert(chips, chipObject)
        -- end
        -- for j=1, #calculatedChips do
        --     local chip = calculatedChips[j]
        --     local chipObject = CreateProp(chip.model, GetOffsetFromEntityInWorldCoords(playSurface, 0.0, 0.12, 1.0 +  ((j - 1) * 0.0065)), false, false, false)
        --     SetEntityHeading(chipObject, heading + seatOffset.rotation.z)
        --     table.insert(betChips, chipObject)
        -- end
        -- for j=1, 2 do 
        --     local card = CreateProp(GetCardModel("hidden"), GetOffsetFromEntityInWorldCoords(playSurface, -0.02 + ((j - 1) * 0.035), (folded and 0.21 or 0.015) - ((j - 1) * 0.005), ((j - 1) * 0.0065)), false, false, false)
        --     SetEntityRotation(card, 0.0, 180.0, (heading + seatOffset.rotation.z) + (20 * (-1 + ((j - 1) * 2))), 2, true)
        --     table.insert(cards, card)
        -- end
        defaultPlayAreas[i] = {
            cards = cards,
            chips = chips,
            betChips = betChips,
            surfaceObject = playSurface,
        }
        defaultInteracts[i] = CreateInteraction({
            label = _L("interact_poker"),
            coords = GetOffsetFromEntityInWorldCoords(playSurface, 0.0, -0.8, 1.0),
            heading = heading,
        }, function(selected)
            AttemptSeatAtPokerEntity(casinoId, entityId)
        end)
    end
    localPokerTable.tableObject = tableObject
    localPokerTable.surfaceObject = surfaceObject
    localPokerTable.dealerPed = dealerPed
    localPokerTable.dealerCards = dealerCards
    localPokerTable.playAreas = defaultPlayAreas
    localPokerTable.interacts = defaultInteracts
end

function UnrenderPokerEntity(casinoId, entityId)
    local slotEntity = LocalPokerTables[casinoId][entityId]
    if not slotEntity then return end
    if slotEntity.tableObject then
        DeleteObject(slotEntity.tableObject)
    end
    if slotEntity.surfaceObject then
        DeleteObject(slotEntity.surfaceObject)
    end
    if slotEntity.dealerPed then
        DeleteScriptObject(slotEntity.dealerPed)
    end
    if slotEntity.dealerCards then
        for i=1, #slotEntity.dealerCards do
            DeleteObject(slotEntity.dealerCards[i])
        end
    end
    if slotEntity.interacts then
        for i=1, #slotEntity.interacts do
            DeleteInteraction(slotEntity.interacts[i])
        end
    end
    if slotEntity.playAreas then
        for i,v in pairs(slotEntity.playAreas) do
            DeleteObject(v.surfaceObject)
            for j=1, #v.cards do
                DeleteObject(v.cards[j])
            end
            for j=1, #v.chips do
                DeleteObject(v.chips[j])
            end
            for j=1, #v.betChips do
                DeleteObject(v.betChips[j])
            end
        end
    end
    slotEntity.tableObject = nil
    slotEntity.surfaceObject = nil
    slotEntity.dealerPed = nil
    slotEntity.dealerCards = nil
    slotEntity.interacts = nil
    slotEntity.playAreas = nil
end

function DeletePokerEntity(casinoId, entityId)
    UnrenderPokerEntity(casinoId, entityId)
    LocalPokerTables[casinoId][entityId] = nil
end

function TurnDealerToSeat(casinoId, entityId, targetSeat, rotationOffset)
    local localPokerTable = LocalPokerTables[casinoId][entityId]
    if not localPokerTable or not localPokerTable.visible then return end
    local dealerPed = localPokerTable.dealerPed
    local playArea = localPokerTable.playAreas[targetSeat]
    local playAreaCoords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, -0.02, 0.15, 0.0)
    local dealerCoords = GetOffsetFromEntityInWorldCoords(dealerPed, 0.0, 0.0, 0.0)
    local targetHeading = GetHeadingFromVector_2d(playAreaCoords.x - dealerCoords.x, playAreaCoords.y - dealerCoords.y) + (rotationOffset or 20)
    SetEntitySmoothRotation(dealerPed, localPokerTable.lastDealerRotation, vector3(0.0, 0.0, targetHeading))
    localPokerTable.lastDealerRotation = vector3(0.0, 0.0, targetHeading)
end

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    if not LocalPokerTables[casinoId] then return end
    if not LocalPokerTables[casinoId][entityId] then return end
    DeletePokerEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:setCasinoEntityHidden", function(casinoId, entityId, toggle)
    if not LocalPokerTables[casinoId] then return end
    if not LocalPokerTables[casinoId][entityId] then return end
    local pokerTable = LocalPokerTables[casinoId][entityId]
    pokerTable.hidden = toggle
    if toggle then
        pokerTable.visible = false
        UnrenderPokerEntity(casinoId, entityId)
    else
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - pokerTable.coords) <= Config.RenderDistance then
            pokerTable.visible = true
            RenderPokerEntity(casinoId, entityId)
        end
    end
end)

RegisterNetEvent("pickle_casinos:refreshCasinoEntity", function(casinoId, entityId)
    if not LocalPokerTables[casinoId] then return end
    if not LocalPokerTables[casinoId][entityId] then return end
    local pokerTable = LocalPokerTables[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    pokerTable.coords = casinoEntity.settings.location.coords
    pokerTable.heading = casinoEntity.settings.location.rotation.z
    if not pokerTable.visible then return end
    UnrenderPokerEntity(casinoId, entityId)
    Wait(100)
    RenderPokerEntity(casinoId, entityId)
end)

CreateThread(function()
    while true do 
        local coords = GetEntityCoords(PlayerPedId())
        for casinoId, entities in pairs(LocalPokerTables) do
            for entityId, entity in pairs(entities) do
                if not entity.visible and not entity.hidden then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) <= Config.RenderDistance then
                        entity.visible = true
                        RenderPokerEntity(casinoId, entityId)
                    end
                elseif entity.visible then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) > Config.RenderDistance then
                        entity.visible = false
                        UnrenderPokerEntity(casinoId, entityId)
                    end
                end
            end
        end
        Wait(1500)
    end
end)

RegisterNetEvent("pickle_casinos:poker:updateSeat", function(casinoId, entityId, seatId, seat, hugeUpdate)
    if not hugeUpdate and CurrentPokerTable and CurrentPokerTable.casinoId == casinoId and CurrentPokerTable.entityId == entityId then
        CurrentPokerTable.seats[seatId] = seat
        SendNUIMessage({
            type = "updatePokerSeats",
            seats = GetPokerSeatsForUI(),
        })
    end
    local localPokerTable = LocalPokerTables[casinoId][entityId]
    if not localPokerTable or not localPokerTable.visible then return end
    local playArea = localPokerTable.playAreas[seatId]
    if not playArea then return end
    local folded = seat.folded
    local seatOffset = POKER_SEATS[seatId]
    for j=1, 2 do 
        if playArea.cards[j] then
            DeleteObject(playArea.cards[j])
        end
        if seat.cards[j] then
            local card = CreateProp(GetCardModel("hidden"), GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, -0.02 + ((j - 1) * 0.035), (folded and 0.21 or 0.015) - ((j - 1) * 0.005), ((j - 1) * 0.0065)), false, false, false)
            SetEntityRotation(card, 0.0, 180.0, (localPokerTable.heading + seatOffset.rotation.z) + (20 * (-1 + ((j - 1) * 2))), 2, true)
            playArea.cards[j] = card
        end
    end
end)

RegisterNetEvent("pickle_casinos:poker:updatePot", function(casinoId, entityId, pot)
    if CurrentPokerTable and CurrentPokerTable.casinoId == casinoId and CurrentPokerTable.entityId == entityId then
        CurrentPokerTable.pot = pot
        SendNUIMessage({
            type = "updatePokerPot",
            pot = pot,
        })
    end
    local localPokerTable = LocalPokerTables[casinoId][entityId]
    if not localPokerTable or not localPokerTable.visible then return end
    -- TODO: Show middle chips
end)

RegisterNetEvent("pickle_casinos:poker:updateSeats", function(casinoId, entityId, seats)
    for i=1, #seats do
        TriggerEvent("pickle_casinos:poker:updateSeat", casinoId, entityId, i, seats[i], true)
    end
    SendNUIMessage({
        type = "updatePokerSeats",
        seats = GetPokerSeatsForUI(),
    })
end)

RegisterNetEvent("pickle_casinos:poker:updateStage", function(casinoId, entityId, stage)
    if not DoesPokerEntityExist(casinoId, entityId) then return end
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casinoEntity then return end
    local localPokerTable = LocalPokerTables[casinoId][entityId]
    if not localPokerTable.visible then return end
    local dealerPed = localPokerTable.dealerPed
    if not localPokerTable.lastDealerRotation then
        localPokerTable.lastDealerRotation = casinoEntity.settings.location.rotation + vector3(0.0, 0.0, 0.0)
    end
    local isCurrentTable = (CurrentPokerTable and CurrentPokerTable.casinoId == casinoId and CurrentPokerTable.entityId == entityId)
    if isCurrentTable then
        CurrentPokerTable.stage = stage
    end
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if localPokerTable.tempDeck and stage.type ~= "dealing" then
        DeleteScriptObject(localPokerTable.tempDeck)
        localPokerTable.tempDeck = nil
    end
    if stage.type == "waiting" then
        if isCurrentTable then
            SendNUIMessage({
                type = "updatePokerStage",
                stage = stage,
            })
        end
    elseif stage.type == "dealing" then
        if isCurrentTable then
            SendNUIMessage({
                type = "updatePokerStage",
                stage = stage,
            })
        end
        local dealerCoords = GetOffsetFromEntityInWorldCoords(localPokerTable.dealerPed, 0.0, 0.0, 0.0)
        TurnDealerToSeat(casinoId, entityId, stage.seat)
        if not localPokerTable.tempDeck then
            localPokerTable.tempDeck = CreateProp(`vw_prop_vw_casino_cards_01`, dealerCoords, false, false, false)
            AttachEntityToEntity(localPokerTable.tempDeck, localPokerTable.dealerPed, GetPedBoneIndex(localPokerTable.dealerPed, 60309), 0.0, 0.0, -0.015, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        end
        local tempDeck = localPokerTable.tempDeck

        ClearPedTasks(localPokerTable.dealerPed)
        PlayAnim(localPokerTable.dealerPed, "anim_casino_b@amb@casino@games@threecardpoker@dealer", "deck_deal_p03", 1.0, -1.0, -1, 1, 1.0)
        Wait(500)
        local tempCard = CreateProp(GetCardModel("hidden"), dealerCoords, false, false, false)
        AttachEntityToEntity(tempCard, dealerPed, GetPedBoneIndex(dealerPed, 28422), 0.05, 0.05, 0.0, 180.0, 0.0, 0.0, false, false, false, false, 2, true)
        Wait(600)
        DeleteScriptObject(tempCard)
        ClearPedTasks(localPokerTable.dealerPed)
    elseif stage.type == "seatTurn" then
        print("Seat turn", stage.seat)
        ClearPedTasks(localPokerTable.dealerPed)
        PlayAnim(localPokerTable.dealerPed, "anim_casino_b@amb@casino@games@blackjack@dealer", "dealer_focus_player_03_idle_intro", 3.0, 1.0, -1, 2, 0, 0, 0, 0 )
        TurnDealerToSeat(casinoId, entityId, stage.seat, 15)
    end
end)

RegisterNetEvent("pickle_casinos:poker:updateBalance", function(balance)
    if not CurrentPokerTable then return end
    CurrentPokerTable.money = balance
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)

AddEventHandler("pickle_casinos:exitGame", function()
    if not CurrentPokerTable then return end
    TriggerServerEvent("pickle_casinos:poker:leaveTable")
    CurrentPokerTable = nil
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k,v in pairs(LocalPokerTables) do
            for id, _ in pairs(v) do
                DeletePokerEntity(k, id)
            end
        end
    end
end)