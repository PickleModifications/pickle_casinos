function InitializeLuckyWheelEntity(casinoId, data, dataOnly)
    local entity = data or { id = "ERR_NO_ID_POKER" }
    entity.stage = entity.stage or { type = "waiting" }
    return entity
end

function ProcessLuckyWheelRewards(source, casinoId, entityId, section, rewards)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local sectionCfg = Config.LuckyWheel.sections[LuckyWheelSections[section]]
    if not sectionCfg then print("^1ERROR: LUCKY WHEEL SECTION CONFIG UNDEFINED, ADD THIS SECTION IN CONFIG.LUCKYWHEEL.SECTIONS: ", LuckyWheelSections[section]) return end
    local totalCost = 0
    for _, reward in ipairs(rewards) do
        if reward.casinoCost and reward.casinoCost > 0 then
            totalCost = totalCost + reward.casinoCost
        end
    end
    local balance = casino.balance or 0
    if IsCasinoOwned(casinoId) and totalCost > 0 then
        if balance < totalCost then
            ShowNotification(source, _L("luckywheel_no_casino_balance"))
            return false
        end
        casino.balance = balance - totalCost
        MySQL.Async.execute('UPDATE `pickle_casinos` SET balance = ? WHERE id = ?', {
            casino.balance,
            casinoId
        })
        AddCasinoTransaction(source, casinoId, "luckywheel_withdraw", totalCost)
        TriggerClientEvent("pickle_casinos:updateCasinoBalance", -1, casinoId, casino.balance, casino.marked_balance or 0)
    end
    for _, reward in ipairs(rewards) do
        if reward.type == "money" then
            AddMoney(source, reward.amount)
        elseif reward.type == "chips" then
            AddCasinoChips(source, casinoId, reward.amount)
        elseif reward.type == "item" then
            Inventory.AddItem(source, reward.name, reward.amount)
        elseif reward.type == "vehicle" then
            AddOwnedVehicle(source, reward.model)
        elseif reward.type == "xp" and Config.XPEnabled then
            AddPlayerXP(source, reward.name, reward.amount)
        end
    end
    local prizeString = ""
    local firstPrize = rewards[1]
    if firstPrize.type == "money" then
        prizeString = NumberWithCommas(firstPrize.amount)
    elseif firstPrize.type == "chips" then
        prizeString = _L("luckywheel_reward_chips", NumberWithCommas(firstPrize.amount, true))
    elseif firstPrize.type == "item" then
        prizeString = _L("luckywheel_reward_item", GetItemLabel(firstPrize.name) or "Unknown Item", NumberWithCommas(firstPrize.amount, true))
    elseif firstPrize.type == "vehicle" then
        prizeString = _L("luckywheel_reward_vehicle", firstPrize.label or firstPrize.model)
    elseif firstPrize.type == "xp" then
        prizeString = _L("luckywheel_reward_xp", NumberWithCommas(firstPrize.amount, true), firstPrize.label or firstPrize.name)
    else 
        prizeString = "UNKNOWN_PRIZE_" .. firstPrize.type
    end
    if #rewards > 1 then
        ShowNotification(source, _L("luckywheel_reward_multiple", prizeString, #rewards - 1))
    else
        ShowNotification(source, _L("luckywheel_reward", prizeString))
    end
    return true
end

function GenerateWinningSection()
    local wheelSections = Config.LuckyWheel.sections
    local sections = {}
    for k,v in pairs(wheelSections) do
        if v.chance and v.chance > 0 then
            for i=1, v.chance do 
                table.insert(sections, k)
            end
        end
    end
    local section = sections[math.random(1, #sections)]
    local sectionIndexes = {}
    for i=1, #LuckyWheelSections do
        local sectionName = LuckyWheelSections[i]
        if sectionName == section then
            table.insert(sectionIndexes, i)
        end
    end
    return section, sectionIndexes[math.random(1, #sectionIndexes)]
end

RegisterNetEvent("pickle_casinos:luckywheel:startSpin", function()
    local source = source
    local casinoId
    local entityId
    for k,v in pairs(Casinos) do
        for i=1, #v.entities do
            local entity = v.entities[i]
            if entity.type == "luckywheel" and entity.spinner == source then
                casinoId = k
                entityId = entity.id
                break
            end
        end
    end
    if not casinoId or not entityId then return end
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local isSpinning = entity.stage.type ~= "waiting" and entity.stage.type ~= "starting"
    if not Config.LuckyWheel then print("^1ERROR: LUCKY WHEEL CONFIG UNDEFINED, CHECK LAST UPDATE FOR CONFIG.LUCKYWHEEL AND COPY IT TO YOURS.^0") return cb(false) end
    if isSpinning then return end
    local sectionIndex = entity.sectionIndex
    local sectionCfg = Config.LuckyWheel.sections[LuckyWheelSections[sectionIndex]]
    if not sectionCfg then print("^1ERROR: LUCKY WHEEL SECTION CONFIG UNDEFINED, ADD THIS SECTION IN CONFIG.LUCKYWHEEL.SECTIONS:^0", LuckyWheelSections[sectionIndex]) return cb(false) end
    local result = GetLuckyWheelSafeDegrees(((sectionIndex / #LuckyWheelSections) * 360.0))
    local section = GetLuckyWheelSectionForDegrees(result)
    local spinPrice = entity.settings.spinPrice or 0
    entity.stage = {type = "spinning", degrees = result}
    TriggerClientCasinoEvent("pickle_casinos:luckywheel:updateStage", -1, casinoId, entityId, entity.stage)
    CreateThread(function()
        Wait(15000)
        local casino = Casinos[casinoId]
        if not casino then return end
        entity.stage = {type = "winner", section = section}
        TriggerClientCasinoEvent("pickle_casinos:luckywheel:updateStage", -1, casinoId, entityId, entity.stage)
        if sectionCfg.rewards and #sectionCfg.rewards > 0 then
            local rewards = {}
            if sectionCfg.chooseRandomReward then
                local reward = sectionCfg.rewards[math.random(1, #sectionCfg.rewards)]
                table.insert(rewards, reward)
            else
                rewards = sectionCfg.rewards
            end
            local processed = ProcessLuckyWheelRewards(source, casinoId, entityId, sectionIndex, rewards)
            if not processed then
                if spinPrice > 0 then
                    AddCasinoChips(source, casinoId, spinPrice)
                end
            else
                -- TODO: spin cooldown
                local needsCooldown = true
                if spinPrice > 0 and not Config.LuckyWheel.paidCooldown then
                    needsCooldown = false
                end
                if needsCooldown then
                    local playerInfo, playerIndex = GetPlayerCasinoInfo(source, casinoId)
                    if not playerIndex then
                        playerIndex = #casino.vip_players + 1
                        casino.vip_players[playerIndex] = playerInfo
                    end
                    casino.vip_players[playerIndex].spinStart = os.time()
                    UpdateCasinoPlayerInfo(casinoId)
                end
            end
        else
            ShowNotification(source, _L("luckywheel_no_reward"))
        end
        entity.stage = {type = "waiting"}
        entity.spinner = nil
        TriggerClientCasinoEvent("pickle_casinos:luckywheel:updateStage", -1, casinoId, entityId, entity.stage)
    end)
end)

RegisterCallback("pickle_casinos:luckywheel:requestSpin", function(source, cb, casinoId, entityId, seatId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local isSpinning = entity.stage.type ~= "waiting"
    local spinPrice = entity.settings.spinPrice or 0
    local balance = GetCasinoChips(source, casinoId)
    if not Config.LuckyWheel then print("^1ERROR: LUCKY WHEEL CONFIG UNDEFINED, CHECK LAST UPDATE FOR CONFIG.LUCKYWHEEL AND COPY IT TO YOURS.^0") return cb(false) end
    if isSpinning or balance < spinPrice then 
        ShowNotification(source, (isSpinning and _L("luckywheel_spin_in_progress") or _L("insufficient_chips")))
        return cb(false) 
    end
    local sectionId, sectionIndex = GenerateWinningSection()
    local sectionCfg = Config.LuckyWheel.sections[LuckyWheelSections[sectionIndex]]
    if not sectionCfg then print("^1ERROR: LUCKY WHEEL SECTION CONFIG UNDEFINED, ADD THIS SECTION IN CONFIG.LUCKYWHEEL.SECTIONS:^0", LuckyWheelSections[sectionIndex]) return cb(false) end
    if (spinPrice > 0 and Config.LuckyWheel.paidCooldown) or (spinPrice == 0) then
        local playerInfo, playerIndex = GetPlayerCasinoInfo(source, casinoId)
        if playerInfo.spinStart then
            local expireTime = playerInfo.spinStart + Config.LuckyWheel.spinCooldown
            if os.time() < expireTime then
                local timeLeft = expireTime - os.time()
                local minutes = math.floor(timeLeft / 60)
                local seconds = timeLeft % 60
                ShowNotification(source, _L("luckywheel_spin_cooldown", GetFormattedTime(timeLeft)))
                return cb(false)
            end
        end
    end
    if spinPrice > 0 then
        RemoveCasinoChips(source, casinoId, spinPrice)
    end
    entity.spinner = source
    entity.sectionIndex = sectionIndex
    entity.stage = {type = "starting"}
    cb(true)
end)

function GetRandomMultiplier()
    local wheelBonus = Config.WheelBonus
    local options = {}
    for i=1, #wheelBonus do
        local option = wheelBonus[i]
        for j=1, option.chance do 
            table.insert(options, {index = i, multiplier = option.multiplier})
        end
    end
    local result = options[math.random(1, #options)]
    return result.index, result.multiplier
end