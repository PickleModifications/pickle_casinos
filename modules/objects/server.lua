local MapObjects = {}
local PlayersEditing = {}

function InitializeMapObjects()
    local text = LoadResourceFile("pickle_casinos", "mapobjects.json") or "{}"
    local data = json.decode(text) or {}
    for k, v in pairs(data) do
        MapObjects[k] = {
            model = v.model,
            coords = vector3(v.coords.x, v.coords.y, v.coords.z),
            rotation = vector3(v.rotation.x, v.rotation.y, v.rotation.z),
        }
    end
end

function UpdateMapObjects()
    SaveResourceFile("pickle_casinos", "mapobjects.json", json.encode(MapObjects, {indent = true}), -1)
end

function GetMapObjectFromData(model, coords, rotation)
    for k,v in pairs(MapObjects) do
        if v.model == model and #(v.coords - coords) < 0.1 then
            return k, v
        end
    end
end

function UpdateObjects(source)
    TriggerClientEvent("pickle_casinos:objects:updateMapObjects", -1, MapObjects)
end

RegisterNetEvent("pickle_casinos:objects:toggleMapObject", function(model, coords, rotation)
    local objectId, objectData = GetMapObjectFromData(model, coords, rotation)
    if objectId then
        MapObjects[objectId] = nil
        UpdateMapObjects()
        TriggerClientEvent("pickle_casinos:objects:removeMapObject", -1, objectId)
    else
        local objectId
        repeat
            objectId = math.random(1, 999999) .. "_" .. math.random(1, 999999)
        until not MapObjects[objectId]
        MapObjects[objectId] = {
            model = model,
            coords = vector3(coords.x, coords.y, coords.z),
            rotation = vector3(rotation.x, rotation.y, rotation.z),
        }
        UpdateMapObjects()
        TriggerClientEvent("pickle_casinos:objects:addMapObject", -1, objectId, MapObjects[objectId])
    end
end)

RegisterNetEvent("pickle_casinos:objects:addMapObjects", function(objects)
    for i=1, #objects do 
        local model = objects[i].model
        local coords = objects[i].coords
        local rotation = objects[i].rotation
        local objectId, objectData = GetMapObjectFromData(model, coords, rotation)
        if not objectId then
            local objectId
            repeat
                objectId = math.random(1, 999999) .. "_" .. math.random(1, 999999)
            until not MapObjects[objectId]
            MapObjects[objectId] = {
                model = model,
                coords = vector3(coords.x, coords.y, coords.z),
                rotation = vector3(rotation.x, rotation.y, rotation.z),
            }
        end
    end
    UpdateMapObjects()
    TriggerClientEvent("pickle_casinos:objects:updateMapObjects", -1, MapObjects)
end)

RegisterCommand("mapobjects", function(source, args, rawCommand)
    PlayersEditing[source] = not PlayersEditing[source]
    TriggerClientEvent("pickle_casinos:objects:toggleMapMode", source, MapObjects, PlayersEditing[source])
end, false)

CreateThread(function()
    InitializeMapObjects()
end)