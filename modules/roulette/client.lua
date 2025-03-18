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
local CHIP_VALUATIONS = {
    { value = 10, model = `vw_prop_chip_10dollar_x1` },
    { value = 50, model = `vw_prop_chip_50dollar_x1` },
    { value = 100, model = `vw_prop_chip_100dollar_x1` },
    { value = 500, model = `vw_prop_chip_500dollar_x1` },
    { value = 1000, model = `vw_prop_chip_1kdollar_x1` },
    { value = 5000, model = `vw_prop_plaq_5kdollar_x1` },
    { value = 10000, model = `vw_prop_plaq_10kdollar_x1` },
}
local CurrentRouletteTable = nil
local playingRouletteAnimation = false
function DoesRouletteEntityExist(casinoId, entityId)
    return LocalRouletteTables[casinoId] and LocalRouletteTables[casinoId][entityId]
end

function GetCalculatedChips(amount)
    if amount <= 0 then return {} end
    local chips = {}
    local remainingAmount = amount
    repeat
        local highestChip = CHIP_VALUATIONS[1]
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

function GetRouletteSeatsForUI(currentHand)
    local seats = {}
    for i=1, 4 do
        local seat = CurrentRouletteTable.seats[i]
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

function DisplayRouletteUI()
    if not CurrentRouletteTable then return end
    local casinoId = CurrentRouletteTable.casinoId
    local entityId = CurrentRouletteTable.entityId
    local seatId = CurrentRouletteTable.seatId
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "setCurrentGame",
        game = {
            type = "roulette",
            data = {
                seatId = seatId,
                seats = GetRouletteSeatsForUI(),
                money = CurrentRouletteTable.money,
                wagerLimit = {10, 100000},
                stage = {
                    type = "waiting",
                },
            }
        }
    })
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
        CurrentRouletteTable = {
            casinoId = casinoId,
            entityId = entityId,
            seatId = seatId,
            seats = entityInfo.seats,
            stage = entityInfo.stage,
            wagers = entityInfo.wagers,
            money = entityInfo.money,
        }
        DisplayRouletteUI()
        local playerPed = PlayerPedId()
        local playArea = rouletteTable.playAreas[seatId]
        PlayRouletteAnimation(playerPed, {dict = "anim_casino_b@amb@casino@games@shared@player@", name = "sit_enter_left"}, {time = 6000})
        SetTableGamesCameraThisUpdate(`CASINO_ROULETTE_CAMERA`)
        Wait(6000)
        local coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.5, 0.05)
        local rotation = GetEntityRotation(playArea.surfaceObject) + vector3(0.0, 0.0, 90.0)
        CreateThread(function()
            while CurrentRouletteTable do
                if not playingRouletteAnimation and not IsEntityPlayingAnim(playerPed, "anim_casino_b@amb@casino@games@shared@player@", "idle_cardgames", 3) then
                    local netScene = NetworkCreateSynchronisedScene(coords, rotation, 2, 0, 1, 1065353216, 0, 1065353216)
                    NetworkAddPedToSynchronisedScene(playerPed, netScene, "anim_casino_b@amb@casino@games@shared@player@", "idle_cardgames", 2.0, -2.0, 13, 16, 2.0, 0)
                    NetworkStartSynchronisedScene(netScene)
                    Wait(100)
                end
                -- SetFollowPedCamViewMode(3)
                DisableIdleCamera(true)
                Wait(0)
            end
        end)
    end, casinoId, entityId, closest.seatId)
end

