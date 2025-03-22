function GetValueOfCards(cards)
    local value = 0
    local secondaryValue = 0
    local aces = 0
    for i=1, #cards do
        local card = cards[i]
        if card.value == "ace" then
            aces = aces + 1
            value = value + 1
        elseif card.value == "jack" or card.value == "queen" or card.value == "king" then
            value = value + 10
        else
            value = value + tonumber(card.value)
        end
    end
    if aces > 0 and value + 10 <= 21 then
        secondaryValue = value + 10
    end
    if secondaryValue == 21 then
        return 21, 0
    end
    return value, secondaryValue
end
