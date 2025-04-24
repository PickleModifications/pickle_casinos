function InitializeCashierEntity(casinoId, data)
    local entity = data or { id = "ERR_NO_ID_SLOT" }
    return entity
end

RegisterCallback("pickle_casinos:getBalances", function(source, cb, casinoId, entityId)
    local money = GetMoney(source)
    local dirty = GetMoney(source, "dirty")
    local balance = 0
    local casinoBalance = 0
    local casinoMarkedBalance = 0
    local casino = Casinos[casinoId]
    if casino then
        balance = Inventory.GetItemCount(source, casino.settings.chipItem) or 0
        casinoBalance = casino.balance or 0
        casinoMarkedBalance = casino.marked_balance or 0
    end
    return cb({
        money = money,
        dirty = dirty,
        balance = balance,
        casinoBalance = casinoBalance,
        casinoMarkedBalance = casinoMarkedBalance,
    })
end)

RegisterNetEvent("pickle_casinos:casinoExchange", function(casinoId, entityId, exchangeType, param, param2)
    if exchangeType == "buy" then
        local currency = param
        local amount = tonumber(param2)
        if currency ~= "money" and currency ~= "dirty" then return end
        if not amount or amount <= 0 then return end
        local casino = Casinos[casinoId]
        if not casino then return end
        local currencyCash = GetMoney(source, currency)
        if currencyCash < amount then return end
        local exchangeRate = 100
        if currency == "money" then
            exchangeRate = casino.settings.moneyExchangeRate or 100
        elseif currency == "dirty" then
            exchangeRate = casino.settings.dirtyExchangeRate or 100
        end
        local multiplier = exchangeRate / 100
        local chips = math.floor(amount * multiplier)
        if chips <= 0 then return end
        RemoveMoney(source, amount, currency)
        if currency == "money" then
            casino.balance = (casino.balance or 0) + chips
        elseif currency == "dirty" then
            casino.marked_balance = (casino.marked_balance or 0) + chips
        end
        MySQL.Async.execute('UPDATE `pickle_casinos` SET balance = ?, marked_balance = ? WHERE id = ?', {
            casino.balance,
            casino.marked_balance,
            casinoId
        })
        Inventory.AddItem(source, casino.settings.chipItem, chips)
        TriggerClientEvent("pickle_casino:updateCasinoBalance", -1, casinoId, casino.balance, casino.marked_balance)
    elseif exchangeType == "sell" then
        print("S1")
        local amount = tonumber(param2)
        if not amount or amount <= 0 then return end
        print("S2")
        local casino = Casinos[casinoId]
        if not casino then return end
        print("S3")
        local chips = Inventory.GetItemCount(source, casino.settings.chipItem) or 0
        if chips < amount then return end
        print("S4")
        local casinoBalance = casino.balance or 0
        if amount > casinoBalance then return end
        print("S5")
        Inventory.RemoveItem(source, casino.settings.chipItem, amount)
        AddMoney(source, amount, "money")
        casino.balance = casinoBalance - amount
        MySQL.Async.execute('UPDATE `pickle_casinos` SET balance = ?, marked_balance = ? WHERE id = ?', {
            casino.balance,
            casino.marked_balance,
            casinoId
        })
        TriggerClientEvent("pickle_casino:updateCasinoBalance", -1, casinoId, casino.balance, casino.marked_balance)
    else
        return 
    end
end)