function PerformRouletteSpin(casinoId, entityId, numberString)
    local casino = Config.Casinos[casinoId]
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
    local coords = casinoEntity.coords
    local heading = casinoEntity.rotation.z
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    local targetCoords = GetWorldPositionOfEntityBone(rouletteTable.tableObject, GetEntityBoneIndexByName(rouletteTable.tableObject, "Roulette_Wheel"))
    local ballObject = rouletteTable.ballObject
    if (not ballObject or not DoesEntityExist(ballObject)) then
        ballObject = CreateProp(`vw_prop_roulette_ball`, targetCoords, false, false, false)
        rouletteTable.ballObject = ballObject
    end
    SetEntityCoordsNoOffset(ballObject, targetCoords, false, false, false)
    SetEntityRotation(ballObject, 0.0, 0.0, heading + 90.0, 2, true)
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
    
    if not LocalRouletteTables[casinoId] then LocalRouletteTables[casinoId] = {} end
    LocalRouletteTables[casinoId][entityId] = {
        dealerPed = dealerPed,
        tableObject = tableObject,
        surfaceObject = surfaceObject,
        interacts = {},
        playAreas = {{},{},{},{}}
    }
    for i,v in pairs(LocalRouletteTables[casinoId][entityId].playAreas) do
        local playArea = LocalRouletteTables[casinoId][entityId].playAreas[i]
        local seatOffset = PLAY_AREA_OFFSETS[i].seatOffset
        playArea.surfaceObject = CreateProp(`prop_tennis_ball`, GetOffsetFromEntityInWorldCoords(surfaceObject, seatOffset.coords - vector3(0.0, 0.0, 0.05)), false, false, false)
        FreezeEntityPosition(playArea.surfaceObject, true)
        SetEntityHeading(playArea.surfaceObject, heading + seatOffset.rotation.z)
    end
    for i,playArea in pairs(LocalRouletteTables[casinoId][entityId].playAreas) do
        if i > 0 then
            LocalRouletteTables[casinoId][entityId].interacts[#LocalRouletteTables[casinoId][entityId].interacts + 1] = CreateInteraction({
                label = _L("interact_roulette"),
                coords = GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, 0.0, -0.8, 1.0),
                heading = heading,
            }, function(selected)
                AttemptSeatAtRouletteEntity(casinoId, entityId)
            end)
        end
    end
    SetTimeout(1000, function()
        AttemptSeatAtRouletteEntity(casinoId, entityId)
    end)
    -- AttemptSeatAtRouletteEntity(casinoId, entityId)
end

function DeleteRouletteEntity(casinoId, entityId)
    if not DoesRouletteEntityExist(casinoId, entityId) then return end
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    for i=1, #rouletteTable.interacts do
        DeleteInteraction(rouletteTable.interacts[i])
    end
    DeleteEntity(rouletteTable.dealerPed)
    DeleteEntity(rouletteTable.tableObject)
    DeleteEntity(rouletteTable.surfaceObject)
    DeleteEntity(rouletteTable.ballObject)
    for i, v in pairs(rouletteTable.playAreas) do  
        local playArea = rouletteTable.playAreas[i]
        DeleteEntity(playArea.surfaceObject)
    end
    LocalRouletteTables[casinoId][entityId] = nil
end

RegisterNUICallback("performRouletteAction", function(data, cb)
    local animations = {
        ["hit"] = { dict = "anim_casino_b@amb@casino@games@roulette@player", name = "request_card" },
        ["stand"] = { dict = "anim_casino_b@amb@casino@games@roulette@player", name = "decline_card_001" },
        ["double"] = { dict = "anim_casino_b@amb@casino@games@roulette@player", name = "place_bet_small" },
        ["split"] = { dict = "anim_casino_b@amb@casino@games@roulette@player", name = "place_bet_small" },
    }
    TriggerServerEvent("pickle_casinos:roulette:performAction", data.action)
    PlayRouletteAnimation(PlayerPedId(), {dict = animations[data.action].dict, name = animations[data.action].name}, {time = 1000})
    cb("ok")
end)

RegisterNUICallback("updateRouletteWagers", function(data, cb)
    TriggerServerEvent("pickle_casinos:roulette:updateRouletteWagers", data.data)
    cb("ok")
end)

RegisterNetEvent("pickle_casinos:roulette:updateMoney", function(money)
    if CurrentRouletteTable then
        CurrentRouletteTable.money = money
        SendNUIMessage({
            type = "updateRouletteMoney",
            money = money,
        })
    end
end)

RegisterNetEvent("pickle_casinos:roulette:updateSeatWager", function(casinoId, entityId, seatId, handId, wager)
    if not DoesRouletteEntityExist(casinoId, entityId) then return end
    if CurrentRouletteTable and CurrentRouletteTable.casinoId == casinoId and CurrentRouletteTable.entityId == entityId then
        if CurrentRouletteTable.seats[seatId].wagers then
            CurrentRouletteTable.seats[seatId].wagers[handId] = wager
        end
        SendNUIMessage({
            type = "updateRouletteSeats",
            seats = GetRouletteSeatsForUI(),
        })
    end
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    local playArea = rouletteTable.playAreas[seatId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local heading = casinoEntity.rotation.z
    local chipOffset = PLAY_AREA_OFFSETS[seatId].chips
    for i=1, #playArea.wagers[handId] do
        DeleteEntity(playArea.wagers[handId][i])
    end
    playArea.wagers[handId] = {}
    print(handId)
    local chips = GetCalculatedChips(wager)
    for i=1, #chips do
        local chip = chips[i]
        local chipObject = CreateProp(chip.model, GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, vector3((handId == 2 and 0.1 or 0.0), -0.12, 1 + (i - 1) * 0.0065)), false, false, false)
        FreezeEntityPosition(chipObject, true)
        SetEntityRotation(chipObject, 0.0, 0.0, heading + chipOffset.rotation.z, 2, true)
        table.insert(playArea.wagers[handId], chipObject)
    end
end)

