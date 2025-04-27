local classes = {"spd", "club", "dia", "hrt"}
local values = {"ace", "02", "03", "04", "05", "06", "07", "08", "09", "10", "jack", "queen", "king"}

local function EvaluatePokerHand(hand, community)
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

    -- Sort cards by rank
    table.sort(allCards, function(a, b)
        return getCardRank(a) > getCardRank(b)
    end)

    -- Evaluate hand (simplified for demonstration)
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

    if #fourOfKind > 0 then
        return "four_of_a_kind", { getCardRank({ value = fourOfKind[1] }) }
    elseif #threeOfKind > 0 and #cardPairs > 0 then
        return "full_house", { getCardRank({ value = threeOfKind[1] }), getCardRank({ value = cardPairs[1] }) }
    elseif #threeOfKind > 0 then
        return "three_of_a_kind", { getCardRank({ value = threeOfKind[1] }) }
    elseif #cardPairs > 1 then
        table.sort(cardPairs, function(a, b) return getCardRank({ value = a }) > getCardRank({ value = b }) end)
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

local function GetPokerWinners(players, community)
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
        ["full_house"] = 5,
        ["four_of_a_kind"] = 6,
    }

    for playerId, result in pairs(results) do
        local rankValue = handRankings[result.rank]
        if not bestRank or rankValue > bestRank then
            winners = { playerId }
            bestRank = rankValue
            bestTiebreaker = result.tiebreaker
        elseif rankValue == bestRank then
            local isTie = true
            for i = 1, #result.tiebreaker do
                if not bestTiebreaker[i] or result.tiebreaker[i] > bestTiebreaker[i] then
                    winners = { playerId }
                    bestTiebreaker = result.tiebreaker
                    isTie = false
                    break
                elseif result.tiebreaker[i] < bestTiebreaker[i] then
                    isTie = false
                    break
                end
            end
            if isTie then
                table.insert(winners, playerId)
            end
        end
    end
    
    return winners, results
end

-- local winners, results = GetPokerWinners(players, communityCards)
-- print("Winner:", table.concat(winners, ", "))
-- for playerId, result in pairs(results) do
--     print(playerId, "has", result.rank, "with tiebreaker", table.concat(result.tiebreaker, ", "))
-- end