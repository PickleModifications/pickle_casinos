local classes = {"spd", "club", "dia", "hrt"}
local values = {"02", "03", "04", "05", "06", "07", "08", "09", "10", "jack", "queen", "king", "ace"}

function EvaluatePokerHand(hand, community)
    local allCards = {}
    for _, card in ipairs(hand) do
        table.insert(allCards, card)
    end
    for _, card in ipairs(community) do
        table.insert(allCards, card)
    end

    -- Helper function to get card rank
    local function getCardRank(card)
        for i, value in ipairs(values) do
            if card.value == value then
                return i
            end
        end
        return 0
    end

    -- Helper function to get card suit
    local function getCardSuit(card)
        return card.class
    end

    -- Sort cards by rank
    table.sort(allCards, function(a, b)
        return getCardRank(a) > getCardRank(b)
    end)

    -- Check for flush
    local function isFlush(cards)
        if #cards < 5 then return false end
        local suits = {}
        for i=1, #cards do 
          local suit = getCardSuit(cards[i])
          suits[suit] = (suits[suit] or 0) + 1
        end
        for k,v in pairs(suits) do
          if v >= 5 then
            return true
          end
        end
    end

    -- Check for straight
    local function isStraight(cards)
        if #cards < 5 then return false end
    
        local ranks = {}
        for _, card in ipairs(cards) do
            local rank = getCardRank(card)
            table.insert(ranks, rank)
        end
    
        -- Function to get unique and sorted ranks
        local function getUniqueSortedRanks(rankList)
            local uniqueRanks = {}
            for _, rank in ipairs(rankList) do
                uniqueRanks[rank] = true
            end
            local sortedRanks = {}
            for rank in pairs(uniqueRanks) do
                table.insert(sortedRanks, rank)
            end
            table.sort(sortedRanks)
            return sortedRanks
        end
    
        local sortedRanks = getUniqueSortedRanks(ranks)
    
        if #sortedRanks < 5 then return false end
    
        -- Check for standard straights; track the highest qualifying window
        local bestHigh = nil
        for i = 1, #sortedRanks - 4 do
            if sortedRanks[i + 4] - sortedRanks[i] == 4 then
                local high = sortedRanks[i + 4]
                if bestHigh == nil or high > bestHigh then
                    bestHigh = high
                end
            end
        end
        if bestHigh then
            return { bestHigh }
        end
    
        -- Check for the special case of A-2-3-4-5 straight
        -- Ace is now at index 13 (#values); treat it as rank 1 for low-ace straight
        local uniqueRanksSet = {}
        for _, rank in ipairs(ranks) do
            uniqueRanksSet[rank] = true
        end
        -- Ace index = #values (13); low cards 2-5 have indices 1-4
        if uniqueRanksSet[#values] and uniqueRanksSet[1] and uniqueRanksSet[2] and uniqueRanksSet[3] and uniqueRanksSet[4] then
            return { 4 } -- high card is 5 (index 4) in A-2-3-4-5
        end
    
        return false
    end

    -- Evaluate for straight flush and royal flush first
    if #allCards >= 5 then
        local sameSuitCards = {}
        local suits = {}
        for _, card in ipairs(allCards) do
            if not suits[card.class] then
                suits[card.class] = {}
            end
            table.insert(suits[card.class], card)
        end

        for _, cardsOfSuit in pairs(suits) do
            if #cardsOfSuit >= 5 then
                table.sort(cardsOfSuit, function(a, b) return getCardRank(a) > getCardRank(b) end)
                local straightResult = isStraight(cardsOfSuit)
                if straightResult then
                    -- Royal flush: high card is ace, which is now at index #values
                    if straightResult[1] == #values then
                        return "royal_flush", straightResult
                    else
                        return "straight_flush", straightResult
                    end
                end
            end
        end
    end

    -- Evaluate hand (rest of the logic)
    local rankCounts = {}
    for _, card in ipairs(allCards) do
        local rank = card.value
        rankCounts[rank] = (rankCounts[rank] or 0) + 1
    end

    local cardPairs, threeOfKind, fourOfKind = {}, {}, {}
    for rank, count in pairs(rankCounts) do
        if count == 2 then
            table.insert(cardPairs, rank)
        elseif count == 3 then
            table.insert(threeOfKind, rank)
        elseif count == 4 then
            table.insert(fourOfKind, rank)
        end
    end

    -- Sort each group descending by card rank so highest is always at index [1]
    table.sort(threeOfKind, function(a, b)
        return getCardRank({ value = a }) > getCardRank({ value = b })
    end)
    table.sort(cardPairs, function(a, b)
        return getCardRank({ value = a }) > getCardRank({ value = b })
    end)
    table.sort(fourOfKind, function(a, b)
        return getCardRank({ value = a }) > getCardRank({ value = b })
    end)

    -- Handle double three-of-a-kind: treat highest as the set, second as the pair
    if #threeOfKind >= 2 then
        -- threeOfKind is already sorted descending; promote second entry to a pair
        local demoted = threeOfKind[2]
        table.remove(threeOfKind, 2)
        table.insert(cardPairs, 1, demoted) -- insert at front (it's the best available pair now)
    end

    if #fourOfKind > 0 then
        return "four_of_a_kind", { getCardRank({ value = fourOfKind[1] }) }
    elseif #threeOfKind > 0 and #cardPairs > 0 then
        return "full_house", { getCardRank({ value = threeOfKind[1] }), getCardRank({ value = cardPairs[1] }) }
    elseif isFlush(allCards) then
        local highCards = {}
        for _, card in ipairs(allCards) do
            table.insert(highCards, getCardRank(card))
        end
        return "flush", highCards
    elseif isStraight(allCards) then
        return "straight", {isStraight(allCards)[1]}
    elseif #threeOfKind > 0 then
        return "three_of_a_kind", { getCardRank({ value = threeOfKind[1] }) }
    elseif #cardPairs > 1 then
        return "two_pair", { getCardRank({ value = cardPairs[1] }), getCardRank({ value = cardPairs[2] }) }
    elseif #cardPairs > 0 then
        return "one_pair", { getCardRank({ value = cardPairs[1] }) }
    else
        local highCards = {}
        for _, card in ipairs(allCards) do
            table.insert(highCards, getCardRank(card))
        end
        return "high_card", highCards
    end
end

function GetPokerWinners(players, community)
    local results = {}
    for playerId, hand in pairs(players) do
        local rank, tiebreaker = EvaluatePokerHand(hand, community)
        results[playerId] = { rank = rank, tiebreaker = tiebreaker }
    end

    -- Determine the winner with tie-breaking logic
    local winners = {}
    local bestRank = nil
    local bestTiebreaker = nil

    local handRankings = {
        ["high_card"] = 1,
        ["one_pair"] = 2,
        ["two_pair"] = 3,
        ["three_of_a_kind"] = 4,
        ["straight"] = 5,
        ["flush"] = 6,
        ["full_house"] = 7,
        ["four_of_a_kind"] = 8,
        ["straight_flush"] = 9,
        ["royal_flush"] = 10,
    }

    for playerId, result in pairs(results) do
        local rankValue = handRankings[result.rank]
        if not bestRank or rankValue > bestRank then
            winners = { playerId }
            bestRank = rankValue
            bestTiebreaker = result.tiebreaker
        elseif rankValue == bestRank then
            local isTie = true
            -- Handle nil tiebreakers
            if not bestTiebreaker and result.tiebreaker then
                winners = { playerId }
                bestTiebreaker = result.tiebreaker
                isTie = false
            elseif bestTiebreaker and not result.tiebreaker then
                isTie = false -- Current best remains
            elseif bestTiebreaker and result.tiebreaker then
                local maxLen = math.max(#bestTiebreaker, #result.tiebreaker)
                for i = 1, maxLen do
                    local val1 = bestTiebreaker[i] or 0
                    local val2 = result.tiebreaker[i] or 0
                    if val2 > val1 then
                        winners = { playerId }
                        bestTiebreaker = result.tiebreaker
                        isTie = false
                        break
                    elseif val2 < val1 then
                        isTie = false
                        break
                    end
                end
            end
            if isTie then
                table.insert(winners, playerId)
            end
        end
    end

    return winners, results
end