RegisterNetEvent("pickle_casinos:roulette:updateSeatCards", function(casinoId, entityId, seatId, handId, cards, extraData)
    if not DoesRouletteEntityExist(casinoId, entityId) then return end
    local extraData = extraData or {}
    CurrentRouletteTable.seats[seatId].hands[handId] = cards
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    local playArea = rouletteTable.playAreas[seatId]
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
        local cardProp = CreateProp(GetCardModel(card.class, card.value), GetOffsetFromEntityInWorldCoords(playArea.surfaceObject, offset + ((extraData.isDouble and i == #cards) and vector3(0.018, 0.02, 0.0) or 0)), false, false, false)
        FreezeEntityPosition(cardProp, true)
        SetEntityRotation(cardProp, 0.0, (card.class == "hidden") and 180.0 or 0.0, (heading + cardOffset.rotation.z) + ((extraData.isDouble and i == #cards) and 90.0 or 0.0), 2, true)
        table.insert(playArea.hands[handId], cardProp)
    end
    SendNUIMessage({
        type = "updateRouletteSeats",
        seats = GetRouletteSeatsForUI(handId),
    })
end)

RegisterNetEvent("pickle_casinos:roulette:updateSeat", function(casinoId, entityId, seatId, seatData)
    if not DoesRouletteEntityExist(casinoId, entityId) then return end
    if CurrentRouletteTable and CurrentRouletteTable.casinoId == casinoId and CurrentRouletteTable.entityId == entityId then
        SendNUIMessage({
            type = "updateRouletteSeats",
            seats = GetRouletteSeatsForUI(),
        })
        CurrentRouletteTable.seats[seatId] = seatData
    end
    for i=1, 2 do
        TriggerEvent("pickle_casinos:roulette:updateSeatWager", casinoId, entityId, seatId, i, seatData.wagers[i])
        TriggerEvent("pickle_casinos:roulette:updateSeatCards", casinoId, entityId, seatId, i, seatData.hands[i])
    end
end)

function SetEntitySmoothRotation(entity, from, to, speed)
    local speed = speed or 4
    local progress = 0
    CreateThread(function()
        while progress < 100 do
            progress = progress + speed
            if progress > 100 then progress = 100 end
            local newCoords = lerp(from, to, progress / 100)
            SetEntityRotation(entity, newCoords, 2, true)
            Wait(10)
        end
    end)
end

RegisterNetEvent("pickle_casinos:roulette:performAction", function(casinoId, entityId, action)
    if not DoesRouletteEntityExist(casinoId, entityId) then return end
    local rouletteTable = LocalRouletteTables[casinoId][entityId]
    local isCurrentTable = (CurrentRouletteTable and CurrentRouletteTable.casinoId == casinoId and CurrentRouletteTable.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local dealerPed = rouletteTable.dealerPed
    if not rouletteTable.lastDealerRotation then
        rouletteTable.lastDealerRotation = casinoEntity.rotation + vector3(0.0, 0.0, 180.0)
    end
    local targetRotation = casinoEntity.rotation + vector3(0.0, 0.0, 180.0)
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
    local isCurrentTable = (CurrentRouletteTable and CurrentRouletteTable.casinoId == casinoId and CurrentRouletteTable.entityId == entityId)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    local dealerPed = rouletteTable.dealerPed
    if stage.type == "waiting" then
        CreateThread(function()
            while stage.time > 1 do
                stage.time = stage.time - 1
                if isCurrentTable then
                    SendNUIMessage({
                        type = "updateRouletteStage",
                        stage = {
                            type = "waiting",
                            time = stage.time,
                        }
                    })
                end
                Wait(1000)
            end
        end)
    elseif stage.type == "rolling" then
        SendNUIMessage({
            type = "updateRouletteStage",
            stage = {
                type = "rolling",
            }
        })
        PerformRouletteSpin(casinoId, entityId, stage.targetNumber)
    elseif stage.type == "winningNumber" then
        SendNUIMessage({
            type = "updateRouletteStage",
            stage = {
                type = "winningNumber",
                winningNumber = stage.winningNumber,
            }
        })
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