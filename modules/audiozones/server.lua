local function GetAudioZone(casino, zoneId)
    if not casino.settings.audio_zones then return nil, nil end
    for i = 1, #casino.settings.audio_zones do
        if casino.settings.audio_zones[i].id == zoneId then
            return casino.settings.audio_zones[i], i
        end
    end
    return nil, nil
end

local function SaveAndSync(casinoId, casino)
    MySQL.Async.execute('UPDATE `pickle_casinos` SET settings = ? WHERE id = ?', {json.encode(casino.settings), casinoId})
    TriggerClientEvent("pickle_casinos:syncAudioZones", -1, casinoId, casino.settings.audio_zones)
end

RegisterNetEvent("pickle_casinos:addAudioZone", function(casinoId, zoneData)
    local source = source
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    if casino.settings.label == PERSONAL_CASINOS_LABEL then return end
    if not GetAudioPreset(zoneData.preset) then return end

    if not casino.settings.audio_zones then
        casino.settings.audio_zones = {}
    end

    local points = {}
    if zoneData.points then
        for i = 1, #zoneData.points do
            local p = zoneData.points[i]
            if p and p.x and p.y and p.z then
                table.insert(points, { x = p.x, y = p.y, z = p.z })
            end
        end
    end

    local zone = {
        id = math.random(100000, 999999),
        preset = zoneData.preset,
        points = points,
    }

    table.insert(casino.settings.audio_zones, zone)
    SaveAndSync(casinoId, casino)
end)

RegisterNetEvent("pickle_casinos:deleteAudioZone", function(casinoId, zoneId)
    local source = source
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    if not casino.settings.audio_zones then return end

    for i = #casino.settings.audio_zones, 1, -1 do
        if casino.settings.audio_zones[i].id == zoneId then
            table.remove(casino.settings.audio_zones, i)
            break
        end
    end

    SaveAndSync(casinoId, casino)
end)

RegisterNetEvent("pickle_casinos:addAudioZonePoint", function(casinoId, zoneId, coords)
    local source = source
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end
    if not coords or not coords.x or not coords.y or not coords.z then return end

    local zone = GetAudioZone(casino, zoneId)
    if not zone then return end

    table.insert(zone.points, { x = coords.x, y = coords.y, z = coords.z })
    SaveAndSync(casinoId, casino)
end)

RegisterNetEvent("pickle_casinos:deleteAudioZonePoint", function(casinoId, zoneId, pointIndex)
    local source = source
    if not CanManageCasino(source, casinoId) then return ShowNotification(source, _L("no_permission")) end
    local casino = Casinos[casinoId]
    if not casino then return end

    local zone = GetAudioZone(casino, zoneId)
    if not zone then return end

    pointIndex = tonumber(pointIndex)
    if not pointIndex or pointIndex < 1 or pointIndex > #zone.points then return end

    table.remove(zone.points, pointIndex)
    SaveAndSync(casinoId, casino)
end)
