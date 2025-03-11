-- Shoutout to Ehbw for making this bridge for OX Core
-- You can view the original code here: https://gist.github.com/Ehbw/5d2b5a14839d5386090101215caf05fc

if GetResourceState('ox_lib') ~= 'started' then return end
if GetResourceState('ox_core') ~= 'started' then return end
if GetResourceState('ox_inventory') ~= 'started' then return end

---@param resourceName string
---@param path string
local function loadFile(resourceName, path)
    local data = LoadResourceFile(resourceName, path)

    if not data or string.len(data) == 0 then
        return warn(("Unable to load file @%s/%s"):format(resourceName, path))
    end

    return assert(load(data, ('@@%s/%s'):format(resourceName, path), 't', _ENV))
end

-- lib will be loaded into the ENV
loadFile('ox_lib', 'init.lua')

---@type OxClient
local Ox = loadFile('ox_core', 'lib/init.lua')

if not lib then
    return warn("Unable to load ox_lib")
end

if not Ox then
    return warn("Unable to load ox_core")
end

function ShowNotification(text)
    lib.notify({
        description = text
    })
end

function ServerCallback(name, cb, ...)
    lib.callback(name, false, cb, ...)
end

---@param coords vector3
---@param radius number
function GetPlayersInArea(coords, radius)
    return lib.getNearbyPlayers(coords and coords.xyz or GetEntityCoords(cache.playerId), radius or 3.0)
end

function Kill()
    SetEntityHealth(cache.ped, 0)
end

RegisterNetEvent(("%s:showNotification"):format(cache.resource), function(text)
    ShowNotification(text)
end)

--- This call can be done on the server if not for the event
AddEventHandler("ox:playerLoaded", function (playerId, isNew)
    TriggerServerEvent("pickle_multiplayerjobs:initializePlayer")
end)

CreateThread(function()
    Wait(100)

    Inventory = {
        Items = {},
        Ready = false
    }

    --- ?
    RegisterNetEvent("pickle_multiplayerjobs:setupInventory", function(data)
        Inventory.Items = data.items
        Inventory.Ready = true
    end)
end)