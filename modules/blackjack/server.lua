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
    entity.seats[1] = {source = source, wager = math.random(10000, 100000), cards = {}}
    SetTimeout(100 * 1, function()
        TriggerClientEvent("pickle_casinos:blackjack:updateSeatWager", -1, casinoId, entityId, 1, entity.seats[1].wager)
    end)
    ShowNotification(source, "You have joined the table at seat " .. seatId .. ".")
    if entity.stage.type == "waiting" then
        StartBlackjackGame(casinoId, entityId)
    end
end

function GetValueOfCards(cards)
    local value = 0
    local aces = 0
    for i=1, #cards do
        local card = cards[i]
        if card.class == "ace" then
            aces = aces + 1
        elseif card.value == "jack" or card.value == "queen" or card.value == "king" then
            value = value + 10
        else
            value = value + tonumber(card.value)
        end
    end
    for i=1, aces do
        if value + 11 <= 21 then
            value = value + 11
        else
            value = value + 1
        end
    end
    return value
end

function StartBlackjackGame(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if not entity.stage.type == "waiting" then return end
    local hiddenCard = GenerateCard()
    entity.seats[0] = {source = 0, cards = {}}
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
                    entity.stage = {type = "turn", seat = seat, hasHit = hasHit, action = nil}
                    TriggerClientEvent("pickle_casinos:blackjack:updateStage", -1, casinoId, entityId, entity.stage)
                    local timeLeft = 10
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

RegisterNetEvent("pickle_casinos:blackjack:performAction", function(action)
    local source = source
    local info = GetPlayerBlackjackInfo(source)
    if not info then return end
    local entity = GetCasinoEntity(info.casinoId, info.entityId)
    if not entity then return end
    if entity.stage.type ~= "turn" then return end
    entity.stage.action = action
end)    