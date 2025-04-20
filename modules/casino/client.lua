LOCAL_MONEY = 0

local isEditing = false

function CreateCasinoEntity(casinoId, entityId)
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    if casinoEntity.type == "blackjack" then
        CreateBlackjackEntity(casinoId, entityId)
    elseif casinoEntity.type == "roulette" then
        CreateRouletteEntity(casinoId, entityId)
    elseif casinoEntity.type == "baccarat" then
        CreateBaccaratEntity(casinoId, entityId)
    elseif casinoEntity.type == "slot" then
        CreateSlotEntity(casinoId, entityId)
    elseif casinoEntity.type == "poker" then
        CreatePokerEntity(casinoId, entityId)
    elseif casinoEntity.type == "wheel" then
        CreateWheelEntity(casinoId, entityId)
    elseif casinoEntity.type == "horseracing" then
        CreateHorseRacingEntity(casinoId, entityId)
    end
end

function GetCasinoEntity(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    for i=1, #casino.entities do
        if casino.entities[i].id == entityId then
            return casino.entities[i], i
        end
    end
end

function UpdateCasinoEntity(casinoId, entity)
    local casino = Casinos[casinoId]
    if not casino then return end
    local casinoEntity, index = GetCasinoEntity(casinoId, entity.id)
    if not casinoEntity then return end
    print("Updating casino entity", casinoId, entity.id, index)
    casino.entities[index] = entity
end

function GenerateWheelBonusConfig()
    local entries = {}
    for i=1, #Config.WheelBonus do 
        entries[i] = {
            id = "bonus_" .. i,
            multiplier = Config.WheelBonus[i].multiplier,
            chance = Config.WheelBonus[i].chance,
        }
    end
    return entries
end

function SetEntitySmoothRotation(entity, from, to, speed)
    local speed = speed or 4
    local progress = 0
    CreateThread(function()
        while progress < 100 do
            progress = progress + speed
            if progress > 100 then progress = 100 end
            local newCoords = lerp(from, to, progress / 100)
            SetEntityRotation(entity, newCoords, 2, true)
            Wait(10)
        end
    end)
end

function StartCasinoEditor()
    if isEditing then return end
    isEditing = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openCasinoEditor",
        casinos = CasinosArrayUI(),
    })
    CreateThread(function()
        while isEditing do 
            if not gizmoEntity and IsControlJustPressed(1, 47) then 
                SetNuiFocus(true, true)
                SetCursorLocation(0.85, 0.5)
            end
            Wait(0)
        end
    end)
end

function StartGizmoEditor(data)
    local ped = PlayerPedId()
    local coords = data.coords or (GetEntityCoords(ped) + GetEntityForwardVector(ped) * 3)
    local rotation = data.rotation or vector3(0.0, 0.0, GetEntityHeading(ped) + 180.0)
    gizmoEntity = CreateProp(data.model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityRotation(gizmoEntity, rotation.x, rotation.y, rotation.z, 2, true)
    SetEntityCollision(gizmoEntity, false, false)
    local result = exports.object_gizmo:useGizmo(gizmoEntity)
    DeleteScriptObject(gizmoEntity)
    gizmoEntity = nil
    return result
end

function CasinosArrayUI()
    local casinosArray = {}
    for k,v in pairs(Casinos) do
        table.insert(casinosArray, v)
    end
    return casinosArray
end

RegisterNUICallback("disableEditorFocus", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("pageLoaded", function(data, cb)
    SendNUIMessage({
        type = "setConfig",
        config = {
            currency = "USD",
            countryCode = "en-US",
            bonusWheelMultipliers = GenerateWheelBonusConfig(),
        }
    })
    TriggerServerEvent("pickle_casinos:initializePlayer")
    cb("ok")
end)

RegisterNUICallback("exitGame", function(data, cb)
    TriggerEvent("pickle_casinos:exitGame")
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "setCurrentGame",
        game = nil
    })
end)

RegisterNUICallback("createCasino", function(data, cb)
    TriggerServerEvent("pickle_casinos:createCasino", data)
    cb("ok")
end)

RegisterNUICallback("updateCasinoSetting", function(data, cb)
    TriggerServerEvent("pickle_casinos:updateCasinoSetting", data.casinoId, data.variable, data.value)
    cb("ok")
end)

