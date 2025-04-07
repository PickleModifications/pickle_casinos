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
        coords = vector3(0.68999981880188, 0.36999988555908, 0.0), rotation = vector3(0.0, 0.0, 148.0)
    },
    {
        coords = vector3(0.23000022768974, 0.36999988555908, 0.0), rotation = vector3(0.0, 0.0, 173.5)
    },
    {
        coords = vector3(-0.28999981284142, 0.36999988555908, 0.0), rotation = vector3(0.0, 0.0, 181.5)
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

function DoesPokerEntityExist(casinoId, entityId) 
    return LocalPokerTables[casinoId] and LocalPokerTables[casinoId][entityId]
end

function PlayPokerAnimation(ped, animation, data)
    playingPokerAnimation = true
    SetTimeout((data and data.time) or 1000, function()
        playingPokerAnimation = false
    end)
    local playArea = LocalPokerTables[CurrentPokerTable.casinoId][CurrentPokerTable.entityId].playAreas[CurrentPokerTable.seatId]
    local coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.5, 0.25)
    local rotation = GetEntityRotation(playArea.surfaceObject) + vector3(0.0, 0.0, 90.0)
    local netScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, rotation.x, rotation.y, rotation.z, 2, 1, 0, 1065353216, 0, 1065353216)
    NetworkAddPedToSynchronisedScene(ped, netScene, animation.dict, animation.name, 2.0, -2.0, 13, 16, 2.0, 0) -- 8.0, -1.5, 157, 16, 1148846080, 0) ?
    NetworkStartSynchronisedScene(netScene)
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
        }
        local casinoId = CurrentPokerTable.casinoId
        local entityId = CurrentPokerTable.entityId
        local seatId = CurrentPokerTable.seatId
        local localPokerTable = LocalPokerTables[casinoId][entityId]
        ClearPedTasksImmediately(playerPed)
        PlayPokerAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_enter_left"}, {time = 6000})
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
    local dealerCoords = GetOffsetFromEntityInWorldCoords(surfaceObject, 0.0, -0.75, 0.27)
    local dealerPed = CreateNPC(casinoEntity.settings.dealerModel, dealerCoords, heading, false, false)
    SetEntityInvincible(dealerPed, true)
    SetBlockingOfNonTemporaryEvents(dealerPed, true)
    FreezeEntityPosition(dealerPed, true)
    if not LocalPokerTables[casinoId] then
        LocalPokerTables[casinoId] = {}
    end
    local defaultPlayAreas = {}
    local defaultInteracts = {}
    for i=1, #POKER_SEATS do
        local seatOffset = POKER_SEATS[i]
        local playSurface = CreateProp(`prop_tennis_ball`, GetOffsetFromEntityInWorldCoords(surfaceObject, seatOffset.coords), false, false, false)
        FreezeEntityPosition(playSurface, true)
        SetEntityHeading(playSurface, heading + seatOffset.rotation.z)
        defaultPlayAreas[i] = {
            cards = {},
            chips = {},
            betChips = {},
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
    LocalPokerTables[casinoId][entityId] = {
        coords = coords,
        heading = heading,
        tableObject = tableObject,
        surfaceObject = surfaceObject,
        dealerPed = dealerPed,
        playAreas = defaultPlayAreas,
        interacts = defaultInteracts,
    }
    AttemptSeatAtPokerEntity(casinoId, entityId)
end

function DeletePokerEntity(casinoId, entityId)
    local slotEntity = LocalPokerTables[casinoId][entityId]
    if not slotEntity then return end
    DeleteObject(slotEntity.tableObject)
    DeleteObject(slotEntity.surfaceObject)
    DeleteEntity(slotEntity.dealerPed)
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
    LocalPokerTables[casinoId][entityId] = nil
end

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