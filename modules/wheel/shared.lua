WheelSections = {
    -- Top Left
    "twentyThree", "two", "five", "three", "two", "three", "two", "five", "three", "two",
    -- Bottom Left
    "eleven", "two", "five", "three", "two", "three", "two", "five", "three", "two",
    -- Bottom Right
    "bonus", "two", "five", "three", "two", "three", "two", "five", "three", "two", 
    -- Top Right
    "eleven", "two", "five", "three", "two", "three", "two", "five", "three", "two",
}

function GetSectionForDegrees(degrees)
    local sectionLength = 360 / #WheelSections
    local section = math.floor(degrees / sectionLength) + 1
    if section > #WheelSections then
        section = 1
    end
    return WheelSections[section]
end

function GetSafeDegrees(degrees)
    local sectionLength = 360 / #WheelSections
    local safestDegree = sectionLength / 2
    repeat 
        safestDegree = safestDegree + sectionLength
    until safestDegree >= degrees
    local safeDegree = safestDegree - (sectionLength)
    local positive = math.random(0, 1)
    local modifier = ((sectionLength / 2.5) * (math.random(1, 100) / 100))
    if positive == 1 then
        safeDegree = safeDegree + modifier
    else
        safeDegree = safeDegree - modifier
    end
    return safeDegree
end