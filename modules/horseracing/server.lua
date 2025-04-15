Tracks = {}

local LastWagers = {}

function GetDefaultWager()
    return {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0,
        [7] = 0,
        [8] = 0,
        [9] = 0,
        [10] = 0,
        [11] = 0,
        [12] = 0,
    }
end

function GenerateWinningHorse(horses)
    local stack = {}
    for i=1, #Config.HorseRacing.odds do
        local odds = Config.HorseRacing.odds[i]
        for j=1, odds.chances do
            table.insert(stack, i)
        end
    end
    local oddsIndex = stack[math.random(1, #stack)]
    for i=1, #horses do 
        if horses[i].oddsIndex == oddsIndex then return i end
    end
end

function InitializeHorseRacingTracks()
    for i=1, #Config.HorseRacing.tracks do
        local track = Config.HorseRacing.tracks[i]
        Tracks[i] = {
            id = i,
            stage = {type = "waiting"},
            label = track.label,
            coords = vector3(track.coords.x, track.coords.y, track.coords.z),
            heading = track.heading,
            distance = track.distance,
            renderDistance = track.renderDistance,
            players = {}
        }
        StartHorseRacingTrackLobby(i)
    end
end

function StartHorseRacingTrackRace(trackId)
    local track = Tracks[trackId]
    if not track then return end
    for source,player in pairs(track.players) do 
        local totalWager = 0
        for a,b in pairs(player.wagers) do 
            totalWager = totalWager + b
        end
        local money = GetMoney(source)
        if money < totalWager then
            track.players[source].wagers = GetDefaultWager()
            TriggerClientEvent("pickle_casinos:horseracing:updateWager", source, track.players[source].casinoId, trackId, track.players[source].wagers)
        else
            LastWagers[source] = track.players[source].wagers
            RemoveMoney(source, totalWager)
        end
    end
    track.stage = {type = "racing", winner = GenerateWinningHorse(track.horses)}
    print("Winner is horse " .. track.stage.winner, "Odds: " .. Config.HorseRacing.odds[track.horses[track.stage.winner].oddsIndex].label)
    TriggerClientEvent("pickle_casinos:horseracing:updateTrackStage", -1, trackId, track.stage)
    Wait(18000)
    local multiplier = Config.HorseRacing.odds[track.horses[track.stage.winner].oddsIndex].multiplier
    for source,player in pairs(track.players) do 
        local winnings = (player.wagers[track.stage.winner] or 0) * multiplier
        if winnings > 0 then
            AddMoney(source, player.wagers[track.stage.winner] + winnings)
            TriggerClientEvent("pickle_casinos:displayResults", source, player.wagers[track.stage.winner] + winnings, GetMoney(source))
        end
    end
    Wait(7000)
    for source,player in pairs(track.players) do 
        player.wagers = GetDefaultWager()
        TriggerClientEvent("pickle_casinos:horseracing:updateWager", source,  track.players[source].casinoId, trackId, player.wagers)
    end
    StartHorseRacingTrackLobby(trackId)
end

function StartHorseRacingTrackLobby(trackId)
    local track = Tracks[trackId]
    if not track then return end
    track.horses = GenerateHorses()
    track.stage = {type = "waiting", time = Config.WaitingTime + 1}
    TriggerClientEvent("pickle_casinos:horseracing:updateTrackStage", -1, trackId, track.stage, track.horses)
    CreateThread(function()
        while track.stage.type == "waiting" and track.stage.time > 1 do
            track.stage.time = track.stage.time - 1
            Wait(1000)
        end
        StartHorseRacingTrackRace(trackId)
    end)
end

function InitializeHorseRacingEntity(casinoId, data)
    local entity = data or { id = "ERR_NO_ID_HORSERACING" }
    return entity
end

function GenerateHorses()
    local horseCount = 12
    local horses = {}
    local multipliersLeft = {}
    for i=1, #Config.HorseRacing.odds do
        multipliersLeft[i] = i
    end
    for i=1, horseCount do
        local horse = {}
        local randomIndex = math.random(1, #multipliersLeft)
        local oddsIndex = multipliersLeft[randomIndex]
        local odds = Config.HorseRacing.odds[oddsIndex]
        horse.oddsIndex = oddsIndex
        table.insert(horses, horse)
        table.remove(multipliersLeft, randomIndex)
    end
    return horses
end

RegisterNetEvent("pickle_casinos:horseracing:setWager", function(casinoId, trackId, wager)
    local source = tonumber(source)
    local casino = Casinos[casinoId]
    if not casino then return end
    local track = Tracks[trackId]
    if not track then return end
    if track.stage.type ~= "waiting" then return end
    local wagers = {}
    if type(wager) == "table" then 
        for i,v in pairs(wager) do
            local subWager = wager[i]
            if subWager then
                local value = tonumber(subWager) or 0
                if value < 0 then value = 0 end
                wagers[tonumber(i)] = value
            else
                wagers[tonumber(i)] = 0
            end
        end
        local totalWager = 0
        for i=1, #wagers do
            totalWager = totalWager + wagers[i]
        end
        local money = GetMoney(source)
        if money < totalWager then      
            wagers = track.players[source] and (track.players[source].wagers or GetDefaultWager()) or GetDefaultWager()  
        end
    elseif wager == "repeat" then
        wagers = LastWagers[source] or GetDefaultWager()
        local totalWager = 0
        for i=1, #wagers do
            totalWager = totalWager + wagers[i]
        end
        if totalWager <= 0 or totalWager > GetMoney(source) then
            wagers = GetDefaultWager()
        end
    else
        wagers = GetDefaultWager()
    end
    track.players[source] = {casinoId = casinoId, wagers = wagers}
    TriggerClientEvent("pickle_casinos:horseracing:updateWager", source, casinoId, trackId, track.players[source].wagers)
end)

CreateThread(function()
    Wait(100)
    InitializeHorseRacingTracks()
    Wait(1000)
    TriggerClientEvent("pickle_casinos:horseracing:updateTracks", -1, Tracks)
end)

RegisterCallback("pickle_casinos:horseracing:getHorseRacingInfo", function(source, cb)
    cb({
        money = GetMoney(source),
        tracks = Tracks,
    })
end)

-- CreateThread(function()
--     local chances = {}
--     local stack = {}
    -- for i=1, #Config.HorseRacing.odds do
    --     local odds = Config.HorseRacing.odds[i]
    --     for j=1, odds.chances do
    --         table.insert(stack, i)
    --     end
    -- end
--     local playLeft = 1000
--     repeat
--         local randomIndex = math.random(1, #stack)
--         local randomOdds = stack[randomIndex]
--         local odds = Config.HorseRacing.odds[randomOdds]
--         local oddsLabel = odds.label
--         chances[oddsLabel] = (chances[oddsLabel] or 0) + 1
--         playLeft = playLeft - 1
--     until playLeft <= 0
--     for k,v in pairs(chances) do
--         print("Percentage of " .. k .. ": " .. ((v / 1000) * 100) .. "%")
--     end
-- end)