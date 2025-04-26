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
        if IsCasinoOwned(casinoId) then 
            casinoBalance = casino.balance or 0
            casinoMarkedBalance = casino.marked_balance or 0
        else
            casinoBalance = Config.MaximumChipPurchaseAmount
            casinoMarkedBalance = Config.MaximumChipPurchaseAmount
        end
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
        ShowNotification(source, _L("cashier_bought_chips", NumberWithCommas(chips, true), NumberWithCommas(amount), currency == "money" and _L("cashier_buy_currency_type_cash") or _L("cashier_buy_currency_type_dirty")))
        if IsCasinoOwned(casinoId) then 
            if currency == "money" then
                casino.balance = (casino.balance or 0) + amount
            elseif currency == "dirty" then
                casino.marked_balance = (casino.marked_balance or 0) + amount
            end
            MySQL.Async.execute('UPDATE `pickle_casinos` SET balance = ?, marked_balance = ? WHERE id = ?', {
                casino.balance,
                casino.marked_balance,
                casinoId
            })
            TriggerClientEvent("pickle_casinos:updateCasinoBalance", -1, casinoId, casino.balance, casino.marked_balance)
        end
        AddCasinoTransaction(source, casinoId, "deposit", amount)
        Inventory.AddItem(source, casino.settings.chipItem, chips)
    elseif exchangeType == "sell" then
        local amount = tonumber(param2)
        if not amount or amount <= 0 then return end
        local casino = Casinos[casinoId]
        if not casino then return end
        local chips = Inventory.GetItemCount(source, casino.settings.chipItem) or 0
        if chips < amount then return end
        local casinoBalance = casino.balance or 0
        if IsCasinoOwned(casinoId) then 
            if amount > casinoBalance then return end
            casino.balance = casinoBalance - amount
            MySQL.Async.execute('UPDATE `pickle_casinos` SET balance = ?, marked_balance = ? WHERE id = ?', {
                casino.balance,
                casino.marked_balance,
                casinoId
            })
            TriggerClientEvent("pickle_casinos:updateCasinoBalance", -1, casinoId, casino.balance, casino.marked_balance)
        end
        Inventory.RemoveItem(source, casino.settings.chipItem, amount)
        AddMoney(source, amount, "money")
        ShowNotification(source, _L("cashier_sold_chips", NumberWithCommas(amount, true), NumberWithCommas(amount), _L("cashier_buy_currency_type_cash")))
        AddCasinoTransaction(source, casinoId, "withdraw", amount)
    else
        return 
    end
end)

RegisterNetEvent("pickle_casinos:purchaseVIP", function(casinoId, entityId)
    local source = source
    local identifier = GetIdentifier(source)
    local casino = Casinos[casinoId]
    if not casino then return end
    local vipPrice = casino.settings.vipPrice or 0
    local money = GetMoney(source)
    if money < vipPrice then
        ShowNotification(source, _L("insufficient_funds"))
        return
    end
    for i=1, #casino.vip_players do 
        local vipPlayer = casino.vip_players[i]
        if vipPlayer.identifier == identifier then
            ShowNotification(source, _L("cashier_vip_already_owned"))
            return
        end
    end
    ShowNotification(source, _L("cashier_vip_bought", NumberWithCommas(vipPrice)))
    RemoveMoney(source, vipPrice)
    table.insert(casino.vip_players, { identifier = identifier, name = GetPlayerCharacterName(source) })
    MySQL.Async.execute('UPDATE `pickle_casinos` SET vip_players = ? WHERE id = ?', {
        json.encode(casino.vip_players),
        casinoId
    })
    if IsCasinoOwned(casinoId) then 
        casino.balance = (casino.balance or 0) + vipPrice
        MySQL.Async.execute('UPDATE `pickle_casinos` SET balance = ? WHERE id = ?', {
            casino.balance,
            casinoId
        })
        TriggerClientEvent("pickle_casinos:updateCasinoBalance", -1, casinoId, casino.balance, casino.marked_balance)
    end
    AddCasinoTransaction(source, casinoId, "vip", vipPrice)
    TriggerClientEvent("pickle_casinos:updateCasinoVIP", -1, casinoId, casino.vip_players)
end)