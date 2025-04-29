local LocalStores = {}
local CurrentStore = nil

function DoesStoreEntityExist(casinoId, entityId) 
    return LocalStores[casinoId] and LocalStores[casinoId][entityId]
end

function CreateStoreEntity(casinoId, entityId)
    if DoesStoreEntityExist(casinoId, entityId) then return end
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    if not LocalStores[casinoId] then
        LocalStores[casinoId] = {}
    end
    LocalStores[casinoId][entityId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - coords) < Config.RenderDistance,
        coords = coords,
        heading = heading,
    }
    RenderStoreEntity(casinoId, entityId)
end

function OpenStorePurchaseMenu(casinoId, entityId, itemIndex)
    ServerCallback("pickle_casinos:getBalances", function(balances)
        local localStore = LocalStores[casinoId][entityId]
        local casinoEntity = GetCasinoEntity(casinoId, entityId)
        if not localStore.visible or not casinoEntity then return end
        local storeCfg = Config.CreatorOptions.stores[casinoEntity.settings.store]
        if not storeCfg then 
            storeCfg = Config.CreatorOptions.stores[1]
        end
        if not storeCfg then return end
        local item = storeCfg.items[itemIndex]
        if not item then return end
        if math.floor(balances.money / item.price) <= 0 then 
            SetTimeout(200, function()
                OpenStoreMenu(casinoId, entityId)
            end)
            return ShowNotification(_L("insufficient_funds"))
        else
            local options = {}
            options[#options + 1] =  {
                type = 'slider', 
                label = _L("store_quantity_input"),
                description = _L("store_quantity_input_desc"), 
                required = true, 
                min = 1, 
                max = math.floor(balances.money / item.price) > Config.MaximumItemPurchaseAmount and Config.MaximumItemPurchaseAmount or math.floor(balances.money / item.price),
            }
            local input = lib.inputDialog(_L("store_purchase_dialog", GetItemLabel(item.item)), options)
            SetTimeout(200, function()
                OpenStoreMenu(casinoId, entityId)
            end)
            if not input or not input[1] then 
                return 
            end
            TriggerServerEvent("pickle_casinos:storePurchase", casinoId, entityId, itemIndex, input[1])
        end
    end, casinoId, entityId)

end

function OpenStoreMenu(casinoId, entityId)
    local localStore = LocalStores[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not localStore.visible or not casinoEntity then return end
    local storeCfg = Config.CreatorOptions.stores[casinoEntity.settings.store]
    if not storeCfg then 
        storeCfg = Config.CreatorOptions.stores[1]
    end
    if not storeCfg then return end
    local menuId = "store_" .. casinoId .. "_" .. entityId
    local options = {}
    for i=1, #storeCfg.items do 
        options[#options + 1] = {
            title = GetItemLabel(storeCfg.items[i].item),
            description = NumberWithCommas(storeCfg.items[i].price),
            image = Config.ImageDirectory .. storeCfg.items[i].item .. ".png",
            onSelect = function()
                OpenStorePurchaseMenu(casinoId, entityId, i)
            end
        }
    end
    lib.registerContext({
        id = menuId,
        title = storeCfg.label,
        options = options,
        onExit = function()
            CurrentCashier = nil
        end,
    })
    lib.showContext(menuId)
end

function RenderStoreEntity(casinoId, entityId)
    local localStore = LocalStores[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not localStore.visible or not casinoEntity then return end
    local storeCfg = Config.CreatorOptions.stores[casinoEntity.settings.store]
    if not storeCfg then 
        storeCfg = Config.CreatorOptions.stores[1]
    end
    if not storeCfg then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    local dealerPed = CreateDealerPed(casinoEntity.settings.dealerModel, coords, heading)
    SetEntityRotation(dealerPed, 0.0, 0.0, heading, 2, true)
    localStore.dealerPed = dealerPed
    localStore.interact = CreateInteraction({
        label = storeCfg.label .. (casinoEntity.settings.vip and (" " .. _L("casino_vip_game")) or ""),
        coords = GetOffsetFromEntityInWorldCoords(dealerPed, 0.0, 0.0, 0.0),
        heading = heading,
        icon = Config.TargetIcons and Config.TargetIcons["stores"] or nil,
        radius = 1.25
    }, function(selected)
        ServerCallback("pickle_casinos:getVIPStatus", function(isVIP)
            if casinoEntity.settings.vip and not isVIP then return ShowNotification(_L("casino_vip_required")) end
            OpenStoreMenu(casinoId, entityId)
        end, casinoId, entityId)
    end)
end

function UnrenderStoreEntity(casinoId, entityId)
    local localStore = LocalStores[casinoId][entityId]
    if not localStore then return end
    if localStore.dealerPed then
        DeletePed(localStore.dealerPed)
    end
    if localStore.interact then
        DeleteInteraction(localStore.interact)
    end
    localStore.interact = nil
    localStore.dealerPed = nil
end

function DeleteStoreEntity(casinoId, entityId)
    UnrenderStoreEntity(casinoId, entityId)
    LocalStores[casinoId][entityId] = nil
end

CreateThread(function()
    while true do 
        local coords = GetEntityCoords(PlayerPedId())
        for casinoId, entities in pairs(LocalStores) do
            for entityId, entity in pairs(entities) do
                if not entity.visible and not entity.hidden then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) <= Config.RenderDistance then
                        entity.visible = true
                        RenderStoreEntity(casinoId, entityId)
                    end
                elseif entity.visible then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) > Config.RenderDistance then
                        entity.visible = false
                        UnrenderStoreEntity(casinoId, entityId)
                    end
                end
            end
        end
        Wait(1500)
    end
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    if not LocalStores[casinoId] then return end
    if not LocalStores[casinoId][entityId] then return end
    DeleteStoreEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:setCasinoEntityHidden", function(casinoId, entityId, toggle)
    if not LocalStores[casinoId] then return end
    if not LocalStores[casinoId][entityId] then return end
    local storeEntity = LocalStores[casinoId][entityId]
    storeEntity.hidden = toggle
    if toggle then
        storeEntity.visible = false
        UnrenderStoreEntity(casinoId, entityId)
    else
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - storeEntity.coords) <= Config.RenderDistance then
            storeEntity.visible = true
            RenderStoreEntity(casinoId, entityId)
        end
    end
end)

RegisterNetEvent("pickle_casinos:refreshCasinoEntity", function(casinoId, entityId)
    if not LocalStores[casinoId] then return end
    if not LocalStores[casinoId][entityId] then return end
    local storeEntity = LocalStores[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    storeEntity.coords = casinoEntity.settings.location.coords
    storeEntity.heading = casinoEntity.settings.location.rotation.z
    if not storeEntity.visible then return end
    UnrenderStoreEntity(casinoId, entityId)
    Wait(100)
    RenderStoreEntity(casinoId, entityId)
end)


AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k,v in pairs(LocalStores) do
            for id, _ in pairs(v) do
                DeleteStoreEntity(k, id)
            end
        end
    end
end)