function GetBaccaratCardsValue(cards)
    local totalNumber = 0
    for i=1, #cards do
        local card = cards[i]
        if card.value == "ace" then
            totalNumber = totalNumber + 1
        elseif card.value == "jack" or card.value == "queen" or card.value == "king" then
            totalNumber = totalNumber + 10
        else
            totalNumber = totalNumber + tonumber(card.value)
        end
    end
    return totalNumber % 10
end