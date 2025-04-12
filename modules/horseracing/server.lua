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
    print("Generated horses:")
    for i=1, #horses do
        local horse = horses[i]
        local odds = Config.HorseRacing.odds[horse.oddsIndex]
        print("Horse " .. i .. ": " .. odds.label)
    end
end

CreateThread(function()
    GenerateHorses()
end)

-- CreateThread(function()
--     local chances = {}
--     local stack = {}
--     for i=1, #Config.HorseRacing.odds do
--         local odds = Config.HorseRacing.odds[i]
--         for j=1, odds.chances do
--             table.insert(stack, i)
--         end
--     end
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