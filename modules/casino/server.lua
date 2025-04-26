CurrentPlayers = {}

function IsCasinoOwned(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return false end
    if casino.owner_info and casino.owner_info.identifier ~= "none" then return true end
    return false
end

function CanManageCasino(source, casinoId)
    if IsPlayerAdmin(source) then return true end
    if not casinoId then return false end
    local casino = Casinos[casinoId]
    if not casino then return false end
    if casino.owner_info and casino.owner_info.identifier == GetIdentifier(source) then return true end
    return false
end

function InitializeCasinoEntity(casinoId, entity, dataOnly)
    entity.settings = EnsureGameSettings(entity.type, entity.settings)
    if entity.type == "blackjack" then
        entity = InitializeBlackjackEntity(casinoId, entity, dataOnly)
    elseif entity.type == "roulette" then
        entity = InitializeRouletteEntity(casinoId, entity, dataOnly)
    elseif entity.type == "baccarat" then
        entity = InitializeBaccaratEntity(casinoId, entity, dataOnly)
    elseif entity.type == "slot" then
        entity = InitializeSlotEntity(casinoId, entity, dataOnly)
    elseif entity.type == "poker" then
        entity = InitializePokerEntity(casinoId, entity, dataOnly)
    elseif entity.type == "wheel" then
        entity = InitializeWheelEntity(casinoId, entity, dataOnly)
    elseif entity.type == "horseracing" then
        entity = InitializeHorseRacingEntity(casinoId, entity, dataOnly)
    elseif entity.type == "cashier" then
        entity = InitializeCashierEntity(casinoId, entity, dataOnly)
    elseif entity.type == "store" then
        entity = InitializeStoreEntity(casinoId, entity, dataOnly)
    end
    return entity
end

function InitializeCasinoEntities(casinoId, entities)
    for i=1, #entities do
        entities[i] = InitializeCasinoEntity(casinoId, entities[i])
    end
    return entities
end

function EnsureCasinoSettings(settings)
    local newSettings = {}
    for k,v in pairs(settings) do
        newSettings[k] = v
    end
    if not newSettings.label then newSettings.label = "UNKNOWN_LABEL" end
    if not newSettings.location then newSettings.location = { coords = vector3(0, 0, 0), rotation = vector3(0, 0, 0) } end
    newSettings.location.coords = vector3(newSettings.location.coords.x, newSettings.location.coords.y, newSettings.location.coords.z)
    newSettings.location.rotation = vector3(newSettings.location.rotation.x, newSettings.location.rotation.y, newSettings.location.rotation.z)
    if not newSettings.chipItem then newSettings.chipItem = "UNKNOWN_CHIP_ITEM" end
    if not newSettings.blipEnabled then newSettings.blipEnabled = false end
    if tonumber(newSettings.moneyExchangeRate or "a") == nil then newSettings.moneyExchangeRate = 100 end
    if tonumber(newSettings.dirtyExchangeRate or "a") == nil then newSettings.dirtyExchangeRate = 75 end
    if tonumber(newSettings.vipPrice or "a") == nil then newSettings.vipPrice = 1000 end
    return newSettings
end

function EnsureCasinoTransactions(transactions)
    local expireTime = os.time() - (86400 * 7)
    local newTransactions = {}
    for i=1, #transactions do
        local transaction = transactions[i]
        if transaction and transaction.datetime then
            if transaction.datetime > expireTime then
                table.insert(newTransactions, transaction)
            end
        end
    end
    return newTransactions
end

function RegisterCasino(id, data, dontSync)
    Casinos[id] = {
        id = id,
        balance = data.balance or 0,
        marked_balance = data.marked_balance or 0,
        owner_info = data.owner_info or nil,
        vip_players = data.vip_players or {},
        transactions = EnsureCasinoTransactions(data.transactions or {}),
        settings = EnsureCasinoSettings(data.settings),
        entities = InitializeCasinoEntities(id, data.entities or {})
    }
    if dontSync then return end
    TriggerClientEvent("pickle_casinos:registerCasino", -1, id, Casinos[id])
end

function JoinCasinoEntity(source, casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if entity.type == "blackjack" then
        JoinBlackjackEntity(source, casinoId, entityId)
    elseif entity.type == "roulette" then
        JoinRouletteEntity(source, casinoId, entityId)
    elseif entity.type == "baccarat" then
        JoinBaccaratEntity(source, casinoId, entityId)
    end
end

function GenerateCard() 
    local classes = {"spd", "club", "dia", "hrt"}
    local values = {"ace", "02", "03", "04", "05", "06", "07", "08", "09", "10", "jack", "queen", "king"}
    -- return { class = classes[1], value = values[1] }
    return { class = classes[math.random(1, #classes)], value = values[math.random(1, #values)] }
end

function GetCasinoEntity(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    for i=1, #casino.entities do
        if casino.entities[i].id == entityId then
            return casino.entities[i]
        end
    end
end

function SendCasinoEntityUpdate(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    TriggerClientEvent("pickle_casinos:updateCasinoEntity", -1, casinoId, entity)
end

function GenerateEntityId(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entityId
    repeat
        entityId = math.random(1, 9999999) .. "_" .. math.random(1, 9999999)
    until not GetCasinoEntity(casinoId, entityId)
    return entityId
end

function EnsureGameSettings(entityType, settings)
    local defaultSettings = {
        location = settings.location and {
            coords = vector3(settings.location.coords.x, settings.location.coords.y, settings.location.coords.z) or vector3(0, 0, 0),
            rotation = settings.location.rotation and vector3(settings.location.rotation.x, settings.location.rotation.y, settings.location.rotation.z) or vector3(0, 0, 0)
        } or {
            coords = vector3(0, 0, 0),
            rotation = vector3(0, 0, 0)
        },
        vip = settings.vip and true or false,
    }
    if entityType == "blackjack" or entityType == "roulette" or entityType == "baccarat" or entityType == "slot" or entityType == "wheel" or entityType == "horseracing" then
        defaultSettings["maxWager"] = settings.maxWager or 1000
    end
    if entityType == "blackjack" or entityType == "roulette" or entityType == "baccarat" or entityType == "poker" then
        defaultSettings["tableModel"] = settings.tableModel
        defaultSettings["dealerModel"] = settings.dealerModel
    end
    if entityType == "cashier" or entityType == "store" then
        defaultSettings["dealerModel"] = settings.dealerModel
    end
    if entityType == "store" then
        defaultSettings["store"] = settings.store or 1
    end
    if entityType == "slot" then
        defaultSettings["game"] = settings.game
    end
    if entityType == "poker" then
        defaultSettings["smallBlind"] = settings.smallBlind or 10
        defaultSettings["bigBlind"] = settings.bigBlind or 20
    end
    return defaultSettings
end

function UpdateCasinoEntitiesSQL(casinoId)
    local entities = {}
    for i=1, #Casinos[casinoId].entities do
        table.insert(entities, {
            id = Casinos[casinoId].entities[i].id,
            type = Casinos[casinoId].entities[i].type,
            settings = Casinos[casinoId].entities[i].settings,
        })
    end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET entities = ? WHERE id = ?', {json.encode(entities), casinoId})
end

function IsPlayerCasinoVIP(source, casinoId)
    local casino = Casinos[casinoId]
    if not casino then return false end
    local identifier = GetIdentifier(source)
    -- if casino.owner_info and casino.owner_info.identifier == identifier then return true end
    for i=1, #casino.vip_players do
        if casino.vip_players[i].identifier == identifier then
            return true
        end
    end
    return false
end

function AddCasinoTransaction(source, casinoId, transactionType, amount)
    local casino = Casinos[casinoId]
    if not casino then return end
    local transaction = {
        origin = {
            identifier = GetIdentifier(source),
            name = GetPlayerCharacterName(source),
        },
        type = transactionType,
        amount = amount,
        datetime = os.time(),
    }
    table.insert(casino.transactions, 1, transaction)
    MySQL.Async.execute('UPDATE `pickle_casinos` SET transactions = ? WHERE id = ?', {json.encode(casino.transactions), casinoId})
    TriggerClientEvent("pickle_casinos:updateCasinoTransactions", -1, casinoId, casino.transactions)
end

function GetCasinoChips(source, casinoId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local chips = Inventory.GetItemCount(source, casino.settings.chipItem) or 0
    return chips
end

function AddCasinoChips(source, casinoId, amount)
    local casino = Casinos[casinoId]
    if not casino then return end
    Inventory.AddItem(source, casino.settings.chipItem, amount)
end

function RemoveCasinoChips(source, casinoId, amount)
    local casino = Casinos[casinoId]
    if not casino then return end
    Inventory.RemoveItem(source, casino.settings.chipItem, amount)
end

RegisterCallback("pickle_casinos:getManagementStatus", function(source, cb, casinoId)
    return cb(CanManageCasino(source, casinoId))
end)

RegisterCallback("pickle_casinos:getPlayers", function(source, cb)
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        players[#players + 1] = {
            source = playerId,
            identifier = GetIdentifier(playerId),
            name = GetPlayerCharacterName(playerId),
        }
    end
    return cb(players)
end)

RegisterCallback("pickle_casinos:getVIPStatus", function(source, cb, casinoId)
    return cb(IsPlayerCasinoVIP(source, casinoId))
end)

RegisterNetEvent("pickle_casinos:initializePlayer", function()
    local source = source
    TriggerClientEvent("pickle_casinos:syncCasinos", source, Casinos)
    TriggerClientEvent("pickle_casinos:setupInventory", source, {
        items = Inventory.Items,
    })
    UpdateHorseTracks(source)
    UpdateObjects(source)
end)

RegisterNetEvent("pickle_casinos:createCasino", function(data)
    if not type(data) == "table" then return end
    if not CanManageCasino(source) then return ShowNotification(source, _L("no_permission")) end
    local casinoSettings = {
        label = data.label or "UNKNOWN_LABEL",
        location = data.location or {
            coords = vector3(0, 0, 0),
            rotation = vector3(0, 0, 0)
        },
        chipItem = data.chipItem or "UNKNOWN_CHIP_ITEM",
        blipEnabled = data.blipEnabled or false,
    }
    local entities = {}
    if data.template and data.template ~= "none" then
        local template = Templates[data.template]
        if template then
            entities = json.decode(template.entitiesJSON) or {}
            AddTemplateMapObjects(data.template, json.decode(template.objectsJSON) or {})
        end
    end 
    MySQL.insert('INSERT INTO `pickle_casinos` (settings, entities, transactions, vip_players) VALUES (?, ?, ?, ?)', {
        json.encode(casinoSettings), json.encode(entities), "[]", "[]"
    }, function(id)
        RegisterCasino(id, {
            id = id,
            entities = entities,
            settings = casinoSettings,
        })
    end)
end)

RegisterNetEvent("pickle_casinos:deleteCasino", function(casinoId)
    if not CanManageCasino(source) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    MySQL.Async.execute('DELETE FROM `pickle_casinos` WHERE id = ?', {casinoId})
    Casinos[casinoId] = nil
    TriggerClientEvent("pickle_casinos:deleteCasino", -1, casinoId)
end)

RegisterNetEvent("pickle_casinos:updateCasinoSetting", function(casinoId, variable, value)
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    if variable == "chipItem" and not CanManageCasino(source) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    if variable == "label" then
        casino.settings.label = tostring(value) or "INVALID_LABEL"
    elseif variable == "chipItem" then
        casino.settings.chipItem = tostring(value) or "INVALID_CHIP_ITEM"
    elseif variable == "blipEnabled" then
        casino.settings.blipEnabled = value and true or false
    elseif variable == "location" then
        if not value or not value.coords or not value.rotation then return end
        casino.settings.location = value
    elseif variable == "moneyExchangeRate" then
        casino.settings.moneyExchangeRate = tonumber(value) or 100
    elseif variable == "dirtyExchangeRate" then
        casino.settings.dirtyExchangeRate = tonumber(value) or 75
    elseif variable == "vipPrice" then 
        casino.settings.vipPrice = tonumber(value) or 1000  
    end
    casino.settings = EnsureCasinoSettings(casino.settings)
    MySQL.Async.execute('UPDATE `pickle_casinos` SET settings = ? WHERE id = ?', {json.encode(casino.settings), casinoId})
    TriggerClientEvent("pickle_casinos:updateCasinoSetting", -1, casinoId, variable, casino.settings[variable])
end)

RegisterNetEvent("pickle_casinos:updateCasinoOwner", function(casinoId, newOwner)
    local source = source
    if not IsPlayerAdmin(source) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    if newOwner.identifier == "none" then
        casino.owner_info = nil
    else
        casino.owner_info = {
            identifier = newOwner.identifier,
            name = newOwner.name
        }
    end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET owner_info = ? WHERE id = ?', {json.encode(casino.owner_info), casinoId})
    TriggerClientEvent("pickle_casinos:updateCasinoOwner", -1, casinoId, casino.owner_info)
end)

RegisterNetEvent("pickle_casinos:createCasinoEntity", function(casinoId, entityType, settings)
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    local entityId = GenerateEntityId(casinoId)
    local entity = {
        id = entityId,
        type = entityType,
        settings = EnsureGameSettings(entityType, settings),
    }
    table.insert(casino.entities, entity)
    UpdateCasinoEntitiesSQL(casinoId)
    InitializeCasinoEntity(casinoId, entity)
    TriggerClientEvent("pickle_casinos:createCasinoEntity", -1, casinoId, entity)
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    for i=1, #casino.entities do
        if casino.entities[i].id == entityId then
            table.remove(casino.entities, i)
            break
        end
    end
    UpdateCasinoEntitiesSQL(casinoId)
    TriggerClientEvent("pickle_casinos:deleteCasinoEntity", -1, casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:updateCasinoEntitySetting", function(casinoId, entityId, variable, value)
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    entity.settings[variable] = value
    entity.settings = EnsureGameSettings(entity.type, entity.settings)
    InitializeCasinoEntity(casinoId, entity, true)
    UpdateCasinoEntitiesSQL(casinoId)
    TriggerClientEvent("pickle_casinos:updateCasinoEntitySetting", -1, casinoId, entityId, variable, entity.settings[variable])
end)

RegisterNetEvent("pickle_casinos:startCasinoTransfer", function(casinoId, transferInfo)
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    local transferType = transferInfo.type
    local balanceType = transferInfo.balanceType
    local amount = transferInfo.amount
    local money = GetMoney(source)
    local marked_money = GetMoney(source, "dirty")
    if amount <= 0 then return ShowNotification(source, _L("invalid_amount")) end
    if transferType == "deposit" then
        if balanceType == "balance" then
            if money < amount then return ShowNotification(source, _L("insufficient_funds")) end
            RemoveMoney(source, amount)
            casino.balance = casino.balance + amount
        elseif balanceType == "marked_balance" then
            if marked_money < amount then return ShowNotification(source, _L("insufficient_funds")) end
            RemoveMoney(source, amount, "dirty")
            casino.marked_balance = casino.marked_balance + amount
        end
        ShowNotification(source, _L("casino_deposited", NumberWithCommas(amount), casino.settings.label))
        AddCasinoTransaction(source, casinoId, "management_deposit", amount)
    elseif transferType == "withdraw" then
        if balanceType == "balance" then
            if casino.balance < amount then return ShowNotification(source, _L("insufficient_funds")) end
            casino.balance = casino.balance - amount
            local totalTax = math.floor(amount * (Config.Casinos.tax / 100))
            AddMoney(source, amount - totalTax)
            if totalTax > 0 then
                for k,v in pairs(Config.Casinos.taxRecipients) do
                    AddSocietyMoney(k, math.floor(totalTax * (v / 100)))
                end
                ShowNotification(source, _L("casino_tax", NumberWithCommas(totalTax)))
            end
        elseif balanceType == "marked_balance" then
            if casino.marked_balance < amount then return ShowNotification(source, _L("insufficient_funds")) end
            casino.marked_balance = casino.marked_balance - amount
            AddMoney(source, amount, "dirty")
        end
        AddCasinoTransaction(source, casinoId, "management_withdraw", amount)
        ShowNotification(source, _L("casino_withdrawn", NumberWithCommas(amount), casino.settings.label))
    end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET balance = ?, marked_balance = ? WHERE id = ?', {
        casino.balance,
        casino.marked_balance,
        casinoId
    })
    TriggerClientEvent("pickle_casinos:updateCasinoBalance", -1, casinoId, casino.balance, casino.marked_balance)
end)

RegisterCommand("casinos", function(source, args, raw)
    if not CanManageCasino(source) then return ShowNotification(source, _L("no_permission")) end
    TriggerClientEvent("pickle_casinos:casinosMenu", source)
end)

CreateThread(function() 
    MySQL.Async.fetchAll("SELECT * FROM `pickle_casinos`", {}, function(results)
        for i=1, #results do
            local result = results[i]
            local settings = json.decode(result.settings) or {}
            local entities = json.decode(result.entities) or {}
            local transactions = json.decode(result.transactions) or {}
            local vip_players = json.decode(result.vip_players) or {}
            local owner_info = json.decode(result.owner_info) or nil
            RegisterCasino(result.id, {
                id = result.id,
                balance = result.balance,
                marked_balance = result.marked_balance,
                owner_info = owner_info,
                settings = settings,
                entities = entities,
                transactions = transactions,
                vip_players = vip_players,
            }, true)
        end
    end)
end)