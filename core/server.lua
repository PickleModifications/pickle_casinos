function GetPlayerIdentifiersArray(source)
    local source = tonumber(source)
    if not source then return {} end
    local identifierTypes = {"steam", "discord", "xbl", "live", "license", "license2", "fivem", "ip"}
    local identifiers = {}
    for i=1, #identifierTypes do
        local identifier = GetPlayerIdentifierByType(source, identifierTypes[i])
        if identifier then
            table.insert(identifiers, identifier)
        end
    end
    return identifiers
end

function GetFilteredPlayerIdentifiers(source)
    local source = tonumber(source)
    if not source then return end
    local identifiers = GetPlayerIdentifiersArray(source)
    local filteredIdentifiers = {}
    for i=1, #identifiers do
        if not string.match(identifiers[i], "ip:") or not Config.DisableIPIdentifier then
            table.insert(filteredIdentifiers, identifiers[i])
        end
    end
    return filteredIdentifiers
end

function GetPlayerPrefixIdentifier(source)
    local source = tonumber(source)
    if not source then return end
    local prefix = Config.IdentifierPrefix
    local identifiers = GetPlayerIdentifiersArray(source)
    for i=1, #identifiers do
        if string.match(identifiers[i], prefix .. ":") then
            return identifiers[i]
        end
    end
    if prefix == "license2" then
        for i=1, #identifiers do
            if string.match(identifiers[i], "license:") then
                return identifiers[i]
            end
        end
    end  
end

function TriggerClientCasinoEvent(eventName, target, casinoId, entityId, ...)
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    -- HANDLE GRID COORDS HERE IF SUPER COOL AND AWESOME
    TriggerClientEvent(eventName, target, casinoId, entityId, ...)
end

function StartCasinoGameplayTransaction(source, casinoId, entityId, gameType, wagerAmount)
    local id = os.time() .. "_" .. source
    TriggerEvent("pickle_casinos:gameplay:startTransaction", id, source, casinoId, entityId, gameType, wagerAmount)
    return id
end

function EndCasinoGameplayTransaction(id, source, casinoId, entityId, gameType, winAmount)
    TriggerEvent("pickle_casinos:gameplay:endTransaction", id, source, casinoId, entityId, gameType, winAmount)
end