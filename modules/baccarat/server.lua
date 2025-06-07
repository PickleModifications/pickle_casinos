local LastWagers = {}
local BaccaratLobbies = {}

function DoesBaccaratLobbyExist(casinoId, entityId)
    if not BaccaratLobbies[casinoId] then return false end
    if not BaccaratLobbies[casinoId][entityId] then return false end
    return BaccaratLobbies[casinoId][entityId]
end

function JoinBaccaratEntity(source, casinoId, entityId, seatId)
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
        ShowNotification(source, _L("playing_other_game"))
        return
    end
    if seatId == 0 then seatId = 1 end
    if entity.seats[seatId].source then
        seatId = nil
        for i=1, #entity.seats do
            if entity.seats[i].source == nil then
                seatId = i
                break
            end
        end
        if not seatId or seatId < 1 then
            ShowNotification(source, _L("no_seats_available"))
            return 
        end
    end
    CurrentPlayers[source] = {casinoId = casinoId, entityId = entityId, seatId = seatId}
    entity.seats[seatId] = {source = source, name = GetPlayerCharacterName(source), wagers = GenerateBaccaratDefaultWagers(), hands = {{}, {}}, inSeat = true}
    if not DoesBaccaratLobbyExist(casinoId, entityId) then
        StartBaccaratLobby(casinoId, entityId)
    end
    SetTimeout(100 * 1, function()
        TriggerClientCasinoEvent("pickle_casinos:baccarat:updateSeat", -1, casinoId, entityId, seatId, entity.seats[seatId])
    end)
    ShowNotification(source, _L("joined_seat", seatId))
    return seatId
end

