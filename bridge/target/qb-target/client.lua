if GetResourceState('ox_target') == 'started' or GetResourceState('qb-target') ~= 'started' or not Config.UseTarget then return end

local Zones = {}

function AddTargetModel(models, radius, options)
    local optionsNames = {}
    for i=1, #options do 
        optionsNames[i] = options[i].name
        if options[i].onSelect then
            local cb = options[i].onSelect
            options[i].action = function(entity)
                cb({entity = entity})
            end
            options[i].onSelect = nil
        end
    end
    RemoveTargetModel(models, optionsNames)
    exports['qb-target']:AddTargetModel(models, {options = options, distance = 2.5})
end

function RemoveTargetModel(models, optionsNames)
    exports['qb-target']:RemoveTargetModel(models, optionsNames)
end

function AddTargetZone(coords, radius, options, defaultIcon, distance)
    local index
    repeat
        index = "bailbounty_coord_" .. math.random(1, 999999999)
    until not Zones[index]
    for i=1, #options do 
        if options[i].onSelect then
            local cb = options[i].onSelect
            options[i].action = function(entity)
                cb({entity = entity})
            end
            options[i].onSelect = nil
        end
        if not options[i].icon then
            options[i].icon = defaultIcon or nil
        end
    end
    exports['qb-target']:AddCircleZone(index, coords, radius, {name = index}, {
        options = options,
        distance = distance
    })
    return index
end

function RemoveTargetZone(index)
    if not index then return end
    Zones[index] = nil
    exports['qb-target']:RemoveZone(index)
end


function GetOptionNames(options)
    local optionsNames = {}
    for i=1, #options do 
        optionsNames[i] = options[i].label
    end
    return optionNames
end

function AddTargetNetworkId(networkId, options)
    if not NetworkDoesNetworkIdExist(networkId) then return end
    local entity = NetworkGetEntityFromNetworkId(networkId)
    RemoveTargetNetworkId(networkId, options)
    for i=1, #options do
        if options[i].onSelect then
            local cb = options[i].onSelect
            options[i].action = function(entity)
                cb({entity = entity})
            end
            options[i].onSelect = nil
        end
    end
    exports["qb-target"]:AddTargetEntity(entity, {options = options, distance = 2.5})
end

function RemoveTargetNetworkId(networkId, options)
    if not NetworkDoesNetworkIdExist(networkId) then return end
    local entity = NetworkGetEntityFromNetworkId(networkId)
    exports["qb-target"]:RemoveTargetEntity(entity, GetOptionNames(options))
end

function AddTargetGlobalVehicle(options)
    RemoveTargetGlobalVehicle(options)
    for i=1, #options do
        if options[i].onSelect then
            local cb = options[i].onSelect
            options[i].action = function(entity)
                cb({entity = entity})
            end
            options[i].onSelect = nil
        end
    end
    exports["qb-target"]:AddGlobalVehicle({options = options, distance = 2.5})
end

function RemoveTargetGlobalVehicle(options)
    for i=1, #options do 
        exports["qb-target"]:RemoveGlobalVehicle(options[i].label)
    end
end

local TargetPlayers = {}

function AddTargetGlobalPlayer(options)
    RemoveTargetGlobalPlayer(options)
    for i=1, #options do
        if options[i].interactCheck then
            options[i].canInteract = function(entity)
                for _, player in ipairs(GetActivePlayers()) do
                    if entity == GetPlayerPed(player) then
                        return options[i].interactCheck(GetPlayerServerId(player))
                    end
                end
                return false
            end
        end
        if options[i].onSelected then
            options[i].action = function(entity)
                for _, player in ipairs(GetActivePlayers()) do
                    if entity == GetPlayerPed(player) then
                        return options[i].onSelected(GetPlayerServerId(player))
                    end
                end
            end
        end
    end
    exports["qb-target"]:AddGlobalPlayer({options = options, distance = 2.5})
end

function RemoveTargetGlobalPlayer(options)
    exports["qb-target"]:RemoveGlobalPlayer(GetOptionNames(options))
end