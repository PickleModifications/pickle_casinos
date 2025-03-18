function JoinRouletteEntity(source, casinoId, entityId, seatId)
    local seatId = seatId or 1
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if entity.seats[seatId].source then
        for i=1, #entity.seats do
            if entity.seats[i].source == nil then
                seatId = i
                break
            end
        end
        ShowNotification(source, "There are no available seats at this table.")
        return 
    end
    entity.seats[seatId] = {
        source = source, 
        wagers = GenerateRouletteDefaultWagers()
    }
    SetTimeout(100 * 1, function()
        TriggerClientEvent("pickle_casinos:roulette:updateSeat", -1, casinoId, entityId, seatId, entity.seats[seatId])
    end)
    ShowNotification(source, "You have joined the table at seat " .. seatId .. ".")
    return seatId
end

function GetRouletteEntity(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    return {
        id = entity.id,
        seats = entity.seats,
        stage = entity.stage
    }
end

function ProcessRouletteWager(casinoId, entityId, seat)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local totalWager = 0
    for i=1, #entity.seats[seat].wagers.rows do
        for j=1, #entity.seats[seat].wagers.rows[i] do
            totalWager = totalWager + entity.seats[seat].wagers.rows[i][j].wager
        end
    end
    for i=1, #entity.seats[seat].wagers.sections do
        for j=1, #entity.seats[seat].wagers.sections[i] do
            totalWager = totalWager + entity.seats[seat].wagers.sections[i][j].wager
        end
    end
    if totalWager == 0 then return end
    local wager = totalWager
    if GetMoney(entity.seats[seat].source) < wager then
        ShowNotification(entity.seats[seat].source, "You do not have enough money to place this bet.")
        return false
    end
    RemoveMoney(entity.seats[seat].source, wager)
    return true
end

function StartRouletteGame(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    if entity.stage.type ~= "waiting" then return end
    local hasAcceptedWager = false
    for i=1, #entity.seats do
        local totalWager = 0
        for j=1, #entity.seats[i].wagers.rows do
            for k=1, #entity.seats[i].wagers.rows[j] do
                if entity.seats[i].wagers.rows[j][k].wager > 0 then
                    totalWager = totalWager + entity.seats[i].wagers.rows[j][k].wager
                end
            end
        end
        for j=1, #entity.seats[i].wagers.sections do
            for k=1, #entity.seats[i].wagers.sections[j] do
                if entity.seats[i].wagers.sections[j][k].wager > 0 then
                    totalWager = totalWager + entity.seats[i].wagers.sections[j][k].wager
                end
            end
        end
        if not ProcessRouletteWager(casinoId, entityId, i) then
            entity.seats[i].wagers = GenerateRouletteDefaultWagers()
            TriggerClientEvent("pickle_casinos:roulette:updateSeatWager", -1, casinoId, entityId, i, entity.seats[i].wagers)
        else
            print("BET ACCEPTED:", i, totalWager)
            hasAcceptedWager = true
        end
    end
    if not hasAcceptedWager then
        StartRouletteLobby(casinoId, entityId)
        return
    end
    CreateThread(function()
        local numbers = {"00", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36"}
        entity.stage = {type = "rolling", targetNumber = numbers[math.random(1, 38)]}
        TriggerClientEvent("pickle_casinos:roulette:updateStage", -1, casinoId, entityId, entity.stage)
        Wait(10000)
        local winningNumber = entity.stage.targetNumber
        for i=1, #entity.seats do 
            local seat = entity.seats[i]
            local wagers = seat.wagers
            local totalWin = 0
            for j=1, #wagers.rows do
                for k=1, #wagers.rows[j] do
                    if wagers.rows[j][k].value == entity.stage.winningNumber then
                        totalWin = totalWin + (wagers.rows[j][k].wager * 36)
                    end
                end
            end
            local winningNumberParsed = tonumber(entity.stage.winningNumber)
            if winningNumberParsed then
                if wagers.sections[1][1].wager > 0 and winningNumberParsed >= 1 and winningNumberParsed <= 12 then
                    totalWin = totalWin + (wagers.sections[1][1].wager * 3)
                end
                if wagers.sections[1][2].wager > 0 and winningNumberParsed >= 13 and winningNumberParsed <= 24 then
                    totalWin = totalWin + (wagers.sections[1][2].wager * 3)
                end
                if wagers.sections[1][3].wager > 0 and winningNumberParsed >= 25 and winningNumberParsed <= 36 then
                    totalWin = totalWin + (wagers.sections[1][3].wager * 3)
                end
                if wagers.sections[2][1].wager > 0 and winningNumberParsed >= 1 and winningNumberParsed <= 18 then
                    totalWin = totalWin + (wagers.sections[2][1].wager * 2)
                end
                if wagers.sections[2][2].wager > 0 and winningNumberParsed % 2 == 0 then
                    totalWin = totalWin + (wagers.sections[2][2].wager * 2)
                end
                if wagers.sections[2][3].wager > 0 and GetRouletteColor(winningNumberParsed) == "red" then
                    totalWin = totalWin + (wagers.sections[2][3].wager * 2)
                end
                if wagers.sections[2][4].wager > 0 and GetRouletteColor(winningNumberParsed) == "black" then
                    totalWin = totalWin + (wagers.sections[2][4].wager * 2)
                end
                if wagers.sections[2][5].wager > 0 and winningNumberParsed % 2 == 1 then
                    totalWin = totalWin + (wagers.sections[2][5].wager * 2)
                end
            end
            if totalWin > 0 then
                AddMoney(seat.source, totalWin)
            end
            entity.seats[i].wagers = GenerateRouletteDefaultWagers()
            TriggerClientEvent("pickle_casinos:roulette:updateSeatWager", -1, casinoId, entityId, i, entity.seats[i].wagers)
        end
        entity.stage = {type = "winningNumber", winningNumber = winningNumber, seats = seats}
        TriggerClientEvent("pickle_casinos:roulette:updateStage", -1, casinoId, entityId, entity.stage)
        Wait(6000)
        StartRouletteLobby(casinoId, entityId)
    end)
end

function StartRouletteLobby(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    entity.stage = {type = "waiting", time = 11}
    TriggerClientEvent("pickle_casinos:roulette:updateStage", -1, casinoId, entityId, entity.stage)
    CreateThread(function()
        while entity.stage.type == "waiting" and entity.stage.time > 1 do
            entity.stage.time = entity.stage.time - 1
            Wait(1000)
        end
        local totalWagers = 0
        for i=1, #entity.seats do
            for j=1, #entity.seats[i].wagers.rows do
                for k=1, #entity.seats[i].wagers.rows[j] do
                    totalWagers = totalWagers + entity.seats[i].wagers.rows[j][k].wager
                end
            end
            for j=1, #entity.seats[i].wagers.sections do
                for k=1, #entity.seats[i].wagers.sections[j] do
                    totalWagers = totalWagers + entity.seats[i].wagers.sections[j][k].wager
                end
            end
        end
        if totalWagers > 0 then
            StartRouletteGame(casinoId, entityId)
        else
            StartRouletteLobby(casinoId, entityId)
        end
    end)
end

function GetRouletteColor(value)
    if value == 0 then
        return "green"
    end
    if value == 1 or value == 3 or value == 5 or value == 7 or value == 9 or value == 12 or value == 14 or value == 16 or value == 18 or value == 19 or value == 21 or value == 23 or value == 25 or value == 27 or value == 30 or value == 32 or value == 34 or value == 36 then
        return "red"
    end
    return "black"
end

function GenerateRouletteRows(generateType)
    local rows = {
        {
            {wager = 0, value = "0", color = "green"},
            {wager = 0, value = "00", color = "none"},
        }
    }
    for i=0, 2 do
        local row = {}
        for j=0, 11 do
            row[#row + 1] = {
                wager = 0,
                value = (3 - i) + (j * 3),
                color = GetRouletteColor((3 - i) + (j * 3)),
            }
        end
        row[#row + 1] = {
            wager = 0,
            value = "2:1",
            color = "none",
        }
        rows[#rows + 1] = row
    end
    return rows;
end

function GenerateRouletteSections(generateType)
    return {
        {
            -- 1st, 2nd, 3rd
            {wager = 0},
            {wager = 0},
            {wager = 0},
        },
        {
            -- 1-18
            {wager = 0},
            -- Even
            {wager = 0},
            -- Red
            {wager = 0},
            -- Black
            {wager = 0},
            -- Odd
            {wager = 0},
            -- 19-36
            {wager = 0},
        }
    }
end

function GenerateRouletteDefaultWagers()
    return {
        rows = GenerateRouletteRows("wager"),
        sections = GenerateRouletteSections("wager"),
    }
end

function InitializeRouletteEntity(casinoId, entity)
    local entity = entity or { id = "ERR_ROULETTE_ENTITY" }
    entity.seats = {}
    for i=0, 4 do 
        entity.seats[i] = {
            source = nil,
            wagers = GenerateRouletteDefaultWagers() 
        }
    end
    SetTimeout(1000, function()
        StartRouletteLobby(casinoId, entity.id)
    end)
    return entity
end

function GetPlayerRouletteInfo(source)
    if not source or source < 1 then return end
    for k,v in pairs(Casinos) do
        for i=1, #v.entities do
            local entity = v.entities[i]
            if entity.type == "roulette" then
                for j, v in pairs(entity.seats) do
                    if entity.seats[j].source and tonumber(entity.seats[j].source) == tonumber(source) then
                        return {casinoId = k, entityId = entity.id, seatId = j}
                    end
                end
            end
        end
    end
end

RegisterCallback("pickle_casinos:roulette:requestSeat", function(source, cb, casinoId, entityId, seatId)
    local seatId = JoinRouletteEntity(source, casinoId, entityId, seatId)
    local entity = GetRouletteEntity(casinoId, entityId)
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

RegisterNetEvent("pickle_casinos:roulette:updateRouletteWagers", function(wagers)
    if (not wagers) then return end
    local source = source
    local info = GetPlayerRouletteInfo(source)
    if not info then return end
    local entity = GetCasinoEntity(info.casinoId, info.entityId)
    if not entity then return end
    if not entity.stage.type == "waiting" then return end
    if wagers.rows then
        for i=1, #wagers.rows do
            for j=1, #wagers.rows[i] do
                entity.seats[info.seatId].wagers.rows[i][j].wager = wagers.rows[i][j].wager
            end
        end
    end
    if wagers.sections then
        for i=1, #wagers.sections do
            for j=1, #wagers.sections[i] do
                entity.seats[info.seatId].wagers.sections[i][j].wager = wagers.sections[i][j].wager
            end
        end
    end
end)