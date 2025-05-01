LuckyWheelSections = {
    "money_50k", "vehicle", "rp_15k", "clothing", "chips_25k", "money_40k", "rp_10k", "clothing", "mystery", 
    "chips_20k", "rp_7k", "clothing", "chips_15k", "money_30k", "rp_5k", "discount", "chips_10k", "money_20k", "rp_2k", "clothing", 
}

function GetLuckyWheelSectionForDegrees(degrees)
    local sectionLength = 360 / #LuckyWheelSections
    local section = math.floor(degrees / sectionLength)
    if section > #LuckyWheelSections then
        section = 1
    end
    return LuckyWheelSections[section]
end

function GetLuckyWheelSafeDegrees(degrees)
    local sectionLength = 360 / #LuckyWheelSections
    local safestDegree = sectionLength / 2
    repeat 
        safestDegree = safestDegree + sectionLength
    until safestDegree >= degrees
    local safeDegree = safestDegree - (sectionLength / 2)
    -- local positive = math.random(0, 1)
    -- local modifier = ((sectionLength / 2.5) * (math.random(1, 100) / 100))
    -- if positive == 1 then
    --     safeDegree = safeDegree + modifier
    -- else
    --     safeDegree = safeDegree - modifier
    -- end
    return safeDegree
end