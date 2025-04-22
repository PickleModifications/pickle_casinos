CLIENT_FPS = 60

CurrentCasinoEntity = nil
LOCAL_MONEY = 0
local isEditing = false
local inGizmo = false
local gizmoEntity = nil

CreateThread(function()
    while true do 
        local startCount = GetFrameCount()
        Wait(1000)
        local endCount = GetFrameCount()
        CLIENT_FPS = endCount - startCount
    end
end)

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
    SetEditorFocus(true)
    SendNUIMessage({
        type = "openCasinoEditor",
        casinos = CasinosArrayUI(),
    })
    CreateThread(function()
        while isEditing do 
            if not inGizmo and IsControlJustPressed(1, 47) then 
                SetEditorFocus(true)
                -- SetCursorLocation(0.85, 0.5)
            end
            Wait(0)
        end
    end)
end

function StartGizmoEditor(data)
    inGizmo = true
    local ped = PlayerPedId()
    local coords = data.coords or (GetEntityCoords(ped) + GetEntityForwardVector(ped) * 3)
    local rotation = data.rotation or vector3(0.0, 0.0, GetEntityHeading(ped))
    if data.entity then
        SetEntityCoords(data.entity, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityRotation(data.entity, rotation.x, rotation.y, rotation.z, 2, true)
        local result = exports.object_gizmo:useGizmo(data.entity)
        inGizmo = false
        return result
    else
        gizmoEntity = CreateProp(data.model, coords.x, coords.y, coords.z, false, false, false)
        SetEntityRotation(gizmoEntity, rotation.x, rotation.y, rotation.z, 2, true)
        SetEntityCollision(gizmoEntity, false, false)
        local result = exports.object_gizmo:useGizmo(gizmoEntity)
        DeleteScriptObject(gizmoEntity)
        gizmoEntity = nil
        inGizmo = false
        return result
    end
end

function CasinosArrayUI()
    local casinosArray = {}
    for k,v in pairs(Casinos) do
        table.insert(casinosArray, v)
    end
    return casinosArray
end

function GenerateGameSettingsUI()   
    local slotOptions = {}
    for k,v in pairs(Config.Slots) do
        table.insert(slotOptions, {
            label = v.label,
            value = k,
        })
    end
    local modelToOptions = function(models)
        local options = {}
        for i=1, #models do
            table.insert(options, {
                label = models[i].label,
                value = models[i].model,
            })
        end
        return options
    end
    return {
        ["blackjack"] = {
            {variable = "dealerModel", type = "dropdown", label = "Dealer Ped", default = Config.CreatorOptions.dealerModels[1].model, options = modelToOptions(Config.CreatorOptions.dealerModels)},
            {variable = "tableModel", type = "dropdown", label = "Table Prop", default = Config.CreatorOptions.blackjack.tableModels[1].model, options = modelToOptions(Config.CreatorOptions.blackjack.tableModels)},
            {variable = "maxWager", type = "money", default = 100, min = 100, label = "Max Wager"},
        },
        ["roulette"] = {
            {variable = "dealerModel", type = "dropdown", label = "Dealer Ped", default = Config.CreatorOptions.dealerModels[1].model, options = modelToOptions(Config.CreatorOptions.dealerModels)},
            {variable = "tableModel", type = "dropdown", label = "Table Prop", default = Config.CreatorOptions.roulette.tableModels[1].model, options = modelToOptions(Config.CreatorOptions.roulette.tableModels)},
            {variable = "maxWager", type = "money", default = 100, min = 100, label = "Max Wager"},
        },
        ["baccarat"] = {
            {variable = "dealerModel", type = "dropdown", label = "Dealer Ped", default = Config.CreatorOptions.dealerModels[1].model, options = modelToOptions(Config.CreatorOptions.dealerModels)},
            {variable = "tableModel", type = "dropdown", label = "Table Prop", default = Config.CreatorOptions.baccarat.tableModels[1].model, options = modelToOptions(Config.CreatorOptions.baccarat.tableModels)},
            {variable = "maxWager", type = "money", default = 100, min = 100, label = "Max Wager"},        
        },
        ["wheel"] = {
            {variable = "maxWager", type = "money", default = 100, min = 100, label = "Max Wager"},
        },
        ["horseracing"] = {
            {variable = "maxWager", type = "money", default = 100, min = 100, label = "Max Wager"},
        },
        ["slot"] = {
            {variable = "game", type = "dropdown", label = "Game", default = slotOptions[1].value, options = slotOptions},
            {variable = "maxWager", type = "money", default = 100, min = 100, label = "Max Wager"},
        },
        ["poker"] = {
            {variable = "dealerModel", type = "dropdown", label = "Dealer Ped", default = Config.CreatorOptions.dealerModels[1].model, options = modelToOptions(Config.CreatorOptions.dealerModels)},
            {variable = "tableModel", type = "dropdown", label = "Table Prop", default = Config.CreatorOptions.poker.tableModels[1].model, options = modelToOptions(Config.CreatorOptions.poker.tableModels)},
            {variable = "smallBlind", type = "money", default = 10, min = 10, label = "Small Blind"},
            {variable = "bigBlind", type = "money", default = 15, min = 15, label = "Big Blind"},
        },
    }
end

function CreateCurrentCasinoEntity(coords, rotation, data)
    print("CREATING OBJ", coords, rotation, json.encode(data, {indent = true}))
    if CurrentCasinoEntity then
        DeleteScriptObject(CurrentCasinoEntity.object)
        CurrentCasinoEntity = nil
    end
    CurrentCasinoEntity = {}
    local model
    local entityType = data.info.entityType
    if not entityType and data.info.entityId then
        local casinoEntity = GetCasinoEntity(data.info.casinoId, data.info.entityId)
        if not casinoEntity then return end
        entityType = casinoEntity.type
    end
    if not entityType then return end
    if data.info.settings.tableModel then
        model = data.info.settings.tableModel
    else
        if entityType == "slot" then
            model = Config.Slots[data.info.settings.game].model
        elseif entityType == "wheel" then
            model = `vw_prop_vw_luckywheel_01a`
        elseif entityType == "horseracing" then
            model = Config.HorseRacing.machineModel
        end
    end
    CurrentCasinoEntity.object = CreateProp(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityRotation(CurrentCasinoEntity.object, rotation.x, rotation.y, rotation.z, 2, true)
end

function SetEditorFocus(toggle)
    SetNuiFocus(toggle, toggle)
    SendNUIMessage({
        type = "setEditorFocus",
        toggle = toggle,
    })
end

RegisterNUICallback("disableEditorFocus", function(data, cb)
    SetEditorFocus(false)
    cb("ok")
end)

RegisterNUICallback("pageLoaded", function(data, cb)
    SendNUIMessage({
        type = "setConfig",
        config = {
            chips = Config.Chips,
            currency = "USD",
            countryCode = "en-US",
            bonusWheelMultipliers = GenerateWheelBonusConfig(),
            gameSettings = GenerateGameSettingsUI()
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

RegisterNUICallback("updateCasinoEntitySetting", function(data, cb)
    TriggerServerEvent("pickle_casinos:updateCasinoEntitySetting", data.casinoId, data.entityId, data.variable, data.value)
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
    SetEditorFocus(false)
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local coords = (data.coords and #(vector3(data.coords.x, data.coords.y, data.coords.z) - playerCoords) < 100.0) and data.coords or (GetEntityCoords(ped) + GetEntityForwardVector(ped) * 3)
    local rotation = (#(vector3(data.rotation.x, data.rotation.y, data.rotation.z) - vector3(0.0, 0.0, 0.0)) > 1.0 and vector3(data.rotation.x, data.rotation.y, data.rotation.z) or vector3(0.0, 0.0, GetEntityHeading(ped)))
    if not data.info or (not data.info.entityType and not data.info.entityId) then
        local result = StartGizmoEditor({model = `prop_tennis_ball`, coords = coords, rotation = rotation})
        SendNUIMessage({
            type = "setLocation",
            location = {
                coords = result.position,
                rotation = result.rotation,
            }
        })
    else
        if data.info.entityId then 
            TriggerEvent("pickle_casinos:setCasinoEntityHidden", data.info.casinoId, data.info.entityId, true)
        end
        if not CurrentCasinoEntity or CurrentCasinoEntity.entityType ~= data.info.entityType then
            CreateCurrentCasinoEntity(coords, rotation, data)
        end
        local result = StartGizmoEditor({entity = CurrentCasinoEntity.object, coords = coords, rotation = rotation})
        SendNUIMessage({
            type = "setLocation",
            location = {
                coords = result.position,
                rotation = result.rotation,
            }
        })
        if data.info.entityId then 
            DeleteScriptObject(CurrentCasinoEntity.object)
            CurrentCasinoEntity = nil
            SetTimeout(1000, function()
                TriggerEvent("pickle_casinos:setCasinoEntityHidden", data.info.casinoId, data.info.entityId, false)
            end)
        end
    end
    SetEditorFocus(true)
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
    local ped = PlayerPedId()
    local coords = casinoEntity.settings.location.coords + vector3(0.0, 0.0, 1.0)
    local rotation = casinoEntity.settings.location.rotation
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, rotation.z)
end)

RegisterNUICallback("createCasinoEntity", function(data, cb)
    cb("ok")
    local casino = Casinos[data.casinoId]
    if not casino then return end
    TriggerServerEvent("pickle_casinos:createCasinoEntity", data.casinoId, data.type, data.settings)
end)

RegisterNUICallback("exitCasinoEntityEditor", function(data, cb)
    cb("ok")
    if CurrentCasinoEntity then
        DeleteScriptObject(CurrentCasinoEntity.object)
        CurrentCasinoEntity = nil
    end
end)

RegisterNUICallback("deleteCasinoEntity", function(data, cb)
    cb("ok")
    TriggerServerEvent("pickle_casinos:deleteCasinoEntity", data.casinoId, data.entityId)
end)

RegisterNUICallback("updateTempCasinoEntitySettings", function(data, cb)
    cb("ok")
    if not CurrentCasinoEntity then return end
    CreateCurrentCasinoEntity(GetEntityCoords(CurrentCasinoEntity.object), GetEntityRotation(CurrentCasinoEntity.object), {
        info = {
            entityType = data.entityType,
            settings = data.settings,
        }
    })
end)

RegisterNUICallback("highlightCasinoEntity", function(data, cb)
    cb("ok")
    if data.casinoId then
        local casinoEntity = GetCasinoEntity(data.casinoId, data.entityId)
        if not casinoEntity then return end
        if CurrentHighlight then
            CurrentHighlight.coords = data.coords
        else
            CurrentHighlight = {coords = casinoEntity.settings.location.coords}
            CreateThread(function()
                while CurrentHighlight do 
                    DrawMarker(0, CurrentHighlight.coords.x, CurrentHighlight.coords.y, CurrentHighlight.coords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.5, 255, 255, 255, 255, false, true, false, true)
                    Wait(0)
                end
            end)
        end
    elseif CurrentHighlight then
        CurrentHighlight = nil
    end
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
    -- StartCasinoEditor()
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

RegisterNetEvent("pickle_casinos:updateCasinoEntitySetting", function(casinoId, entityId, variable, value)
    local casino = Casinos[casinoId]
    if not casino then return end
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casinoEntity then return end
    casinoEntity.settings[variable] = value
    SendNUIMessage({
        type = "updateCasinoEntitySetting",
        casinoId = casinoId,
        entityId = entityId,
        variable = variable,
        value = value,
    })
    SendNUIMessage({
        type = "updateCasinoEntities",
        casinoId = casinoId,
        entities = casino.entities, 
    })
    SendNUIMessage({
        type = "updateCasinos",
        casinos = CasinosArrayUI(),
    })
    TriggerEvent("pickle_casinos:refreshCasinoEntity", casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:deleteCasino", function(casinoId)
    local casino = Casinos[casinoId]
    if not casino then return end
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

RegisterNetEvent("pickle_casinos:createCasinoEntity", function(casinoId, data)
    local casino = Casinos[casinoId]
    if not casino then return end
    table.insert(casino.entities, data)
    CreateCasinoEntity(casinoId, data.id)
    SendNUIMessage({
        type = "updateCasinoEntities",
        casinoId = casinoId,
        entities = casino.entities, 
    })
    SendNUIMessage({
        type = "updateCasinos",
        casinos = CasinosArrayUI(),
    })
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    local casino = Casinos[casinoId]
    if not casino then return end
    for i=1, #casino.entities do
        if casino.entities[i].id == entityId then
            table.remove(casino.entities, i)
            break
        end
    end
    SendNUIMessage({
        type = "updateCasinoEntities",
        casinoId = casinoId,
        entities = casino.entities, 
    })
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
        if CurrentCasinoEntity then
            DeleteScriptObject(CurrentCasinoEntity.object)
            CurrentCasinoEntity = nil
        end
    end
end)