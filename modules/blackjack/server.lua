function JoinBlackjackEntity(source, casinoId, entityId, seatId)
    local seatId = seatId or 1
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if entity.seats[seatId] then
        for i=1, #entity.seats do
            if not entity.seats[i] then
                seatId = i
                break
            end
        end
        ShowNotification(source, "There are no available seats at this table.")
        return 
    end
    entity.seats[seatId] = {source = source, wager = math.random(10000, 100000), cards = {}}
    SetTimeout(100 * 1, function()
        TriggerClientEvent("pickle_casinos:blackjack:updateSeatWager", -1, casinoId, entityId, seatId, entity.seats[seatId].wager)
    end)
    ShowNotification(source, "You have joined the table at seat " .. seatId .. ".")
    if entity.stage.type == "waiting" then
        CreateThread(function()
            Wait(math.random(100, 500))
            StartBlackjackGame(casinoId, entityId)
        end)
    end
    return seatId
end

function StartBlackjackGame(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if entity.stage.type ~= "waiting" then return end
    local hiddenCard = GenerateCard()
    entity.seats[0] = {source = 0, cards = {}}
    print("STARTING BLACKJACK GAME")
    CreateThread(function()
        local round = 0
        repeat
            round = round + 1
            for k=1, 4 do
                if entity.seats[k] then
                    entity.stage = {type = "dealing", seat = k, card = GenerateCard() }
                    entity.seats[k].cards[#entity.seats[k].cards + 1] = entity.stage.card
                    TriggerClientEvent("pickle_casinos:blackjack:updateStage", -1, casinoId, entityId, entity.stage)
                    SetTimeout(1300, function()
                        TriggerClientEvent("pickle_casinos:blackjack:updateSeatCards", -1, casinoId, entityId, k, entity.seats[k].cards)
                    end)
                    Wait(2000)
                end
            end
            entity.stage = {type = "dealing", seat = 0, card = round == 1 and { class = "hidden", value = 0 } or GenerateCard()}
            entity.seats[0].cards[#entity.seats[0].cards + 1] = entity.stage.card
            TriggerClientEvent("pickle_casinos:blackjack:updateStage", -1, casinoId, entityId, entity.stage)
            SetTimeout(1300, function()
                TriggerClientEvent("pickle_casinos:blackjack:updateSeatCards", -1, casinoId, entityId, 0, entity.seats[0].cards)
            end)
            Wait(2000)
        until round == 2
        local seat = 0
        repeat
            seat = seat + 1
            if entity.seats[seat] then
                local done = false
                local hasHit = false
                repeat
                    entity.stage = {type = "turn", seat = seat, hasHit = hasHit, action = nil, cards = entity.seats[seat].cards}
                    TriggerClientEvent("pickle_casinos:blackjack:updateStage", -1, casinoId, entityId, entity.stage)
                    local timeLeft = 11
                    repeat
                        local entity2 = GetCasinoEntity(casinoId, entityId)
                        print("WAITING", timeLeft, entity.stage.action, entity.stage.seat, entity2.stage.action)
                        timeLeft = timeLeft - 1
                        Wait(1000)
                    until timeLeft == 0 or entity.stage.action ~= nil
                    local action = entity.stage.action or "stand"
                    if action == "hit" then
                        entity.stage = {type = "dealing", seat = seat, isHit = true, card = GenerateCard()}
                        entity.seats[seat].cards[#entity.seats[seat].cards + 1] = entity.stage.card
                        hasHit = true
                        local value = GetValueOfCards(entity.seats[seat].cards)
                        TriggerClientEvent("pickle_casinos:blackjack:updateStage", -1, casinoId, entityId, entity.stage)
                        SetTimeout(1300, function()
                            TriggerClientEvent("pickle_casinos:blackjack:updateSeatCards", -1, casinoId, entityId, seat, entity.seats[seat].cards)
                        end)
                        Wait(2000)
                        if value >= 21 then
                            done = true
                        end
                    else
                        done = true
                    end
                until done
            end
        until seat >= 4
        entity.stage = {type = "displayCard", seat = 0, card = hiddenCard}
        entity.seats[0].cards[1] = entity.stage.card
        TriggerClientEvent("pickle_casinos:blackjack:updateStage", -1, casinoId, entityId, entity.stage)
        Wait(2000)
        if GetValueOfCards(entity.seats[0].cards) < 17 then
            repeat
                entity.stage = {type = "dealing", seat = 0, card = GenerateCard()}
                entity.seats[0].cards[#entity.seats[0].cards + 1] = entity.stage.card
                TriggerClientEvent("pickle_casinos:blackjack:updateStage", -1, casinoId, entityId, entity.stage)
                SetTimeout(1300, function()
                    TriggerClientEvent("pickle_casinos:blackjack:updateSeatCards", -1, casinoId, entityId, 0, entity.seats[0].cards)
                end)
                print(json.encode(entity.seats[0].cards))
                Wait(2000)
            until GetValueOfCards(entity.seats[0].cards) >= 17
        end
        local seat = 0
        repeat
            seat = seat + 1
            if entity.seats[seat] then
                entity.stage = {type = "cleanup", seat = seat}
                TriggerClientEvent("pickle_casinos:blackjack:updateStage", -1, casinoId, entityId, entity.stage)
                Wait(2000)
            end
        until seat >= 4
        entity.stage = {type = "cleanup", seat = 0}
        TriggerClientEvent("pickle_casinos:blackjack:updateStage", -1, casinoId, entityId, entity.stage)
        Wait(2000)
        for k,v in pairs(entity.seats) do
            entity.seats[k].cards = {}
        end
        entity.stage = {type = "waiting"}
        StartBlackjackGame(casinoId, entityId)
    end)
end

function InitializeBlackjackEntity(entity)
    local entity = entity or {}
    entity.stage = {type = "waiting"}
    entity.seats = {}
    return entity
end

function GetPlayerBlackjackInfo(source)
    if not source or source < 1 then return end
    for k,v in pairs(Casinos) do
        for i=1, #v.entities do
            local entity = v.entities[i]
            if entity.type == "blackjack" then
                for j, v in pairs(entity.seats) do
                    if entity.seats[j] and tonumber(entity.seats[j].source) == tonumber(source) then
                        return {casinoId = k, entityId = entity.id, seatId = j}
                    end
                end
            end
        end
    end
end

RegisterCallback("pickle_casinos:blackjack:requestSeat", function(source, cb, casinoId, entityId, seatId)
    cb(JoinBlackjackEntity(source, casinoId, entityId, seatId))
end)

RegisterNetEvent("pickle_casinos:blackjack:performAction", function(action)
    local source = source
    local info = GetPlayerBlackjackInfo(source)
    if not info then return end
    local entity = GetCasinoEntity(info.casinoId, info.entityId)
    if not entity then return end
    if entity.stage.type ~= "turn" then return end
    entity.stage.action = action
end)    