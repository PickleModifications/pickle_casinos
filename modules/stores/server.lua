function InitializeStoreEntity(casinoId, data)
    local entity = data or { id = "ERR_NO_ID_SLOT" }
    return entity
end

RegisterNetEvent("pickle_casinos:storePurchase", function(casinoId, entityId, itemIndex, amount)
    local casino = Casinos[casinoId]
    if not casino then return end
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casinoEntity then return end
    local storeCfg = Config.CreatorOptions.stores[casinoEntity.settings.store]
    if not storeCfg then 
        storeCfg = Config.CreatorOptions.stores[1]
    end
    if not storeCfg then return end
    local item = storeCfg.items[itemIndex]
    if not item then return end
    if amount <= 0 then return end
    local itemName = item.item
    local price = item.price * amount
    local money = GetMoney(source)
    if money < price then 
        return ShowNotification(_L("insufficient_funds"))
    end
    RemoveMoney(source, price)
    Inventory.AddItem(source, itemName, amount)
    ShowNotification(source, _L("store_purchase_success", NumberWithCommas(amount, true), GetItemLabel(item.item), NumberWithCommas(price)))
    local profit = math.floor(price * (Config.Casinos.profitPercent / 100))
    casino.balance = (casino.balance or 0) + profit
    AddCasinoTransaction(source, casinoId, "purchase", profit)
    MySQL.Async.execute('UPDATE `pickle_casinos` SET balance = ? WHERE id = ?', {
        casino.balance,
        casinoId
    })
    TriggerClientEvent("pickle_casinos:updateCasinoBalance", -1, casinoId, casino.balance, casino.marked_balance)
end)