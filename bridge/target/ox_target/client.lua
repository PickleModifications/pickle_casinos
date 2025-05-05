if GetResourceState('ox_target') ~= 'started' or not Config.UseTarget then return end

function AddTargetModel(models, radius, options)
    local optionsNames = {}
    for i=1, #options do 
        optionsNames[i] = options[i].name
    end
    RemoveTargetModel(models, optionsNames)
    exports.ox_target:addModel(models, options)
end

function RemoveTargetModel(models, optionsNames)
    exports.ox_target:removeModel(models, optionsNames)
end

function AddTargetZone(coords, radius, defaultOptions, defaultIcon, distance)
    local options = {}
    for i=1, #defaultOptions do 
        options[i] = defaultOptions[i]
        if not options[i].icon then
            options[i].icon = defaultIcon
        end
        options[i].distance = distance
    end
    return exports.ox_target:addSphereZone({
        coords = coords,
        radius = radius,
        options = options
    })
end

function RemoveTargetZone(index)
    exports.ox_target:removeZone(index)
end

function GetOptionNames(options)
    local optionsNames = {}
    for i=1, #options do 
        optionsNames[i] = options[i].name
    end
    return optionNames
end

function AddTargetNetworkId(networkId, options)
    RemoveTargetNetworkId(networkId, options)
    exports.ox_target:addEntity(networkId, options)
end

function RemoveTargetNetworkId(networkId, options)
    exports.ox_target:removeEntity(networkId, GetOptionNames(options))
end

function AddTargetGlobalVehicle(options)
    RemoveTargetGlobalVehicle(options)
    exports.ox_target:addGlobalVehicle(options)
end

function RemoveTargetGlobalVehicle(options)
    for i=1, #options do 
        exports.ox_target:removeGlobalVehicle(options[i].name)
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
            options[i].onSelect = function(data)
                local entity = data.entity
                for _, player in ipairs(GetActivePlayers()) do
                    if entity == GetPlayerPed(player) then
                        return options[i].onSelected(GetPlayerServerId(player))
                    end
                end
            end
        end
    end
    exports.ox_target:addGlobalPlayer(options)
end

function RemoveTargetGlobalPlayer(options)
    exports.ox_target:removeGlobalPlayer(GetOptionNames(options))
end