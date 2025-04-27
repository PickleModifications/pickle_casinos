local MapObjects = {}
local LocalMapObjects = {}
local TransparentObjects = {}
local IN_MAP_MODE = false

function GetDirectionFromRotation(rotation)
    local dm = (math.pi / 180)
    return vector3(-math.sin(dm * rotation.z) * math.abs(math.cos(dm * rotation.x)), math.cos(dm * rotation.z) * math.abs(math.cos(dm * rotation.x)), math.sin(dm * rotation.x))
end

function GetDirectionCoords()
    local range = 1000.0
	local coords = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local dir = GetDirectionFromRotation(rot)
	local ecoords = vector3(coords.x + dir.x * range, coords.y + dir.y * range, coords.z + dir.z * range)
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(StartShapeTestRay(coords.x, coords.y, coords.z, ecoords.x, ecoords.y, ecoords.z, -1, -1, 1))
	return hit, endCoords, entityHit 
end

function EnsureMapObjectsRemoved()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    for k, v in pairs(MapObjects) do
        if #(playerCoords - v.coords) < Config.RenderDistance then
            if not LocalMapObjects[k] then
                LocalMapObjects[k] = true
                local object = GetClosestObjectOfType(v.coords, 0.5, v.model, false, false, false)
                local objectCoords = GetEntityCoords(object)
                if #(objectCoords - v.coords) < 0.5 and not TransparentObjects[k] and not IsEntityScriptObject(object) then
                    debugPrint("DELETE OBJ", object, v.coords)
                    SetEntityAsMissionEntity(object)
                    DeleteEntity(object)
                end
            end
        elseif LocalMapObjects[k] then
            LocalMapObjects[k] = nil
        end
    end
end

function IsObjectMapObject(object)
    local model = GetEntityModel(object)
    local coords = GetEntityCoords(object)
    for k, v in pairs(MapObjects) do
        if v.model == model and #(coords - v.coords) < 0.5 then
            return true
        end
    end
    return false
end

function EnsureMapObjectsTransparent()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local objects = GetGamePool('CObject')
    for k, v in pairs(MapObjects) do
        if not TransparentObjects[k] then
            if #(playerCoords - v.coords) < Config.RenderDistance then
                local foundObject 
                for i=1, #objects do
                    local object = objects[i]
                    local objectCoords = GetEntityCoords(object)
                    if #(objectCoords - v.coords) < 0.5 and not IsEntityScriptObject(object) then
                        foundObject = object
                    end
                end
                if not foundObject then
                    local model = v.model
                    RequestModel(model)
                    while not HasModelLoaded(model) do
                        Wait(0)
                    end
                    foundObject = CreateObject(model, v.coords, false, false, false)
                end
                SetEntityRotation(foundObject, v.rotation.x, v.rotation.y, v.rotation.z, 2, true)
                SetEntityAlpha(foundObject, 128, false)
                FreezeEntityPosition(foundObject, true)
                TransparentObjects[k] = foundObject
            end
        end
    end
end