RegisterNUICallback("deleteCasino", function(data, cb)
    TriggerServerEvent("pickle_casinos:deleteCasino", data.id)
    cb("ok")
end)

RegisterNUICallback("editLocation", function(data, cb)
    cb("ok")
    SendNUIMessage({
        type = "setEditorHidden",
        hidden = true,
    })
    SetNuiFocus(false, false)
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local coords = (data.coords and #(vector3(data.coords.x, data.coords.y, data.coords.z) - playerCoords) < 100.0) and data.coords or (GetEntityCoords(ped) + GetEntityForwardVector(ped) * 3)
    local rotation = data.rotation or vector3(0.0, 0.0, GetEntityHeading(ped) + 180.0)
    if not info then
        local result = StartGizmoEditor({model = `prop_tennis_ball`, coords = coords, rotation = rotation})
        SendNUIMessage({
            type = "setLocation",
            location = {
                coords = result.position,
                rotation = result.rotation,
            }
        })
    end
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "setEditorHidden",
        hidden = false,
    })
end)

RegisterNUICallback("teleportToCasino", function(data, cb)
    cb("ok")
    local casino = Casinos[data.casinoId]
    if not casino then return end
    local ped = PlayerPedId()
    local coords = casino.settings.location.coords
    local rotation = casino.settings.location.rotation
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, rotation.z)
end)

RegisterNUICallback("teleportToEntity", function(data, cb)
    cb("ok")
    local casino = Casinos[data.casinoId]
    if not casino then return end
    local casinoEntity = GetCasinoEntity(data.casinoId, data.entityId)
    if not casinoEntity then return end
    -- IDK how yet
    local ped = PlayerPedId()
    local coords = casinoEntity.location.coords
    local rotation = casinoEntity.location.rotation
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, rotation.z)
end)

RegisterNetEvent("pickle_casinos:syncCasinos", function(data)
    for k,v in pairs(data) do
        Casinos[k] = v
        for i=1, #v.entities do
            CreateCasinoEntity(k, v.entities[i].id)
        end
    end
    SendNUIMessage({
        type = "updateCasinos",
        casinos = CasinosArrayUI(),
    })
    StartCasinoEditor()
end)

RegisterNetEvent("pickle_casinos:displayResults", function(totalWin, balance)
    SendNUIMessage({
        type = "displayResults",
        results = {winnings = totalWin},
    })
    SendNUIMessage({
        type = "updateBalance",
        balance = balance,
    })
end)

RegisterNetEvent("pickle_casinos:updateCasinoEntity", function(casinoId, entity)
    local casino = Casinos[casinoId]
    if not casino then return end
    local casinoEntity = GetCasinoEntity(casinoId, entity.id)
    if not casinoEntity then return end
    UpdateCasinoEntity(casinoId, entity)
end)

RegisterNetEvent("pickle_casinos:updateMoney", function(money)
    LOCAL_MONEY = money
    SendNUIMessage({
        type = "updateMoney",
        money = money
    })
end)

RegisterNetEvent("pickle_casinos:updateCasinoSetting", function(casinoId, variable, value)
    local casino = Casinos[casinoId]
    if not casino then return end
    casino.settings[variable] = value
    SendNUIMessage({
        type = "updateCasinoSetting",
        casinoId = casinoId,
        variable = variable,
        value = value,
    })
    SendNUIMessage({
        type = "updateCasinos",
        casinos = CasinosArrayUI(),
    })
end)

RegisterNetEvent("pickle_casinos:deleteCasino", function(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return end
    for i=1, #casino.entities do
        DeleteCasinoEntity(casinoId, casino.entities[i].id)
    end
    Casinos[casinoId] = nil
    SendNUIMessage({
        type = "updateCasinos",
        casinos = CasinosArrayUI(),
    })
end)

RegisterNetEvent("pickle_casinos:registerCasino", function(casinoId, data)
    Casinos[casinoId] = data
    for i=1, #Casinos[casinoId].entities do
        CreateCasinoEntity(casinoId, Casinos[casinoId].entities[i].id)
    end
    SendNUIMessage({
        type = "updateCasinos",
        casinos = CasinosArrayUI(),
    })
end)

RegisterNetEvent("pickle_casinos:casinosMenu", function()
    StartCasinoEditor()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isEditing then
            SetNuiFocus(false, false)
        end
        if gizmoEntity then
            DeleteScriptObject(gizmoEntity)
        end
    end
end)