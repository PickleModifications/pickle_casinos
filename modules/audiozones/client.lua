local ActiveZones = {}
local ActiveAudio = {}
local playerInZone = nil

-- Preview rendering state
local previewZone = nil
local previewMarkers = nil
local previewMarkerThread = false

-- Audio playback management
local function StartAmbientAudio(casinoId, presetId)
    if ActiveAudio[casinoId] and ActiveAudio[casinoId].playing then return end
    local preset = GetAudioPreset(presetId)
    if not preset then return end

    ActiveAudio[casinoId] = { playing = true, preset = presetId }
    CreateThread(function()
        while not RequestScriptAudioBank("DLC_VINEWOOD/CASINO_GENERAL", false, -1) do
            Wait(100)
        end
        while not RequestScriptAudioBank("DLC_VINEWOOD/CASINO_SLOT_MACHINES_01", false, -1) do
            Wait(100)
        end
        while not RequestScriptAudioBank("DLC_VINEWOOD/CASINO_SLOT_MACHINES_02", false, -1) do
            Wait(100)
        end
        while not RequestScriptAudioBank("DLC_VINEWOOD/CASINO_SLOT_MACHINES_03", false, -1) do
            Wait(100)
        end
        StopStream()
        while not LoadStream("casino_walla", "DLC_VW_Casino_Interior_Sounds") and ActiveAudio[casinoId].playing do
            Wait(100)
        end
        if ActiveAudio[casinoId].playing then
            if not IsAudioSceneActive("dlc_vw_casino_slot_machines_playing") then
                StartAudioScene("dlc_vw_casino_slot_machines_playing")
            end
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            PlayStreamFromPosition(playerCoords.x, playerCoords.y, playerCoords.z)
        end
        while ActiveAudio[casinoId] and ActiveAudio[casinoId].playing do
            Wait(1000)
        end
        StopStream()
        StopAudioScene("dlc_vw_casino_slot_machines_playing")
        ReleaseScriptAudioBank("DLC_VINEWOOD/CASINO_GENERAL")
        ReleaseScriptAudioBank("DLC_VINEWOOD/CASINO_SLOT_MACHINES_01")
        ReleaseScriptAudioBank("DLC_VINEWOOD/CASINO_SLOT_MACHINES_02")
        ReleaseScriptAudioBank("DLC_VINEWOOD/CASINO_SLOT_MACHINES_03")
    end)
end

local function StopAmbientAudio(casinoId)
    if not ActiveAudio[casinoId] then return end
    ActiveAudio[casinoId].playing = false
    ActiveAudio[casinoId] = nil
end

