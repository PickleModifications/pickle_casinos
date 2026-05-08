CurrentPlayers = {}
PlayerCooldowns = {}

function GetCasino(casinoId)
    return Casinos[casinoId]
end

exports("GetCasino", GetCasino)

function IsCasinoOwned(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return false end
    if casino.owner_info and casino.owner_info.identifier ~= "none" then return true end
    return false
end

function IsCasinoPersonalCasinos(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return false end
    if casino.settings.label == PERSONAL_CASINOS_LABEL then return true end
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
    elseif entity.type == "thunder_roulette" then
        entity = InitializeThunderRouletteEntity(casinoId, entity, dataOnly)
    elseif entity.type == "baccarat" then
        entity = InitializeBaccaratEntity(casinoId, entity, dataOnly)
    elseif entity.type == "slot" then
        entity = InitializeSlotEntity(casinoId, entity, dataOnly)
    elseif entity.type == "poker" then
        entity = InitializePokerEntity(casinoId, entity, dataOnly)
    elseif entity.type == "wheel" then
        entity = InitializeWheelEntity(casinoId, entity, dataOnly)
    elseif entity.type == "luckywheel" then
        entity = InitializeLuckyWheelEntity(casinoId, entity, dataOnly)
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
    if not newSettings.isOpen then newSettings.isOpen = false end
    if not newSettings.cashEnabled then newSettings.cashEnabled = false end
    if not newSettings.markedEnabled then newSettings.markedEnabled = false end
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

function GenerateDeck()
    local deck = {}
    local classes = {"spd", "club", "dia", "hrt"}
    local values = {"ace", "02", "03", "04", "05", "06", "07", "08", "09", "10", "jack", "queen", "king"}
    for i=1, #classes do
        for j=1, #values do
            table.insert(deck, { class = classes[i], value = values[j] })
        end
    end
    -- Randomize the deck
    for i = #deck, 2, -1 do
        local j = math.random(1, i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

function GenerateCard(deck) 
    local classes = {"spd", "club", "dia", "hrt"}
    local values = {"ace", "02", "03", "04", "05", "06", "07", "08", "09", "10", "jack", "queen", "king"}
    -- return { class = classes[1], value = values[6] }
    if deck then
        local index = math.random(1, #deck)
        local card = deck[index]
        table.remove(deck, index)
        return card, deck
    else
        return { class = classes[math.random(1, #classes)], value = values[math.random(1, #values)] }
    end
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

exports("GetCasinoEntity", GetCasinoEntity)

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
    if entityType == "blackjack" or entityType == "roulette" or entityType == "thunder_roulette" or entityType == "baccarat" or entityType == "slot" or entityType == "wheel" or entityType == "horseracing" then
        defaultSettings["maxWager"] = settings.maxWager or 1000
        if Config.MaxWager and defaultSettings["maxWager"] > Config.MaxWager then
            defaultSettings["maxWager"] = Config.MaxWager
        end
    end
    if entityType == "blackjack" or entityType == "roulette" or entityType == "thunder_roulette" or entityType == "baccarat" or entityType == "poker" then
        defaultSettings["tableModel"] = settings.tableModel
        defaultSettings["dealerModel"] = settings.dealerModel
    end
    if entityType == "cashier" or entityType == "store" then
        defaultSettings["dealerModel"] = settings.dealerModel
    end
    if entityType == "luckywheel" then
        defaultSettings["wheelModel"] = settings.wheelModel
        defaultSettings["spinPrice"] = settings.spinPrice or 0
        defaultSettings["vehicleLocation"] = settings.vehicleLocation and {
            coords = vector3(settings.vehicleLocation.coords.x, settings.vehicleLocation.coords.y, settings.vehicleLocation.coords.z) or vector3(0, 0, 0),
            rotation = vector3(settings.vehicleLocation.rotation.x, settings.vehicleLocation.rotation.y, settings.vehicleLocation.rotation.z) or vector3(0, 0, 0)
        } or { coords = vector3(0, 0, 0), rotation = vector3(0, 0, 0) }
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
            owner_info = Casinos[casinoId].entities[i].owner_info,
        })
    end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET entities = ? WHERE id = ?', {json.encode(entities), casinoId})
end

function GetPlayerCasinoInfo(source, casinoId)
    local casino = Casinos[casinoId]
    if not casino then return false end
    local identifier = GetIdentifier(source)
    for i=1, #casino.vip_players do
        if casino.vip_players[i].identifier == identifier then
            return casino.vip_players[i], i
        end
    end
    return { identifier = identifier, name = GetPlayerCharacterName(source) }, nil
end

function UpdateCasinoPlayerInfo(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return end
    MySQL.Async.execute('UPDATE `pickle_casinos` SET vip_players = ? WHERE id = ?', {json.encode(casino.vip_players), casinoId})
end

function IsPlayerCasinoVIP(source, casinoId)
    local casino = Casinos[casinoId]
    if not casino then return false end
    local player = GetPlayerCasinoInfo(source, casinoId)
    return player.startTime ~= nil
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
    TriggerLatentClientEvent("pickle_casinos:updateCasinoTransactions", -1, Config.BytesPerSecond or 25000, casinoId, casino.transactions)
end

function GetCasinoChips(source, casinoId)
    local casino = Casinos[casinoId]
    if not source then return 0 end
    if not casino then return 0 end
    if casino.settings.label == PERSONAL_CASINOS_LABEL then 
        return GetMoney(source)
    end
    local chips = Inventory.GetItemCount(source, casino.settings.chipItem) or 0
    return chips
end

function AddCasinoChips(source, casinoId, amount)
    local casino = Casinos[casinoId]
    if not casino then return end
    if casino.settings.label == PERSONAL_CASINOS_LABEL then 
        return AddMoney(source, amount)
    end
    Inventory.AddItem(source, casino.settings.chipItem, amount)
end

function RemoveCasinoChips(source, casinoId, amount)
    local casino = Casinos[casinoId]
    if not casino then return end
    if casino.settings.label == PERSONAL_CASINOS_LABEL then 
        return RemoveMoney(source, amount)
    end
    Inventory.RemoveItem(source, casino.settings.chipItem, amount)
end

function UpdatePlayerBalance(source, casinoId, noDelay)
    local performUpdate = function()
        local balance = GetCasinoChips(source, casinoId)
        TriggerClientEvent("pickle_casinos:updateBalance", source, balance, casinoId)
    end
    if noDelay then
        performUpdate()
        return
    end
    SetTimeout(100, function()
        performUpdate()
    end)
end

function GetFormattedPlayer(source)
    local name = GetPlayerName(source)
    name = "**Name:** ".. name .. " (ID: " .. source .. ")\n**Identifiers:**\n`" .. json.encode(GetFilteredPlayerIdentifiers(source), {indent = true}) .. "`"
    return name
end

function PerformCooldownProcess(source)
    local source = tonumber(source)
    local threshold = Config.CooldownTime or 10
    local warningThreshold = threshold - 3
    local newCooldown = false
    if not PlayerCooldowns[source] then
        newCooldown = true
        PlayerCooldowns[source] = {
            cooldown = 0,
        }
    end
    if PlayerCooldowns[source] then 
        PlayerCooldowns[source].cooldown = PlayerCooldowns[source].cooldown + 1
        if PlayerCooldowns[source].cooldown == warningThreshold then
            ShowNotification(source, _L("cooldown_warning"))
        end
    end
    if newCooldown then
        SetTimeout(1000, function()
            if PlayerCooldowns[source] and PlayerCooldowns[source].cooldown >= threshold then
                DropPlayer(source, "Pickle Casinos: You have been kicked for spamming game actions.")
            end
            PlayerCooldowns[source] = nil
        end)
    end
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
    local playerInfo, playerIndex = GetPlayerCasinoInfo(source, casinoId)
    local vipStartTime = playerInfo.startTime
    if not vipStartTime then return cb(false) end
    if Config.Casinos.vipExpireTime > 0 and (vipStartTime + Config.Casinos.vipExpireTime) < os.time() then
        local casino = Casinos[casinoId]
        if not casino then return end
        if playerIndex then
            casino.vip_players[playerIndex].startTime = nil
            MySQL.Async.execute('UPDATE `pickle_casinos` SET vip_players = ? WHERE id = ?', {json.encode(casino.vip_players), casinoId})
        end
        return cb(false)
    end 
    return cb(true, {
        timeLeft = Config.Casinos.vipExpireTime > 0 and ((vipStartTime + Config.Casinos.vipExpireTime) - os.time()) or nil,
    })
end)

RegisterNetEvent("pickle_casinos:initializePlayer", function()
    local source = source
    TriggerClientEvent("pickle_casinos:syncCasinos", source, Casinos, GetIdentifier(source))
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
        isOpen = true,
        cashEnabled = true,
        markedEnabled = true,
    }
    if casinoSettings.label == PERSONAL_CASINOS_LABEL then
        casinoSettings.label = "UNKNOWN_LABEL"
    end
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
        if casino.settings.label == PERSONAL_CASINOS_LABEL then
            casino.settings.label = "INVALID_LABEL"
        end
    elseif variable == "chipItem" then
        casino.settings.chipItem = tostring(value) or "INVALID_CHIP_ITEM"
    elseif variable == "blipEnabled" then
        casino.settings.blipEnabled = value and true or false
    elseif variable == "isOpen" then
        casino.settings.isOpen = value and true or false
    elseif variable == "cashEnabled" then
        casino.settings.cashEnabled = value and true or false
    elseif variable == "markedEnabled" then
        casino.settings.markedEnabled = value and true or false
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
    local source = source
    if not IsCasinoPersonalCasinos(casinoId) and not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    if IsCasinoPersonalCasinos(casinoId) then
        local placeableCfg = Config.PlaceableEntities[entityType]
        if not placeableCfg then return end
        local item = placeableCfg.item
        if Inventory.GetItemCount(source, item) < 1 then return end
        Inventory.RemoveItem(source, item, 1)
    end
    local entityId = GenerateEntityId(casinoId)
    local entity = {
        id = entityId,
        type = entityType,
        settings = EnsureGameSettings(entityType, settings),
    }
    if IsCasinoPersonalCasinos(casinoId) then
        entity.owner_info = {
            identifier = GetIdentifier(source),
            name = GetPlayerCharacterName(source)
        }
    end
    table.insert(casino.entities, entity)
    UpdateCasinoEntitiesSQL(casinoId)
    InitializeCasinoEntity(casinoId, entity)
    TriggerClientEvent("pickle_casinos:createCasinoEntity", -1, casinoId, entity)
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    local source = source
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casinoEntity then return end
    local isEntityOwner = (casinoEntity.owner_info and casinoEntity.owner_info.identifier == GetIdentifier(source))
    if not CanManageCasino(source, casinoId) and not isEntityOwner then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    local entityType = nil
    for i=1, #casino.entities do
        if casino.entities[i].id == entityId then
            entityType = casino.entities[i].type
            table.remove(casino.entities, i)
            break
        end
    end
    UpdateCasinoEntitiesSQL(casinoId)
    TriggerClientEvent("pickle_casinos:deleteCasinoEntity", -1, casinoId, entityId)
    if IsCasinoPersonalCasinos(casinoId) then
        local placeableCfg = Config.PlaceableEntities[entityType]
        if not placeableCfg then return end
        local item = placeableCfg.item
        Inventory.AddItem(source, item, 1)
    end
end)

RegisterNetEvent("pickle_casinos:updateCasinoEntitySetting", function(casinoId, entityId, variable, value)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casinoEntity then return end
    local isEntityOwner = (casinoEntity.owner_info and casinoEntity.owner_info.identifier == GetIdentifier(source))
    if not CanManageCasino(source, casinoId) and not isEntityOwner then return ShowNotification(source, _L("no_permission")) end
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
    local source = source
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
    for k,v in pairs(Config.PlaceableEntities) do 
        RegisterUsableItem(v.item, function(source)
            TriggerClientEvent("pickle_casinos:createPlacedEntity", source, k)
        end)
    end
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `pickle_casinos` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `owner_info` longtext DEFAULT NULL,
            `balance` int(11) NOT NULL DEFAULT 0,
            `marked_balance` int(11) NOT NULL DEFAULT 0,
            `settings` longtext NOT NULL,
            `vip_players` longtext NOT NULL,
            `transactions` longtext NOT NULL,
            `entities` longtext NOT NULL,
            PRIMARY KEY (`id`)
        )
    ]], {}, function()
        MySQL.Async.fetchAll("SELECT * FROM `pickle_casinos`", {}, function(results)
            local personalCasinoFound = false
            for i=1, #results do
                local result = results[i]
                local settings = json.decode(result.settings) or {}
                local entities = json.decode(result.entities) or {}
                local transactions = json.decode(result.transactions) or {}
                local vip_players = json.decode(result.vip_players) or {}
                local owner_info = json.decode(result.owner_info) or nil
                if settings and settings.label == PERSONAL_CASINOS_LABEL then
                    personalCasinoFound = true
                end
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
            if not personalCasinoFound then
                MySQL.insert('INSERT INTO `pickle_casinos` (settings, entities, transactions, vip_players) VALUES (?, ?, ?, ?)', {
                    json.encode({
                        label = PERSONAL_CASINOS_LABEL,
                        location = {
                            coords = vector3(0, 0, 0),
                            rotation = vector3(0, 0, 0)
                        },
                        chipItem = "UNKNOWN_CHIP_ITEM",
                        blipEnabled = false,
                        isOpen = true,
                        cashEnabled = true,
                        markedEnabled = true,
                    }), "[]", "[]", "[]"
                }, function(id)
                    RegisterCasino(id, {
                        id = id,
                        balance = 0,
                        marked_balance = 0,
                        owner_info = nil,
                        settings = {
                            label = PERSONAL_CASINOS_LABEL,
                            location = {
                                coords = vector3(0, 0, 0),
                                rotation = vector3(0, 0, 0)
                            },
                            chipItem = "UNKNOWN_CHIP_ITEM",
                            blipEnabled = false,
                            isOpen = true,
                            cashEnabled = true,
                            markedEnabled = true,
                        },
                        entities = {},
                        transactions = {},
                        vip_players = {},
                    }, true)
                end)
            end
        end)
    end)
end)