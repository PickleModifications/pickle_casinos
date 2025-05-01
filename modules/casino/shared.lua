Casinos = {}

local CHIP_VALUATIONS = {
    { value = 10, model = `vw_prop_chip_10dollar_x1` },
    { value = 50, model = `vw_prop_chip_50dollar_x1` },
    { value = 100, model = `vw_prop_chip_100dollar_x1` },
    { value = 500, model = `vw_prop_chip_500dollar_x1` },
    { value = 1000, model = `vw_prop_chip_1kdollar_x1` },
    { value = 5000, model = `vw_prop_plaq_5kdollar_x1` },
    { value = 10000, model = `vw_prop_plaq_10kdollar_x1` },
}

function GetCardModel(class, value)
    if class == "hidden" then
        return GetHashKey("vw_prop_cas_card_club_ace")
    end
    return GetHashKey("vw_prop_cas_card_" .. class .. "_" .. value)
end

function GetCalculatedChips(amount, maxStack)
    if amount <= 0 then return {} end
    local chips = {}
    local remainingAmount = amount
    repeat
        local highestChip = CHIP_VALUATIONS[1]
        for i=1, #CHIP_VALUATIONS do
            local chip = CHIP_VALUATIONS[i]
            if chip.value <= remainingAmount then
                highestChip = chip
            end
        end
        if highestChip then
            table.insert(chips, highestChip)
            remainingAmount = math.max(0, remainingAmount - highestChip.value)
        end
        if remainingAmount < CHIP_VALUATIONS[1].value then break end
    until (remainingAmount <= 0 or #chips >= (maxStack or 10))
    return chips
end

function GetFormattedTime(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    local dayStr = days > 1 and "s" or ""
    if days > 0 then
        string.format((days > 0 and ("%d day"..dayStr .. " ") or "").."%02d:%02d:%02d", days, hours, minutes, secs)
    else
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    end
end