RegisterNetEvent("pickle_casinos:objects:toggleMapMode", function(mapObjects, toggle)
    if toggle then
        if IN_MAP_MODE then return end
        debugPrint("START MAP MODE")
        MapObjects = mapObjects
        IN_MAP_MODE = true
        EnsureMapObjectsRemoved()
        EnsureMapObjectsTransparent()
        local spriteDict, sprite = "darts", "dart_reticules"
        local currentEntity = nil
        while IN_MAP_MODE do 
            ShowInteractText(
                '[G]     - Add Detected Models  \n' ..
                '[E]     - Toggle Entity'
            )
            if IsControlJustPressed(1, 47) then
                local newMapObjects = {}
                local objects = GetGamePool('CObject')
                for i=1, #objects do 
                    local object = objects[i]
                    local model = GetEntityModel(object)
                    local isTargetModel = false
                    for j=1, #Config.TargetedModels do
                        if model == Config.TargetedModels[j] then
                            isTargetModel = true
                            break
                        end
                    end
                    if isTargetModel and not IsEntityScriptObject(object) and not IsObjectMapObject(object) then
                        local objectCoords = GetEntityCoords(object)
                        local objectRotation = GetEntityRotation(object, 2)
                        newMapObjects[#newMapObjects + 1] = {
                            model = model,
                            coords = objectCoords,
                            rotation = objectRotation
                        }
                    end
                end
                TriggerServerEvent("pickle_casinos:objects:addMapObjects", newMapObjects)
            end
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local hit, coords, entity = GetDirectionCoords()
            RequestStreamedTextureDict(spriteDict, false)
            
            if hit and coords and #(playerCoords - coords) < 5.0 and entity and GetEntityType(entity) == 3 and not IsEntityScriptObject(entity) then
                if not currentEntity or currentEntity ~= entity then
                    if currentEntity then
                        SetEntityDrawOutline(currentEntity, false)
                    end
                    SetEntityDrawOutline(entity, true)
                    SetEntityDrawOutlineColor(255, 0, 0, 255)
                    currentEntity = entity
                end 
                if IsControlJustPressed(1, 51) then
                    TriggerServerEvent("pickle_casinos:objects:toggleMapObject", GetEntityModel(entity), GetEntityCoords(entity), GetEntityRotation(entity))
                end
                DrawSprite(spriteDict, sprite, 0.5, 0.5, 0.015, 0.025, 180.0, 0, 255, 0, 255)
            else
                DrawSprite(spriteDict, sprite, 0.5, 0.5, 0.015, 0.025, 180.0, 255, 255, 255, 255)
                if currentEntity then
                    SetEntityDrawOutline(currentEntity, false)
                    currentEntity = nil
                end
            end
            Wait(0)
        end
        for k,v in pairs(TransparentObjects) do
            if DoesEntityExist(v) then
                SetEntityAsMissionEntity(v)
                DeleteEntity(v)
                TransparentObjects[k] = nil
            end
        end
        if currentEntity then
            SetEntityDrawOutline(currentEntity, false)
            currentEntity = nil
        end
        EnsureMapObjectsRemoved()
    else
        IN_MAP_MODE = false
    end
end)

RegisterNetEvent("pickle_casinos:objects:removeMapObject", function(objectId)
    debugPrint("REMOVING", objectId)
    if MapObjects[objectId] then
        if TransparentObjects[k] then
            SetEntityAsMissionEntity(TransparentObjects[objectId])
            DeleteEntity(TransparentObjects[objectId])
            TransparentObjects[objectId] = nil
        end
        local model = MapObjects[objectId].model
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
        local v = MapObjects[objectId]
        foundObject = CreateObject(model, v.coords, false, false, false)
        SetEntityRotation(foundObject, v.rotation.x, v.rotation.y, v.rotation.z, 2, true)
        FreezeEntityPosition(foundObject, true)
        MapObjects[objectId] = nil
    end
end)

RegisterNetEvent("pickle_casinos:objects:addMapObject", function(objectId, objectData)
    debugPrint("ADDING", objectId, objectData)
    MapObjects[objectId] = objectData
    if IN_MAP_MODE then
        EnsureMapObjectsTransparent()
    end
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local objects = GetGamePool('CObject')
    local k = objectId
    local v = objectData
    if #(playerCoords - v.coords) < Config.RenderDistance then
        for i=1, #objects do
            local object = objects[i]
            local objectCoords = GetEntityCoords(object)
            if #(objectCoords - v.coords) < 0.5 and TransparentObjects[k] ~= object and not IsEntityScriptObject(object) then
                SetEntityAsMissionEntity(object)
                DeleteEntity(object)
                debugPrint("DELETE OBJ2", object, v.coords)
            end
        end
    end
end)

RegisterNetEvent("pickle_casinos:objects:updateMapObjects", function(mapObjects)
    for k, v in pairs(MapObjects) do
        if not mapObjects[k] then
            if TransparentObjects[k] then
                SetEntityAsMissionEntity(TransparentObjects[k])
                DeleteEntity(TransparentObjects[k])
                TransparentObjects[k] = nil
            end
            MapObjects[k] = nil
        end
    end
    for k, v in pairs(mapObjects) do
        if not MapObjects[k] then
            MapObjects[k] = v
        end
    end
    EnsureMapObjectsRemoved()
    if IN_MAP_MODE then
        EnsureMapObjectsTransparent()
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k, v in pairs(TransparentObjects) do
            if DoesEntityExist(v) then
                SetEntityAsMissionEntity(v)
                DeleteEntity(v)
            end
        end
    end
end)

CreateThread(function()
    while true do 
        if not IN_MAP_MODE then
            EnsureMapObjectsRemoved()
        end
        Wait(1500)
    end
end)