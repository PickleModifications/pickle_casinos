local PokerLobbies = {}

function DoesPokerLobbyExist(casinoId, entityId)
    if not casinoId or not entityId then return end
    if not PokerLobbies[casinoId] then return end
    if not PokerLobbies[casinoId][entityId] then return end
    return PokerLobbies[casinoId][entityId]
end

function GenerateDefaultPokerSeat(source, casinoId, entityId)
    local casinoBalance = GetCasinoChips(source, casinoId)
    local entity = GetCasinoEntity(casinoId, entityId)
    if not source or not entity then return {source = nil, cards = {}, name = "ERR_UNKNOWN", inSeat = false, balance = 0} end
    local maxBalance = entity.settings.bigBlind * 100
    local balance = GetCasinoChips(source, casinoId)
    if balance > maxBalance then
        balance = maxBalance
    end
    return {source = source, cards = {}, blind = "none", name = GetPlayerCharacterName(source), balance = balance, inSeat = true}
end

function JoinPokerEntity(source, casinoId, entityId, seatId)
    local seatId = seatId or 1
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if CurrentPlayers[source] then
        for i=1, #entity.seats do
            if entity.seats[i].source == source then
                entity.seats[seatId].inSeat = true
                return i
            end
        end
        ShowNotification(source, "You are already playing another casino game.")
        return
    end
    if entity.seats[seatId].source then
        seatId = nil
        for i=1, #entity.seats do
            if entity.seats[i].source == nil then
                seatId = i
                break
            end
        end
        if not seatId then
            ShowNotification(source, "There are no available seats at this table.")
            return 
        end
    end
    local newSeat = GenerateDefaultPokerSeat(source, casinoId, entityId)
    if newSeat.balance < entity.settings.bigBlind then
        ShowNotification(source, "You do not have enough chips to join this table.")
        return
    end
    entity.seats[seatId] = newSeat
    RemoveCasinoChips(source, casinoId, entity.seats[seatId].balance)
    CurrentPlayers[source] = {casinoId = casinoId, entityId = entityId, seatId = seatId}
    if not DoesPokerLobbyExist(casinoId, entityId) then
        StartPokerLobby(casinoId, entityId)
    end
    SetTimeout(100 * 1, function()
        TriggerClientEvent("pickle_casinos:poker:updateSeat", -1, casinoId, entityId, seatId, entity.seats[seatId])
    end)
    ShowNotification(source, "You have joined the table at seat " .. seatId .. ".")
    return seatId
end

function InitializePokerEntity(casinoId, data, dataOnly)
    local entity = data or { id = "ERR_NO_ID_POKER" }
    entity.seats = {}
    entity.dealerCards = {}
    for i=1, 10 do
        entity.seats[i] = GenerateDefaultPokerSeat()
    end
    -- for i=1, 1 do
    --     if i ~= 8 then
    --         entity.seats[i].source = i + 1000
    --         entity.seats[i].name = "Bot #" .. i
    --         entity.seats[i].balance = 10000
    --         entity.seats[i].inSeat = true
    --     end
    -- end
    return entity
end

function GetPlayerPokerInfo(source)
    if not source or source < 1 then return end
    for k,v in pairs(Casinos) do
        for i=1, #v.entities do
            local entity = v.entities[i]
            if entity.type == "poker" and entity.id == Casinos[k].entities[i].id then
                for j=1, #entity.seats do
                    if entity.seats[j].source == source then
                        return {casinoId = k, entityId = entity.id, seatId = j}
                    end
                end
            end
        end
    end
end

function TriggerReclusiveClientEvent(eventName, source, ...)
    for _, playerId in ipairs(GetPlayers()) do
        if tonumber(source) ~= tonumber(playerId) then
            TriggerClientEvent(eventName, playerId, ...)
        end
    end
end