function LeaveBaccaratEntity(source, casinoId, entityId, seatId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if entity.seats[seatId].source == source then
        entity.seats[seatId] = GenerateDefaultBaccaratSeat()
        SetTimeout(100 * 1, function()
            TriggerClientCasinoEvent("pickle_casinos:baccarat:updateSeat", -1, casinoId, entityId, seatId, entity.seats[seatId])
            TriggerClientCasinoEvent("pickle_casinos:baccarat:updateSeatWager", -1, casinoId, entityId, seatId, entity.seats[seatId].wagers)
        end)
        CurrentPlayers[source] = nil
        ShowNotification(source, _L("left_baccarat"))
    end
end

function GetBaccaratEntity(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    return {
        id = entity.id,
        seats = entity.seats,
        stage = entity.stage,
        betRange = entity.betRange,
    }
end

function ProcessBaccaratWager(casinoId, entityId, seat, handId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local wager = GetBaccaratTotalWager(entity.seats[seat].wagers)
    if wager > GetCasinoChips(entity.seats[seat].source, casinoId) then
        ShowNotification(entity.seats[seat].source, _L("insufficient_chips_bet"))
        return false
    end
    RemoveCasinoChips(entity.seats[seat].source, casinoId, wager)
    LastWagers[entity.seats[seat].source] = entity.seats[seat].wagers
    return true
end

function StartBaccaratGame(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if entity.stage.type ~= "waiting" then return end
    local transactions = {}
    local hiddenCard = GenerateCard()
    for i=1, 4 do
        if entity.seats[i].source then
            if not ProcessBaccaratWager(casinoId, entityId, i, 1) then
                entity.seats[i].wagers = GenerateBaccaratDefaultWagers()
                TriggerClientCasinoEvent("pickle_casinos:baccarat:updateSeat", -1, casinoId, entityId, i, entity.seats[i])
            else
                transactions[entity.seats[i].source] = StartCasinoGameplayTransaction(entity.seats[i].source, casinoId, entityId, "baccarat", GetBaccaratTotalWager(entity.seats[i].wagers))
            end
        end
    end
    CreateThread(function()
        local isFirstCard = true
        local round = 0
        repeat
            round = round + 1
            local sides = {"player", "banker"}
            for i=1, 2 do
                entity.stage = {type = "dealing", side = sides[i], card = GenerateCard(), cardIndex = #entity.cards[sides[i]] + 1, isFirstCard = isFirstCard}
                entity.cards[sides[i]][#entity.cards[sides[i]] + 1] = entity.stage.card
                TriggerClientCasinoEvent("pickle_casinos:baccarat:updateStage", -1, casinoId, entityId, entity.stage)
                if isFirstCard then
                    Wait(3000)
                end
                isFirstCard = false
                SetTimeout(1300, function()
                    TriggerClientCasinoEvent("pickle_casinos:baccarat:updateCards", -1, casinoId, entityId, sides[i], entity.cards[sides[i]])
                end)
                Wait(2000)
            end
        until round == 2
        local playerValue = GetBaccaratCardsValue(entity.cards.player)
        local bankerValue = GetBaccaratCardsValue(entity.cards.banker)
        local playerThirdCard = nil
        local done = false

        if playerValue == 8 or playerValue == 9 or bankerValue == 8 or bankerValue == 9 then
            done = true
        elseif playerValue <= 5 then
            playerThirdCard = GenerateCard()
            entity.stage = {type = "dealing", side = "player", card = GenerateCard(), cardIndex = #entity.cards.player + 1}
            entity.cards.player[#entity.cards.player + 1] = entity.stage.card
            TriggerClientCasinoEvent("pickle_casinos:baccarat:updateStage", -1, casinoId, entityId, entity.stage)
            SetTimeout(1300, function()
                TriggerClientCasinoEvent("pickle_casinos:baccarat:updateCards", -1, casinoId, entityId, "player", entity.cards.player)
            end)
            Wait(2000)
        end
        if not done then
            if not playerThirdCard then
                if bankerValue <= 5 then
                    entity.stage = {type = "dealing", side = "banker", card = GenerateCard(), cardIndex = #entity.cards.banker + 1}
                    entity.cards.banker[#entity.cards.banker + 1] = entity.stage.card
                    TriggerClientCasinoEvent("pickle_casinos:baccarat:updateStage", -1, casinoId, entityId, entity.stage)
                    SetTimeout(1300, function()
                        TriggerClientCasinoEvent("pickle_casinos:baccarat:updateCards", -1, casinoId, entityId, "banker", entity.cards.banker)
                    end)
                    Wait(2000)
                end
            else
                if (bankerValue <= 2) then
                    entity.stage = {type = "dealing", side = "banker", card = GenerateCard(), cardIndex = #entity.cards.banker + 1}
                    entity.cards.banker[#entity.cards.banker + 1] = entity.stage.card
                    TriggerClientCasinoEvent("pickle_casinos:baccarat:updateStage", -1, casinoId, entityId, entity.stage)
                    SetTimeout(1300, function()
                        TriggerClientCasinoEvent("pickle_casinos:baccarat:updateCards", -1, casinoId, entityId, "banker", entity.cards.banker)
                    end)
                    Wait(2000)
                elseif (playerThirdCard.value ~= 8 and (bankerValue >= 3 and bankerValue <= 6)) then
                    entity.stage = {type = "dealing", side = "banker", card = GenerateCard(), cardIndex = #entity.cards.banker + 1}
                    entity.cards.banker[#entity.cards.banker + 1] = entity.stage.card
                    TriggerClientCasinoEvent("pickle_casinos:baccarat:updateStage", -1, casinoId, entityId, entity.stage)
                    SetTimeout(1300, function()
                        TriggerClientCasinoEvent("pickle_casinos:baccarat:updateCards", -1, casinoId, entityId, "banker", entity.cards.banker)
                    end)
                    Wait(2000)
                end
            end
            done = true
        end
        local playerValue = GetBaccaratCardsValue(entity.cards.player)
        local bankerValue = GetBaccaratCardsValue(entity.cards.banker)
        local winner = "tie"
        if playerValue > bankerValue then
            winner = "player"
        elseif playerValue < bankerValue then
            winner = "banker"
        end
        local winningWagers = {
            player = (winner == "player"),
            banker = (winner == "banker"),
            tie = (winner == "tie"),
            playerPair = false,
            bankerPair = false,
            eitherPair = false,
            suitedPair = false,
            bothSuitedPair = false,
        }
        local winMultipliers = {
            player = 1,
            banker = 0.95,
            tie = 8,
            playerPair = 11,
            bankerPair = 11,
            eitherPair = 5,
            suitedPair = 20,
            bothSuitedPair = 200,
        }
        -- Set player pair
        if entity.cards.player[1].value == entity.cards.player[2].value then
            winningWagers.playerPair = true
        end
        -- Set banker pair
        if entity.cards.banker[1].value == entity.cards.banker[2].value then
            winningWagers.bankerPair = true
        end
        -- Set either pair
        if winningWagers.playerPair or winningWagers.bankerPair then
            winningWagers.eitherPair = true
        end
        -- Set suited pair
        if (entity.cards.player[1].class == entity.cards.player[2].class and winningWagers.playerPair) or (entity.cards.banker[1].class == entity.cards.banker[2].class and winningWagers.bankerPair) then
            winningWagers.suitedPair = true
        end
        -- Set both suited pair
        if (entity.cards.player[1].class == entity.cards.player[2].class and winningWagers.playerPair) and (entity.cards.banker[1].class == entity.cards.banker[2].class and winningWagers.bankerPair) then
            winningWagers.bothSuitedPair = true
        end
        local seatResults = {}
        for i=1, #entity.seats do 
            seatResults[i] = {won = 0, money = 0}
            if (entity.seats[i].source) then
                for k,isWinner in pairs(winningWagers) do
                    local wager = entity.seats[i].wagers[k]
                    if wager and wager > 0 and isWinner then
                        local winMultiplier = winMultipliers[k]
                        if (k == "suitedPair" and winningWagers.bothSuitedPair) then
                            winMultiplier = winMultipliers["bothSuitedPair"]
                        end
                        seatResults[i].won = seatResults[i].won + (wager + (wager * winMultiplier))
                    end
                end
                if winner == "tie" then
                    seatResults[i].won = seatResults[i].won + (entity.seats[i].wagers.player + (entity.seats[i].wagers.banker * 0.95))
                end
                seatResults[i].won = math.floor(seatResults[i].won)
                seatResults[i].money = GetCasinoChips(entity.seats[i].source, casinoId) + seatResults[i].won
                if seatResults[i].won > 0 then
                    AddCasinoChips(entity.seats[i].source, casinoId, seatResults[i].won)
                end
                if transactions[entity.seats[i].source] then
                    EndCasinoGameplayTransaction(transactions[entity.seats[i].source], entity.seats[i].source, casinoId, entityId, "baccarat", seatResults[i].won)
                end
                UpdatePlayerBalance(entity.seats[i].source, casinoId)
            end
        end
        Wait(750)
        TriggerClientCasinoEvent("pickle_casinos:baccarat:updateResults", -1, casinoId, entityId, {
            type = "results", 
            winningWagers = winningWagers,
        }, seatResults)
        entity.cards = {player = {}, banker = {}}
        entity.stage = {type = "cleanup", seat = 0}
        TriggerClientCasinoEvent("pickle_casinos:baccarat:updateStage", -1, casinoId, entityId, entity.stage)
        Wait(2000)
        TriggerClientCasinoEvent("pickle_casinos:baccarat:updateCards", -1, casinoId, entityId, "player", entity.cards["player"])
        TriggerClientCasinoEvent("pickle_casinos:baccarat:updateCards", -1, casinoId, entityId, "banker", entity.cards["banker"])
        for k,v in pairs(entity.seats) do
            entity.seats[k].wagers = GenerateBaccaratDefaultWagers()
            TriggerClientCasinoEvent("pickle_casinos:baccarat:updateSeatWager", -1, casinoId, entityId, k, entity.seats[k].wagers)
        end
        StartBaccaratLobby(casinoId, entityId)
    end)
end

function StartBaccaratLobby(casinoId, entityId)
    BaccaratLobbies[casinoId] = BaccaratLobbies[casinoId] or {}
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local totalPlayers = 0
    for i=1, #entity.seats do
        if entity.seats[i].source and not entity.seats[i].inSeat then
            LeaveBaccaratEntity(entity.seats[i].source, casinoId, entityId, i)
        elseif entity.seats[i].source then
            totalPlayers = totalPlayers + 1
        end
    end
    if totalPlayers <= 0 then
        BaccaratLobbies[casinoId][entityId] = false
        return
    else
        BaccaratLobbies[casinoId][entityId] = true
    end
    entity.stage = {type = "waiting", time = GetWaitingTime("baccarat")}
    TriggerClientCasinoEvent("pickle_casinos:baccarat:updateStage", -1, casinoId, entityId, entity.stage)
    CreateThread(function()
        while entity.stage.type == "waiting" and entity.stage.time > 1 do
            entity.stage.time = entity.stage.time - 1
            Wait(1000)
        end
        local totalWagers = 0
        for k,v in pairs(entity.seats) do
            totalWagers = totalWagers + GetBaccaratTotalWager(v.wagers)
        end
        if totalWagers > 0 then
            StartBaccaratGame(casinoId, entityId)
        else
            StartBaccaratLobby(casinoId, entityId)
        end
    end)
end

function GetBaccaratTotalWager(wagers)
    local total = 0
    for k,v in pairs(wagers) do
        total = total + v
    end
    return total
end

function GenerateBaccaratDefaultWagers()
    return {
        player = 0,
        banker = 0,
        tie = 0,
        playerPair = 0,
        bankerPair = 0,
        eitherPair = 0,
        suitedPair = 0,
    }
end

function GenerateDefaultBaccaratSeat()
    return {source = nil, wagers = GenerateBaccaratDefaultWagers(), inSeat = false}
end

function InitializeBaccaratEntity(casinoId, entity, dataOnly)
    local entity = entity or { id = "ERR_BACCARAT_ENTITY" }
    entity.seats = {}
    for i=1, 4 do 
        entity.seats[i] = GenerateDefaultBaccaratSeat()
    end
    entity.cards = {player = {}, banker = {}}
    entity.betRange = {
        math.floor(entity.settings.maxWager / 100),
        entity.settings.maxWager
    }
    return entity
end

function GetPlayerBaccaratInfo(source)
    if not source or source < 1 then return end
    for k,v in pairs(Casinos) do
        for i=1, #v.entities do
            local entity = v.entities[i]
            if entity.type == "baccarat" then
                for j, v in pairs(entity.seats) do
                    if entity.seats[j].source and tonumber(entity.seats[j].source) == tonumber(source) then
                        return {casinoId = k, entityId = entity.id, seatId = j}
                    end
                end
            end
        end
    end
end

RegisterCallback("pickle_casinos:baccarat:requestSeat", function(source, cb, casinoId, entityId, seatId)
    local seatId = JoinBaccaratEntity(source, casinoId, entityId, seatId)
    local entity = GetBaccaratEntity(casinoId, entityId)
    if seatId then
        return cb(seatId, {
            id = entity.id,
            seats = entity.seats,
            stage = entity.stage,
            money = GetCasinoChips(source, casinoId),
            betRange = entity.betRange,
        })
    end
    cb(seatId)
end)

RegisterNetEvent("pickle_casinos:baccarat:leaveTable", function()
    local source = source
    local info = GetPlayerBaccaratInfo(source)
    if not info then return end
    local entity = GetCasinoEntity(info.casinoId, info.entityId)
    if not entity then return end
    if entity.stage.type == "waiting" then
        LeaveBaccaratEntity(source, info.casinoId, info.entityId, info.seatId)
    else 
        entity.seats[info.seatId].inSeat = false
    end
end)

RegisterNetEvent("pickle_casinos:baccarat:setWager", function(wager)
    local source = source
    PerformCooldownProcess(source)
    if not wager or type(wager) ~= "table" then return end
    local info = GetPlayerBaccaratInfo(source)
    if not info then return end
    local entity = GetCasinoEntity(info.casinoId, info.entityId)
    if not entity then return end
    if not entity.stage.type == "waiting" then return end
    local newWagers = {
        player = wager.player or 0,
        banker = wager.banker or 0,
        tie = wager.tie or 0,
        playerPair = wager.playerPair or 0,
        bankerPair = wager.bankerPair or 0,
        eitherPair = wager.eitherPair or 0,
        suitedPair = wager.suitedPair or 0,
    }
    local totalWager = GetBaccaratTotalWager(newWagers)
    if totalWager <= entity.betRange[2] then
        entity.seats[info.seatId].wagers = newWagers
    end
    TriggerClientCasinoEvent("pickle_casinos:baccarat:updateSeatWager", -1, info.casinoId, info.entityId, info.seatId, entity.seats[info.seatId].wagers)
end)

RegisterNetEvent("pickle_casinos:baccarat:repeatWager", function()
    local source = source
    PerformCooldownProcess(source)
    local info = GetPlayerBaccaratInfo(source)
    if not info then return end
    local entity = GetCasinoEntity(info.casinoId, info.entityId)
    if not entity then return end
    if not entity.stage.type == "waiting" then return end
    local newWagers = LastWagers[source] or GenerateBaccaratDefaultWagers()
    local totalWager = GetBaccaratTotalWager(newWagers)
    if totalWager <= entity.betRange[2] then
        entity.seats[info.seatId].wagers = newWagers
    end
    TriggerClientCasinoEvent("pickle_casinos:baccarat:updateSeatWager", -1, info.casinoId, info.entityId, info.seatId, entity.seats[info.seatId].wagers)
end)

AddEventHandler('playerDropped', function()
    local source = source
    local info = GetPlayerBaccaratInfo(source)
    if info then
        LeaveBaccaratEntity(source, info.casinoId, info.entityId, info.seatId)
    end
    if CurrentPlayers[source] then
        CurrentPlayers[source] = nil
    end
end)