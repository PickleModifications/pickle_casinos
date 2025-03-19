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
        connects = GenerateRouletteDefaultWagers()
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
    local totalWager = GetRouletteTotalWager(entity.seats[seat].connects)
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
        local totalWager = GetRouletteTotalWager(entity.seats[i].connects)
        if not ProcessRouletteWager(casinoId, entityId, i) then
            entity.seats[i].connects = GenerateRouletteDefaultWagers()
            TriggerClientEvent("pickle_casinos:roulette:updateSeatWager", -1, casinoId, entityId, i, entity.seats[i].connects)
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
            local connects = seat.connects
            local totalWin = 0
            -- TODO: Calculate winnings
            local data = GetDefaultRouletteConnections()
            for i=1, #data do 
                local wager = connects[i].wager
                if wager > 0 and data[i].numbers then
                    local payRatio = math.floor(36 / #data[i].numbers)
                    local hasNumber = false
                    for j=1, #data[i].numbers do
                        if data[i].numbers[j] == winningNumber then
                            hasNumber = true
                            break
                        end
                    end
                    if hasNumber then 
                        totalWin = totalWin + (wager * payRatio)
                    end
                end
            end
            if totalWin > 0 then
                AddMoney(seat.source, totalWin)
            end
            SetTimeout(6000, function()
                entity.seats[i].connects = GenerateRouletteDefaultWagers()
                TriggerClientEvent("pickle_casinos:roulette:updateSeatWager", -1, casinoId, entityId, i, entity.seats[i].connects)
            end)
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
            totalWagers = totalWagers + GetRouletteTotalWager(entity.seats[i].connects)
        end
        print("TOTAL WAGERS:", totalWagers) 
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

function GetRouletteTotalWager(connects) 
    local totalWager = 0
    for i=1, #connects do
        totalWager = totalWager + connects[i].wager
    end
    return totalWager
end

function GenerateRouletteRows(generateType)
    local rows = {
        {
            {value = "0", color = "green"},
            {value = "00", color = "none"},
        }
    }
    for i=0, 2 do
        local row = {}
        for j=0, 11 do
            row[#row + 1] = {
                value = (3 - i) + (j * 3),
                color = GetRouletteColor((3 - i) + (j * 3)),
            }
        end
        row[#row + 1] = {
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
            {},
            {},
            {},
        },
        {
            -- 1-18
            {},
            -- Even
            {},
            -- Red
            {},
            -- Black
            {},
            -- Odd
            {},
            -- 19-36
            {},
        }
    }
end

function GenerateRouletteDefaultWagers()
    return GetDefaultRouletteConnections()
end

function InitializeRouletteEntity(casinoId, entity)
    local entity = entity or { id = "ERR_ROULETTE_ENTITY" }
    entity.seats = {}
    for i=0, 4 do 
        entity.seats[i] = {
            source = nil,
            connects = GenerateRouletteDefaultWagers() 
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

RegisterNetEvent("pickle_casinos:roulette:updateRouletteWagers", function(connects)
    local source = source
    local info = GetPlayerRouletteInfo(source)
    if not info then return end
    local entity = GetCasinoEntity(info.casinoId, info.entityId)
    if not entity then return end
    if not entity.stage.type == "waiting" then return end
    local data = GetDefaultRouletteConnections()
    for i=1, #data do 
        data[i].wager = (connects[i].wager and tonumber(connects[i].wager) and tonumber(connects[i].wager) > 0) and tonumber(connects[i].wager) or 0
    end
    entity.seats[info.seatId].connects = data
    TriggerClientEvent("pickle_casinos:roulette:updateSeatWager", -1, info.casinoId, info.entityId, info.seatId, connects)
end)