-- Preview rendering
local function StartMarkerThread()
    if previewMarkerThread then return end
    previewMarkerThread = true
    CreateThread(function()
        while previewMarkerThread do
            if previewMarkers and #previewMarkers >= 1 then
                for i = 1, #previewMarkers do
                    local p = previewMarkers[i]
                    DrawMarker(28, p.x, p.y, p.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 200, 255, 200, false, true, 2, false, nil, nil, false)
                end
                if #previewMarkers >= 2 then
                    for i = 1, #previewMarkers do
                        local p1 = previewMarkers[i]
                        local p2 = previewMarkers[(i % #previewMarkers) + 1]
                        DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, 0, 200, 255, 255)
                    end
                end
            end
            Wait(0)
        end
    end)
end

local function StopPreviewRendering()
    previewMarkerThread = false
    previewMarkers = nil
    if previewZone then
        previewZone:remove()
        previewZone = nil
    end
end

local function SetPreviewPoints(points)
    -- Clean up previous
    if previewZone then
        previewZone:remove()
        previewZone = nil
    end
    previewMarkerThread = false
    previewMarkers = nil

    if not points or #points == 0 then return end

    local pts = {}
    for i = 1, #points do
        pts[i] = vector3(points[i].x, points[i].y, points[i].z)
    end

    if #pts >= 3 then
        previewZone = lib.zones.poly({
            points = pts,
            thickness = 10.0,
            debug = true,
        })
    else
        previewMarkers = pts
        StartMarkerThread()
    end
end

-- Zone creation / destruction using lib.zones.poly
local function CreatePolyZone(casinoId, zoneData)
    if not ActiveZones[casinoId] then
        ActiveZones[casinoId] = {}
    end

    if ActiveZones[casinoId][zoneData.id] then
        ActiveZones[casinoId][zoneData.id]:remove()
        ActiveZones[casinoId][zoneData.id] = nil
    end

    if not zoneData.points or #zoneData.points < 3 then return end

    local points = {}
    for i = 1, #zoneData.points do
        local p = zoneData.points[i]
        points[i] = vector3(p.x, p.y, p.z)
    end

    local zone = lib.zones.poly({
        points = points,
        thickness = zoneData.thickness or 10.0,
        debug = Config.Debug,
        onEnter = function()
            debugPrint("[AudioZones] Entered zone " .. zoneData.id)
            playerInZone = { casinoId = casinoId, zoneId = zoneData.id }
            StartAmbientAudio(casinoId, zoneData.preset)
        end,
        onExit = function()
            debugPrint("[AudioZones] Exited zone " .. zoneData.id)
            if playerInZone and playerInZone.casinoId == casinoId and playerInZone.zoneId == zoneData.id then
                playerInZone = nil
            end
            StopAmbientAudio(casinoId)
        end,
    })

    ActiveZones[casinoId][zoneData.id] = zone
end

local function RemoveAllCasinoAudioZones(casinoId)
    StopAmbientAudio(casinoId)
    if not ActiveZones[casinoId] then return end
    for _, zone in pairs(ActiveZones[casinoId]) do
        zone:remove()
    end
    ActiveZones[casinoId] = nil
end

local function SyncCasinoAudioZones(casinoId)
    RemoveAllCasinoAudioZones(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return end
    if casino.settings.label == PERSONAL_CASINOS_LABEL then return end
    local audioZones = casino.settings.audio_zones
    if not audioZones then return end
    for i = 1, #audioZones do
        CreatePolyZone(casinoId, audioZones[i])
    end
end

-- NUI callbacks

-- Preview: start/stop/update rendering from NUI
RegisterNUICallback("startAudioZonePreview", function(data, cb)
    cb("ok")
    SetPreviewPoints(data.points or {})
end)

RegisterNUICallback("stopAudioZonePreview", function(_, cb)
    cb("ok")
    StopPreviewRendering()
end)

-- Get current player position for NUI
RegisterNUICallback("getPlayerPosition", function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    cb({ x = coords.x, y = coords.y, z = coords.z })
end)

-- Existing zone CRUD
RegisterNUICallback("addAudioZone", function(data, cb)
    cb("ok")
    TriggerServerEvent("pickle_casinos:addAudioZone", data.casinoId, {
        preset = data.preset,
        points = data.points or {},
    })
end)

RegisterNUICallback("deleteAudioZone", function(data, cb)
    cb("ok")
    TriggerServerEvent("pickle_casinos:deleteAudioZone", data.casinoId, data.zoneId)
end)

RegisterNUICallback("addAudioZonePoint", function(data, cb)
    cb("ok")
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent("pickle_casinos:addAudioZonePoint", data.casinoId, data.zoneId, {
        x = coords.x, y = coords.y, z = coords.z,
    })
end)

RegisterNUICallback("deleteAudioZonePoint", function(data, cb)
    cb("ok")
    TriggerServerEvent("pickle_casinos:deleteAudioZonePoint", data.casinoId, data.zoneId, data.pointIndex)
end)

-- Hook into casino registration (broadcast when a new casino is created)
RegisterNetEvent("pickle_casinos:registerCasino", function(casinoId)
    CreateThread(function()
        Wait(0)
        SyncCasinoAudioZones(casinoId)
    end)
end)

-- Hook into player join sync (server sends all casinos on connect)
RegisterNetEvent("pickle_casinos:syncCasinos", function()
    CreateThread(function()
        Wait(500)
        for casinoId, _ in pairs(Casinos) do
            SyncCasinoAudioZones(casinoId)
        end
    end)
end)

-- Sync all zones on resource restart
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(2000)
        for casinoId, _ in pairs(Casinos) do
            SyncCasinoAudioZones(casinoId)
        end
    end)
end)

-- Sync event from server
RegisterNetEvent("pickle_casinos:syncAudioZones", function(casinoId, audioZones)
    local casino = Casinos[casinoId]
    if not casino then return end
    casino.settings.audio_zones = audioZones
    SyncCasinoAudioZones(casinoId)
    SendNUIMessage({
        type = "updateAudioZones",
        casinoId = casinoId,
        audioZones = audioZones or {},
    })
end)

-- Cleanup on casino delete
RegisterNetEvent("pickle_casinos:deleteCasino", function(casinoId)
    RemoveAllCasinoAudioZones(casinoId)
end)

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    StopPreviewRendering()
    for casinoId, _ in pairs(ActiveZones) do
        RemoveAllCasinoAudioZones(casinoId)
    end
end)
