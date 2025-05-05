if GetResourceState('ox_target') == 'started' or GetResourceState('qtarget') ~= 'started' or not Config.UseTarget then return end

local Zones = {}

function AddTargetModel(models, radius, options)
    local optionsNames = {}
    for i=1, #options do 
        optionsNames[i] = options[i].name
    end
    RemoveTargetModel(models, optionsNames)
    exports['qtarget']:AddTargetModel(models, {options = options, distance = 2.5})
end

function RemoveTargetModel(models, optionsNames)
    exports['qtarget']:RemoveTargetModel(models, optionsNames)
end

function AddTargetZone(coords, radius, options)
    local index
    repeat
        index = "bailbounty_coord_" .. math.random(1, 999999999)
    until not Zones[index]
    exports['qtarget']:AddBoxZone(index, coords, radius, distance, {
        name = index,
        heading = 0.0,
        minZ = coords.z,
        maxZ = coords.z + radius,
    }, {
        options = options,
    })
    return index
end

function RemoveTargetZone(index)
    Zones[index] = nil
    exports['qtarget']:RemoveZone(index)
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
    RemoveTargetNetworkId(networkId, options)
    local entity = NetToPed(networkId)
    exports.qtarget:AddTargetEntity(entity, options)
end

function RemoveTargetNetworkId(networkId, options)
    if not NetworkDoesNetworkIdExist(networkId) then return end
    local entity = NetToPed(networkId)
    exports.qtarget:RemoveTargetEntity(entity, GetOptionNames(options))
end

function AddTargetGlobalVehicle(options)
    RemoveTargetGlobalVehicle(options)
    exports.qtarget:Vehicle(options)
end

function RemoveTargetGlobalVehicle(options)
    for i=1, #options do 
        exports.qtarget:RemoveVehicle(options[i].name)
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
    exports.qtarget:Player(options)
end

function RemoveTargetGlobalPlayer(options)
    exports.qtarget:RemovePlayer(GetOptionNames(options))
end