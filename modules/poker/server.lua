function GenerateDefaultPokerSeat(source)
    if not source then return {source = nil, cards = {}, name = "ERR_UNKNOWN", inSeat = false, balance = 0} end
    return {source = source, cards = {}, blind = "none", name = GetPlayerCharacterName(source), balance = GetMoney(source), inSeat = true}
end

function JoinPokerEntity(source, casinoId, entityId, seatId)
    local seatId = seatId or 1
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if CurrentPlayers[source] then
        for i=1, #entity.seats do
            if entity.seats[i].source == source then
                entity.seats[seatId].inSeat = true
                return i
            end
        end
        ShowNotification(source, "You are already playing another casino game.")
        return
    end
    if entity.seats[seatId].source then
        seatId = nil
        for i=1, #entity.seats do
            if entity.seats[i].source == nil then
                seatId = i
                break
            end
        end
        if not seatId then
            ShowNotification(source, "There are no available seats at this table.")
            return 
        end
    end
    entity.seats[seatId] = GenerateDefaultPokerSeat(source)
    CurrentPlayers[source] = {casinoId = casinoId, entityId = entityId, seatId = seatId}
    SendCasinoEntityUpdate(casinoId, entityId)
    SetTimeout(100 * 1, function()
        TriggerClientEvent("pickle_casinos:poker:updateSeat", -1, casinoId, entityId, seatId, entity.seats[seatId])
    end)
    ShowNotification(source, "You have joined the table at seat " .. seatId .. ".")
    return seatId
end

function InitializePokerEntity(casinoId, data, dataOnly)
    local entity = data or { id = "ERR_NO_ID_POKER" }
    entity.seats = {}
    for i=1, 10 do
        entity.seats[i] = GenerateDefaultPokerSeat()
    end
    for i=1, 2 do
        if i ~= 8 then
            entity.seats[i].source = i + 1000
            entity.seats[i].name = "Bot #" .. i
            entity.seats[i].balance = 10000
            entity.seats[i].inSeat = true
        end
    end
    if not dataOnly then
        SetTimeout(100 * 1, function()
            StartPokerLobby(casinoId, entity.id)
        end)
    end
    return entity
end

function GetPlayerPokerInfo(source)
    if not source or source < 1 then return end
    for k,v in pairs(Casinos) do
        for i=1, #v.entities do
            local entity = v.entities[i]
            -- if entity.type == "slot" and entity.currentPlayer and entity.currentPlayer.source == source then
            --     return {casinoId = k, entityId = entity.id, seatId = 1}
            -- end
        end
    end
end

function TriggerReclusiveClientEvent(eventName, source, ...)
    for _, playerId in ipairs(GetPlayers()) do
        if tonumber(source) ~= tonumber(playerId) then
            TriggerClientEvent(eventName, playerId, ...)
        end
    end
end

function GetObfuscuatedSeat(seat)
    local obfuscatedSeat = {}
    for k,v in pairs(seat) do
        if k == "cards" then
            obfuscatedSeat.cards = {}
            for i=1, #v do
                obfuscatedSeat.cards[i] = { class = "hidden", value = 0 }
            end
        else
            obfuscatedSeat[k] = v
        end
    end
    if obfuscatedSeat.cards then
        for i=1, #obfuscatedSeat.cards do
            if obfuscatedSeat.cards[i] then
                obfuscatedSeat.cards[i].class = "hidden"
                obfuscatedSeat.cards[i].value = 0
            end
        end
    end
    return obfuscatedSeat
end