function GetObfuscuatedSeat(seat)
    local obfuscatedSeat = {}
    for k,v in pairs(seat) do
        if k == "cards" then
            obfuscatedSeat.cards = {}
            for i=1, #v do
                obfuscatedSeat.cards[i] = { class = "hidden", value = 0 }
            end
        else
            obfuscatedSeat[k] = v
        end
    end
    if obfuscatedSeat.cards then
        for i=1, #obfuscatedSeat.cards do
            if obfuscatedSeat.cards[i] then
                obfuscatedSeat.cards[i].class = "hidden"
                obfuscatedSeat.cards[i].value = 0
            end
        end
    end
    return obfuscatedSeat
end

function GetObfuscuatedSeats(seats, winners)
    local obfuscatedSeats = {}
    for i=1, #seats do
        local isWinner = false
        if winners then
            for j=1, #winners do
                if winners[j] == i then
                    isWinner = true
                    break
                end
            end
        end
        if not isWinner then
            obfuscatedSeats[i] = GetObfuscuatedSeat(seats[i])
        else
            obfuscatedSeats[i] = seats[i]
        end
    end
    return obfuscatedSeats
end

function StartPokerGame(casinoId, entityId)
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local round = 0
    local smallBlind = entity.settings.smallBlind or 1
    local bigBlind = entity.settings.bigBlind or 2
    entity.pot = 0
    entity.dealerCards = {}
    local lastButtonIndex = #entity.seats
    local smallBlindIndex = lastButtonIndex
    local deck = GenerateDeck()
    repeat 
        smallBlindIndex = smallBlindIndex + 1
        if smallBlindIndex > #entity.seats then
            smallBlindIndex = 1
        end
    until entity.seats[smallBlindIndex].source
    local bigBlindIndex = smallBlindIndex
    repeat 
        bigBlindIndex = bigBlindIndex + 1
        if bigBlindIndex > #entity.seats then
            bigBlindIndex = 1
        end
    until entity.seats[bigBlindIndex].source and bigBlindIndex ~= smallBlindIndex
    entity.seats[smallBlindIndex].blind = "small"
    entity.seats[smallBlindIndex].balance = entity.seats[smallBlindIndex].balance - smallBlind
    entity.seats[bigBlindIndex].blind = "big"
    entity.seats[bigBlindIndex].balance = entity.seats[bigBlindIndex].balance - bigBlind
    entity.seats[smallBlindIndex].totalWager = (entity.seats[smallBlindIndex].totalWager or 0) + smallBlind
    entity.seats[bigBlindIndex].totalWager = (entity.seats[bigBlindIndex].totalWager or 0) + bigBlind
    -- debugPrint("Small Blind: " .. smallBlindIndex .. " Big Blind: " .. bigBlindIndex)
    entity.pot = smallBlind + bigBlind
    TriggerClientEvent("pickle_casinos:poker:updateSeats", -1, casinoId, entityId, entity.seats)
    TriggerClientEvent("pickle_casinos:poker:updatePot", -1, casinoId, entityId, entity.pot)
    local seatOrder = {}
    local currentSeat = bigBlindIndex
    entity.stage = {type = "dealing", time = 0, seat = bigBlindIndex, minimumBet = 0}
    repeat
        if entity.seats[currentSeat].source then
            entity.seats[currentSeat].playing = true
            seatOrder[#seatOrder + 1] = currentSeat
        end
        currentSeat = currentSeat + 1
        if currentSeat > #entity.seats then
            currentSeat = 1
        end
    until currentSeat == bigBlindIndex
    CreateThread(function()
        repeat
            round = round + 1
            for i=1, #seatOrder do
                local seatId = seatOrder[i]
                local card, updatedDeck = GenerateCard(deck)
                deck = updatedDeck
                entity.seats[seatId].cards[round] = card
                TriggerReclusiveClientEvent("pickle_casinos:poker:updateStage", entity.seats[seatId].source, casinoId, entityId, {type = "dealing", seat = seatId, card = { class = "hidden", value = 0 }})
                TriggerClientEvent("pickle_casinos:poker:updateStage", entity.seats[seatId].source, casinoId, entityId, {type = "dealing", seat = seatId, card = card})
                SetTimeout(1200, function()
                    debugPrint(json.encode(entity.seats[seatId].cards))
                    TriggerReclusiveClientEvent("pickle_casinos:poker:updateSeat", entity.seats[seatId].source, casinoId, entityId, seatId, GetObfuscuatedSeat(entity.seats[seatId]))
                    TriggerClientEvent("pickle_casinos:poker:updateSeat", entity.seats[seatId].source, casinoId, entityId, seatId, entity.seats[seatId])
                end)
                Wait(1300)
            end
        until round >= 2
        local currentRound = {
            active = true,
            section = "preflop",
            highestBet = 0,
            seatBets = {},
            actionSeat = seatOrder[1],
        }
        repeat
            local totalSeats = 0
            local totalPlayers = 0
            currentRound.active = true
            for i=1, #seatOrder do
                local seatId = seatOrder[i]
                local seat = entity.seats[seatId]
                if not (entity.seats[currentSeat].all or entity.seats[currentSeat].fold) then
                    totalSeats = totalSeats + 1
                end
                if not (seat.fold) then
                    totalPlayers = totalPlayers + 1
                end
            end
            print("Total Seats: " .. totalSeats, "Total Players: " .. totalPlayers)
            if totalSeats <= 1 then
                currentRound.active = false
            end
            if totalPlayers <= 1 then
                currentRound.active = false
                break
            else
                local dealCardSections = {
                    ["flop"] = 3,
                    ["turn"] = 1,
                    ["river"] = 1,
                }
                if dealCardSections[currentRound.section] then
                    local cardCount = dealCardSections[currentRound.section]
                    for i=1, cardCount do
                        local index = #entity.dealerCards + 1
                        local card, updatedDeck = GenerateCard(deck)
                        deck = updatedDeck
                        entity.dealerCards[index] = card
                        entity.stage = {type = "dealerDealing", index = index, card = entity.dealerCards[index]}
                        TriggerClientEvent("pickle_casinos:poker:updateStage", -1, casinoId, entityId, entity.stage)
                        SetTimeout(1400, function()
                            TriggerClientEvent("pickle_casinos:poker:updateDealerCards", -1, casinoId, entityId, entity.dealerCards)
                        end)
                        Wait(1500)
                    end
                end
            end
            if currentRound.active then
                local allSeatsPlayed = false
                local roundRepeat = false
                while currentRound.active do
                    for i=1, #seatOrder do
                        local currentSeat = seatOrder[i]
                        debugPrint("TOTAL WAGER: " .. (entity.seats[currentSeat].totalWager or 0),"SEAT ID: " .. currentSeat)
                        local skipTurn = false
                        if allSeatsPlayed and currentRound.actionSeat == currentSeat then
                            currentRound.active = false
                            skipTurn = true
                            break
                        end
                        if entity.seats[currentSeat].all or entity.seats[currentSeat].fold then
                            skipTurn = true
                        end
                        if not skipTurn then
                            local minimumBet = 0
                            if entity.seats[currentSeat].blind == "small" then
                                minimumBet = currentRound.highestBet
                            elseif entity.seats[currentSeat].blind == "big" then
                                minimumBet = currentRound.highestBet
                            else
                                minimumBet = currentRound.highestBet
                            end
                            minimumBet = minimumBet - (currentRound.seatBets[currentSeat] or 0)
                            if minimumBet < 0 then minimumBet = 0 end
                            debugPrint("Minimum Bet: " .. minimumBet, "Highest Bet: " .. currentRound.highestBet, "SEAT INFO:", currentSeat, currentRound.seatBets[currentSeat])
                            entity.seats[currentSeat].action = nil
                            TriggerClientEvent("pickle_casinos:poker:updateSeatAction", -1, casinoId, entityId, currentSeat, entity.seats[currentSeat].action)
                            entity.stage = {type = "seatTurn", time = Config.SeatTurnTime, seat = currentSeat, minimumBet = minimumBet}
                            TriggerClientEvent("pickle_casinos:poker:updateStage", -1, casinoId, entityId, entity.stage)
                            for i=1, Config.SeatTurnTime + 1 do 
                                if entity.seats[currentSeat].action then break end
                                Wait(1000)
                            end
                            
                            if not entity.seats[currentSeat].action then
                                entity.seats[currentSeat].action = {type = "fold", amount = 0, wagered = 0}
                            end
                            if entity.seats[currentSeat].action.type == "fold" and minimumBet <= 0 then
                                entity.seats[currentSeat].action = {type = "check", amount = 0, wagered = 0}
                            end
                            if entity.seats[currentSeat].action.type == "check" and minimumBet > 0 and (currentRound.seatBets[currentSeat] == nil or currentRound.seatBets[currentSeat] < minimumBet) then
                                entity.seats[currentSeat].action = {type = "call", amount = 0, wagered = 0}
                            end
                            if entity.seats[currentSeat].action.type == "call" then
                                local deductedAmount = minimumBet
                                if entity.seats[currentSeat].balance - deductedAmount < 0 then
                                    entity.seats[currentSeat].action = {type = "all"}
                                else
                                    entity.seats[currentSeat].totalWager = (entity.seats[currentSeat].totalWager or 0) + deductedAmount
                                    entity.seats[currentSeat].balance = entity.seats[currentSeat].balance - deductedAmount
                                    entity.seats[currentSeat].action = {type = "call", amount = minimumBet, wagered = 0}
                                    entity.pot = entity.pot + deductedAmount
                                end
                            end
                            if entity.seats[currentSeat].action.type == "raise" then
                                local amount = entity.seats[currentSeat].action.amount or 0
                                if amount < (minimumBet + smallBlind) then
                                    amount = minimumBet + smallBlind
                                end
                                local deductedAmount = amount
                                if entity.seats[currentSeat].balance - amount <= smallBlind then
                                    entity.seats[currentSeat].action = {type = "all"}
                                else
                                    currentRound.actionSeat = currentSeat
                                    currentRound.highestBet = amount
                                    entity.seats[currentSeat].totalWager = (entity.seats[currentSeat].totalWager or 0) + deductedAmount
                                    entity.seats[currentSeat].action = {type = "raise", amount = amount, wagered = 0}
                                    entity.seats[currentSeat].balance = entity.seats[currentSeat].balance - deductedAmount
                                    currentRound.seatBets[currentSeat] = amount
                                    entity.pot = entity.pot + deductedAmount
                                end
                            end
                            if entity.seats[currentSeat].action.type == "all" then
                                currentRound.actionSeat = currentSeat
                                entity.pot = entity.pot + entity.seats[currentSeat].balance
                                entity.seats[currentSeat].all = true
                                entity.seats[currentSeat].action.amount = (entity.seats[currentSeat].totalWager or 0) + entity.seats[currentSeat].balance
                                entity.seats[currentSeat].balance = 0
                                if entity.seats[currentSeat].action.amount > currentRound.highestBet then
                                    currentRound.highestBet = entity.seats[currentSeat].action.amount
                                end
                            end
                            if entity.seats[currentSeat].action.type == "fold" then
                                entity.seats[currentSeat].fold = true
                            elseif entity.seats[currentSeat].action.type == "raise" or entity.seats[currentSeat].action.type == "all" then
                                roundRepeat = true
                            end
                            -- TriggerClientEvent("pickle_casinos:poker:updateSeat", -1, casinoId, entityId, currentSeat, GetObfuscuatedSeat(entity.seats[currentSeat]))
                            debugPrint(currentSeat, json.encode(entity.seats[currentSeat].action))
                            TriggerClientEvent("pickle_casinos:poker:updateSeatAction", -1, casinoId, entityId, currentSeat, entity.seats[currentSeat].action, entity.seats[currentSeat].balance)
                            TriggerClientEvent("pickle_casinos:poker:updatePot", -1, casinoId, entityId, entity.pot)
                        
                        end
                    end
                    allSeatsPlayed = true
                end
            end
            currentRound.highestBet = 0
            currentRound.seatBets = {}
            currentRound.actionSeat = seatOrder[1]
            if currentRound.section == "preflop" then
                currentRound.section = "flop"
            elseif currentRound.section == "flop" then
                currentRound.section = "turn"
            elseif currentRound.section == "turn" then
                currentRound.section = "river"
            else
                currentRound.section = "end"
            end
        until currentRound.section == "end"
        local formattedPlayerCards = {}
        for i=1, #entity.seats do
            if entity.seats[i].source and not entity.seats[i].fold then
                formattedPlayerCards[i] = {}
                for j=1, #entity.seats[i].cards do
                    formattedPlayerCards[i][j] = { class = entity.seats[i].cards[j].class, value = entity.seats[i].cards[j].value }
                end
            end
        end
        local winners, results = GetPokerWinners(formattedPlayerCards, entity.dealerCards)
        debugPrint("Round Ended", json.encode(winners), json.encode(results))

        local totalPot = entity.pot
        local winnings = {}
        local totalContributions = 0

        -- Calculate total contributions of winners
        for _, seatId in ipairs(winners) do
            totalContributions = totalContributions + (entity.seats[seatId].totalWager or 0)
        end

        -- Distribute winnings proportionally based on contributions
        for _, seatId in ipairs(winners) do
            local contribution = entity.seats[seatId].totalWager or 0
            local share = (contribution / totalContributions) * totalPot
            winnings[seatId] = share
            entity.seats[seatId].balance = entity.seats[seatId].balance + share
            debugPrint(string.format("Player %d won: %.2f (Contribution: %.2f, Total Pot: %.2f, New Balance: %.2f)",
                seatId, share, contribution, totalPot, entity.seats[seatId].balance))
        end
        for i=1, #entity.seats do
            if entity.seats[i].source then
                local visibleSeats = { i }
                for j=1, #winners do
                    if winners[j] ~= i then
                        visibleSeats[#visibleSeats + 1] = winners[j]
                    end 
                end
                local seats = GetObfuscuatedSeats(entity.seats, winners)
                seats[i].cards = entity.seats[i].cards
                entity.stage = {type = "results", winnings = winnings, seats = seats}
                TriggerClientEvent("pickle_casinos:poker:updateStage", -1, casinoId, entityId, entity.stage)
            end
        end

        -- Reset the pot
        entity.pot = 0
        -- Reset seat data
        for i=1, #entity.seats do
            entity.seats[i].action = nil
            entity.seats[i].fold = nil
            entity.seats[i].all = nil
            entity.seats[i].playing = nil
            entity.seats[i].blind = "none"
            entity.seats[i].totalWager = 0
            entity.seats[i].cards = {}
            if entity.seats[i].source and entity.seats[i].balance < (entity.settings.bigBlind * 100) then
                local replenishAmount = (entity.settings.bigBlind * 100) - entity.seats[i].balance
                local casinoBalance = GetCasinoChips(entity.seats[i].source, casinoId)
                if casinoBalance >= 0 then
                    if casinoBalance >= replenishAmount then
                        RemoveCasinoChips(entity.seats[i].source, casinoId, replenishAmount)
                        entity.seats[i].balance = entity.seats[i].balance + replenishAmount
                    else
                        RemoveCasinoChips(entity.seats[i].source, casinoId, casinoBalance)
                        entity.seats[i].balance = entity.seats[i].balance + casinoBalance
                    end
                end
            end
        end
        entity.dealerCards = {}
        Wait(5000)
        TriggerClientEvent("pickle_casinos:poker:updateSeats", -1, casinoId, entityId, entity.seats)
        TriggerClientEvent("pickle_casinos:poker:updateDealerCards", -1, casinoId, entityId, entity.dealerCards)
        TriggerClientEvent("pickle_casinos:poker:updatePot", -1, casinoId, entityId, entity.pot)
        -- Start a new poker lobby
        StartPokerLobby(casinoId, entityId)
    end)
end

function LeavePokerEntity(source, casinoId, entityId, seatId)
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local source = entity.seats[seatId].source
    if entity.seats[seatId].balance > 0 then
        AddCasinoChips(source, casinoId, entity.seats[seatId].balance)
    end
    entity.seats[seatId] = GenerateDefaultPokerSeat()
    CurrentPlayers[source] = nil
    TriggerClientEvent("pickle_casinos:poker:updateSeat", -1, casinoId, entityId, seatId, entity.seats[seatId])
end

function StartPokerLobby(casinoId, entityId)
    PokerLobbies[casinoId] = PokerLobbies[casinoId] or {}
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local totalPlayers = 0
    for i=1, #entity.seats do
        if entity.seats[i].source then
            if entity.seats[i].inSeat and entity.seats[i].balance >= entity.settings.bigBlind then
                totalPlayers = totalPlayers + 1
            else
                if entity.seats[i].balance < entity.settings.bigBlind then
                    TriggerClientEvent("pickle_casinos:exitGame", entity.seats[i].source, true)
                end
                LeavePokerEntity(entity.seats[i].source, casinoId, entityId, i)
            end
        end
    end
    if totalPlayers <= 0 then
        PokerLobbies[casinoId] = PokerLobbies[casinoId] or {}
        PokerLobbies[casinoId][entityId] = false
        return
    else
        PokerLobbies[casinoId][entityId] = true
    end
    entity.stage = {type = "waiting", time = Config.WaitingTime}
    TriggerClientEvent("pickle_casinos:poker:updateStage", -1, casinoId, entityId, entity.stage)
    CreateThread(function()
        while entity.stage.type == "waiting" and entity.stage.time > 1 do
            entity.stage.time = entity.stage.time - 1
            Wait(1000)
        end
        local totalPlayers = 0
        for i=1, #entity.seats do
            if entity.seats[i].source and entity.seats[i].inSeat then
                totalPlayers = totalPlayers + 1
            end
        end
        if totalPlayers < 2 then
            StartPokerLobby(casinoId, entityId)
        else
            StartPokerGame(casinoId, entityId)
        end
    end)
end

RegisterNetEvent("pickle_casinos:poker:sendPokerAction", function(betType, value)
    local playerInfo = GetPlayerPokerInfo(source)
    if not playerInfo then return end
    local casinoId = playerInfo.casinoId
    local entityId = playerInfo.entityId
    local seatId = playerInfo.seatId
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if not entity.seats[seatId] then return end
    if not entity.seats[seatId].playing then return end
    if entity.stage.type ~= "seatTurn" or entity.stage.seat ~= seatId then return end
    if betType == "call" then
        entity.seats[seatId].action = {type = "call", amount = value, wagered = 0}
    elseif betType == "raise" then
        entity.seats[seatId].action = {type = "raise", amount = value, wagered = 0}
    elseif betType == "fold" then
        entity.seats[seatId].action = {type = "fold", amount = 0, wagered = 0}
    elseif betType == "check" then
        entity.seats[seatId].action = {type = "check", amount = 0, wagered = 0}
    elseif betType == "all" then
        entity.seats[seatId].action = {type = "all", amount = value, wagered = 0}
    end
end)

RegisterNetEvent("pickle_casinos:poker:leaveTable", function()
    local source = source
    local playerInfo = GetPlayerPokerInfo(source)
    if not playerInfo then return end
    local casinoId = playerInfo.casinoId
    local entityId = playerInfo.entityId
    local seatId = playerInfo.seatId
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if entity.stage.type == "waiting" then
        LeavePokerEntity(source, casinoId, entityId, seatId)
    else
        entity.seats[seatId].inSeat = false
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    local playerInfo = GetPlayerPokerInfo(source)
    if not playerInfo then return end
    local casinoId = playerInfo.casinoId
    local entityId = playerInfo.entityId
    local seatId = playerInfo.seatId
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    LeavePokerEntity(source, casinoId, entityId, seatId)
end)

RegisterCallback("pickle_casinos:poker:requestSeat", function(source, cb, casinoId, entityId, seatId)
    local seatId = JoinPokerEntity(source, casinoId, entityId, seatId)
    local entity = GetCasinoEntity(casinoId, entityId)
    if seatId then
        return cb(seatId, {
            id = entity.id,
            seats = GetObfuscuatedSeats(entity.seats),
            stage = entity.stage,
            money = entity.seats[seatId].balance,
        })
    end
    cb(seatId)
end)