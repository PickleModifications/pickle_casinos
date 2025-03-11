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

    return assert(load(data, ('@@%s/%s'):format(resourceName, path), 't', _ENV)())
end

---@type OxClient
local Ox = loadFile('ox_core', 'lib/init.lua')

if not lib then
    return warn("Unable to load ox_lib")
end

if not Ox then
    return warn("Unable to load ox_core")
end

---@param name string
---@param cb function
function RegisterCallback(name, cb)
    lib.callback.register(name, cb)
end

function RegisterUsableItem()
    
end

---@param target number
---@param text string
function ShowNotification(target, text)
    lib.notify(target, {
        description = text
    })
end

---@param source number
---@return string?
function GetIdentifier(source)
    local player = Ox.GetPlayer(source)
    if not player or not player.charId then
        return
    end

    return player.charId
end

---@param identifier string
---@return number?
function GetSourceFromIdentifier(identifier)
    local player = Ox.GetPlayerFromFilter({ identifier = identifier })
    if not player then
        return
    end
    return player.source
end

---@param source number
function GetPlayerCharacterName(source)
    local player = Ox.GetPlayer(source)
    if not player or not player.charId then
        --- Player has not selected a character
        return "Unknown Name"
    end

    return player.get("firstName") .. " " .. player.get("lastName")
end

local inventory = exports.ox_inventory

function AddMoney(source, count)
    inventory:AddItem(source, "money", count)
end

function AddDirtyMoney(source, count)
    inventory:AddItem(source, "black_money", count)
end

function RemoveMoney(source, count)
    inventory:RemoveItem(source, "money", count)
end

---@param plate string
---@return {owner: number}?
function GetOwnedVehicleFromPlate(plate)
    local owner = MySQL.scalar.await("SELECT `owner` FROM `vehicles` WHERE `plate` = ?", {
        plate
    })

    return owner and {owner = owner} or nil
end

function AddOwnedVehicle(source, plate, model)
    local player = Ox.GetPlayer(source)
    if not player or not player.charId then
        return warn(("Attempted to add owned vehicle for player %i, but they haven't selected a character"):format(source))
    end

    Ox.CreateVehicle({
        model = model,
        plate = plate,
        -- Locates it in the impound
        stored = "impound",
        owner = player.charId
    })
end

---@param source number
---@param oldPlate string
---@param newPlate string
function UpdateVehiclePlate(source, oldPlate, newPlate)
    local player = Ox.GetPlayer(source)

    if not player or not player.charId then
        return
    end

    local handle = GetVehiclePedIsIn(player.ped, false)
    if not handle then
        return
    end

    local vehicle = Ox.GetVehicle(handle)

    if not vehicle then
        warn(("Vehicle %i isn't a ox_core created vehicle"):format(handle))
        return
    end

    vehicle.setPlate(newPlate)
    local properties = vehicle.get("properties")
    if properties then
        properties.plate = properties.plate and newPlate or nil
        vehicle.setProperty(properties, false)
    end
end

function GetPlayerJob(source)
    --- A player can be apart of dozens of groups. 
    --- And they can also have an 'activeGroup'. 
    --- So we check activeGroup then fetch another group if they don't have an activeGroup
    local player = Ox.GetPlayer(source)
    if not player or not player.charId then
        --- Player doesn't exist or hasn't selected a character
        return { label = "Unknown Job", rank_label = "Unknown Grade" }
    end

    --- We check their activeGroup
    local activeGroup = player.get("activeGroup")

    -- Fetch a random group the user is apart of if they don't have an activeGroup
    if not activeGroup then
        local groups = player.getGroups()
        local groupName, groupGrade = next(groups)

        if groupName and groupGrade then
           local groupData = Ox.GetGroup(groupName)
           return { label = groupName, rank_label = groupData.grades[groupGrade] }
        end
    end

    local groupData = Ox.GetGroup(activeGroup)
    return { label = activeGroup, rank_label = groupData.grades[Ox.GetGroup(activeGroup)] }
end

---@param source number
---@param job string
---@param grade number
function SetPlayerJob(source, job, grade)
    local player = Ox.GetPlayer(source)
    if not player or not player.charId then
        return
    end

    local group = Ox.GetGroup(job)
    -- Warn in console that the group doesn't exist
    if not group then
        lib.print.warn(("Attempted to give group %s to %i (%s), however the group doesn't exist"):format(job, source, player.username))
        return
    end

    player.setGroup(job, grade)
end

CreateThread(function()
    Wait(100)

    if InitializeInventory then return InitializeInventory() end -- Already loaded through inventory folder.

    Inventory = {
        Items = {},
        Ready = false
    }

    function Inventory.CanCarryItem(source, name, count)
        return inventory:CanCarryItem(source, name, count)
    end

    function Inventory.GetInventory(source)
        return inventory:GetInventory(source)
    end

    function Inventory.UpdateInventory(source)
    end

    function Inventory.AddItem(source, name, count)
        inventory:AddItem(source, name, count)
    end

    function Inventory.RemoveItem(source, name, count)
        inventory:RemoveItem(source, name, count)
    end

    function Inventory.AddWeapon(source, name)
        inventory:AddItem(source, name, 1)
    end

    function Inventory.RemoveWeapon(source, name)
        inventory:RemoveItem(source, name)
    end

    function Inventory.GetItemCount(source, name)
        return inventory:GetItemCount(source, name)
    end

    function Inventory.HasWeapon(source, name)
        return inventory:Search(source, 'count', name) > 0
    end

    RegisterCallback("pickle_multiplayerjobs:getInventory", function(source, cb)
        cb(Inventory.GetInventory(source))
    end)

    Inventory.Items = inventory:Items()
end)