function StartPokerGame(casinoId, entityId)
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local round = 0
    local smallBlind = entity.settings.smallBlind or 1
    local bigBlind = entity.settings.bigBlind or 2
    local pot = 0
    local lastButtonIndex = #entity.seats
    local smallBlindIndex = lastButtonIndex
    repeat 
        smallBlindIndex = smallBlindIndex + 1
        if smallBlindIndex > #entity.seats then
            smallBlindIndex = 1
        end
    until entity.seats[smallBlindIndex].source
    local bigBlindIndex = smallBlindIndex
    repeat 
        bigBlindIndex = bigBlindIndex + 1
        if bigBlindIndex > #entity.seats then
            bigBlindIndex = 1
        end
    until entity.seats[bigBlindIndex].source and bigBlindIndex ~= smallBlindIndex
    entity.seats[smallBlindIndex].blind = "small"
    entity.seats[bigBlindIndex].blind = "big"
    -- print("Small Blind: " .. smallBlindIndex .. " Big Blind: " .. bigBlindIndex)
    pot = smallBlind + bigBlind
    TriggerClientEvent("pickle_casinos:poker:updateSeats", -1, casinoId, entityId, entity.seats)
    TriggerClientEvent("pickle_casinos:poker:updatePot", -1, casinoId, entityId, pot)
    CreateThread(function()
        repeat
            round = round + 1
            for i=1, #entity.seats do
                if entity.seats[i].source then
                    local card = GenerateCard()
                    entity.seats[i].cards[round] = card
                    TriggerReclusiveClientEvent("pickle_casinos:poker:updateStage", entity.seats[i].source, casinoId, entityId, {type = "dealing", seat = i, card = { class = "hidden", value = 0 }})
                    TriggerClientEvent("pickle_casinos:poker:updateStage", entity.seats[i].source, casinoId, entityId, {type = "dealing", seat = i, card = card})
                    SetTimeout(1200, function()
                        print(json.encode(entity.seats[i].cards))
                        TriggerReclusiveClientEvent("pickle_casinos:poker:updateSeat", entity.seats[i].source, casinoId, entityId, i, GetObfuscuatedSeat(entity.seats[i]))
                        TriggerClientEvent("pickle_casinos:poker:updateSeat", entity.seats[i].source, casinoId, entityId, i, entity.seats[i])
                    end)
                    Wait(1300)
                end
            end
        until round >= 2
        local startSeat = bigBlindIndex
        repeat
            startSeat = startSeat + 1
            if startSeat > #entity.seats then
                startSeat = 1
            end
        until entity.seats[startSeat].source
        local currentSeat = startSeat
        repeat
            if entity.seats[currentSeat].source then
                entity.stage = {type = "seatTurn", time = Config.SeatTurnTime, seat = currentSeat}
                TriggerClientEvent("pickle_casinos:poker:updateStage", -1, casinoId, entityId, {type = "seatTurn", seat = currentSeat})
                Wait(5000)
            end
            currentSeat = currentSeat + 1
            if currentSeat > #entity.seats then
                currentSeat = 1
            end
        until currentSeat == startSeat
    end)
end

function StartPokerLobby(casinoId, entityId)
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    entity.stage = {type = "waiting", time = Config.WaitingTime}
    TriggerClientEvent("pickle_casinos:poker:updateStage", -1, casinoId, entityId, entity.stage)
    CreateThread(function()
        while entity.stage.type == "waiting" and entity.stage.time > 1 do
            entity.stage.time = entity.stage.time - 1
            Wait(1000)
        end
        local totalPlayers = 0
        for i=1, #entity.seats do
            if entity.seats[i].source and entity.seats[i].inSeat then
                totalPlayers = totalPlayers + 1
            end
        end
        if totalPlayers < 2 then
            StartPokerLobby(casinoId, entityId)
        else
            StartPokerGame(casinoId, entityId)
        end
    end)
end

RegisterNetEvent("pickle_casinos:poker:leaveTable", function()
    local playerInfo = GetPlayerPokerInfo(source)
    if not playerInfo then return end
end)

RegisterCallback("pickle_casinos:poker:requestSeat", function(source, cb, casinoId, entityId, seatId)
    local seatId = JoinPokerEntity(source, casinoId, entityId, seatId)
    local entity = GetCasinoEntity(casinoId, entityId)
    if seatId then
        return cb(seatId, {
            id = entity.id,
            seats = entity.seats,
            stage = entity.stage,
            money = GetMoney(source)
        })
    end
    cb(seatId)
end)