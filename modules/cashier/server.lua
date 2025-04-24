function InitializeCashierEntity(casinoId, data)
    local entity = data or { id = "ERR_NO_ID_SLOT" }
    return entity
end

RegisterServerCallback("pickle_casinos:getBalances", function(source, cb, casinoId, entityId)
    local cash = GetMoney(source)
    local dirty = GetMoney(source, "dirty")
    local balance = 0
    local casino = Casinos[casinoId]
    if casino then
        balance = Inventory.GetItemCount(source, casino.settings.chipItem) or 0
    end
    return {
        cash = cash,
        dirty = dirty,
        balance = balance,
    }
end)