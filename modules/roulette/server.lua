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

function ProcessRouletteWager(casinoId, entityId, seat, handId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    local wager = entity.seats[seat].wagers[handId]
    if wager > GetMoney(entity.seats[seat].source) then
        ShowNotification(entity.seats[seat].source, "You do not have enough money to place this wager.")
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
        for k,v in pairs(entity.seats) do
            if v.wagers then
                totalWagers = totalWagers + v.wagers[1]
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

RegisterNetEvent("pickle_casinos:roulette:setWager", function(wager)
    local source = source
    local info = GetPlayerRouletteInfo(source)
    if not info then return end
    local entity = GetCasinoEntity(info.casinoId, info.entityId)
    if not entity then return end
    if not entity.stage.type == "waiting" then return end
    entity.seats[info.seatId].wagers[1] = wager
    TriggerClientEvent("pickle_casinos:roulette:updateSeatWager", -1, info.casinoId, info.entityId, info.seatId, 1, wager)
end)