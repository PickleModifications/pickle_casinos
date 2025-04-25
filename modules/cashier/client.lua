local LocalCashiers = {}
local CurrentCashier = nil

function DoesCashierEntityExist(casinoId, entityId) 
    return LocalCashiers[casinoId] and LocalCashiers[casinoId][entityId]
end

function CreateCashierEntity(casinoId, entityId)
    if DoesCashierEntityExist(casinoId, entityId) then return end
    local casino = Casinos[casinoId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not casino or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    if not LocalCashiers[casinoId] then
        LocalCashiers[casinoId] = {}
    end
    LocalCashiers[casinoId][entityId] = {
        visible = #(GetEntityCoords(PlayerPedId()) - coords) < Config.RenderDistance,
        coords = coords,
        heading = heading,
    }
    RenderCashierEntity(casinoId, entityId)
end

function OpenCashierExchangeAmountMenu(casinoId, entityId, exchangeType, currency, balances)
    local options = {}
    local maxAmount = exchangeType == "buy" and (
        balances[currency] < Config.MaximumChipPurchaseAmount and balances[currency] or Config.MaximumChipPurchaseAmount
    ) or (
        balances.balance > balances.casinoBalance and balances.casinoBalance or balances.balance
    )
    if maxAmount <= 0 then
        SetTimeout(200, function()
            OpenCashierMenu(casinoId, entityId)
        end)
        if exchangeType == "buy" then
            ShowNotification(_L("cashier_no_money"))
        elseif balances.balance <= 0 then
            ShowNotification(_L("cashier_no_chips"))
        else
            ShowNotification(_L("cashier_out_money"))
        end
        return
    end
    options[#options + 1] =  {
        type = 'slider', 
        label = _L("cashier_".. exchangeType.. "_input"),
        description = _L("cashier_".. exchangeType.. "_input_desc"), 
        required = true, 
        min = 1, 
        max = maxAmount,
        icon = "coins"
    }
    local input = lib.inputDialog(_L("cashier_"..exchangeType.."_chips"), options)
    SetTimeout(200, function()
        OpenCashierMenu(casinoId, entityId)
    end)
    if not input or not input[1] then 
        return 
    end
    TriggerServerEvent("pickle_casinos:casinoExchange", casinoId, entityId, exchangeType, currency, input[1])
end

function OpenCashierExchangeMenu(casinoId, entityId, exchangeType)
    local casino = Casinos[casinoId]
    ServerCallback("pickle_casinos:getBalances", function(balances)
        if exchangeType == "buy" then
            local options = {}
            options[#options + 1] = {required = true, type = 'select', label = _L("cashier_buy_currency"), description = _L("cashier_buy_currency_desc"), icon = 'money-bills', default = "money", options = {
                {label = _L("cashier_buy_currency_cash", casino.settings.moneyExchangeRate .. "%"), value = "money"},
                {label = _L("cashier_buy_currency_dirty", casino.settings.dirtyExchangeRate .. "%"), value = "dirty"},
            }}
            local input = lib.inputDialog(_L("cashier_"..exchangeType.."_chips"), options)
            if not input or not input[1] then 
                SetTimeout(200, function()
                    OpenCashierMenu(casinoId, entityId)
                end)
                return 
            end
            OpenCashierExchangeAmountMenu(casinoId, entityId, exchangeType, input[1], balances)
        else
            OpenCashierExchangeAmountMenu(casinoId, entityId, exchangeType, "money", balances)
        end
    end, casinoId, entityId)
end

function OpenCashierMenu(casinoId, entityId)
    CurrentCashier = { casinoId = casinoId, entityId = entityId }
    local casino = Casinos[casinoId]
    if not casino then return end
    ServerCallback("pickle_casinos:getVIPStatus", function(isVIP)
        local vipPrice = casino.settings.vipPrice or 0
        local menuId = "pickle_casinos_cashier_" .. casinoId
        local options = {}
        options[#options + 1] = {
            title = _L("cashier_buy_chips"),
            description = _L("cashier_buy_chips_desc"),
            icon = 'coins',
            onSelect = function()
                OpenCashierExchangeMenu(casinoId, entityId, "buy")
            end
        }
        options[#options + 1] = {
            title = _L("cashier_sell_chips"),
            description = _L("cashier_sell_chips_desc"),
            icon = 'money-bills',
            onSelect = function()
                OpenCashierExchangeMenu(casinoId, entityId, "sell")
            end
        }
        if not isVIP then
            options[#options + 1] = {
                title = _L("cashier_vip", NumberWithCommas(vipPrice)),
                description = _L("cashier_vip_desc"),
                icon = 'star',
                onSelect = function()
                    TriggerServerEvent("pickle_casinos:purchaseVIP", casinoId, entityId)
                    SetTimeout(200, function()
                        OpenCashierMenu(casinoId, entityId)
                    end)
                end
            }
        else
            options[#options + 1] = {
                title = _L("cashier_vip_owned"),
                description = _L("cashier_vip_desc"),
                disabled = true,
                icon = 'star',
            }
        end
        lib.registerContext({
            id = menuId,
            title = _L("cashier_title"),
            options = options,
            onExit = function()
                CurrentCashier = nil
            end,
        })
        lib.showContext(menuId)
    end, casinoId)
end

function RenderCashierEntity(casinoId, entityId)
    local localCashier = LocalCashiers[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    if not localCashier.visible or not casinoEntity then return end
    local coords = casinoEntity.settings.location.coords
    local heading = casinoEntity.settings.location.rotation.z
    local dealerPed = CreateDealerPed(casinoEntity.settings.dealerModel, coords, heading)
    SetEntityRotation(dealerPed, 0.0, 0.0, heading, 2, true)
    localCashier.dealerPed = dealerPed
    localCashier.interact = CreateInteraction({
        label = _L("cashier_title"),
        coords = GetOffsetFromEntityInWorldCoords(dealerPed, 0.0, 0.0, 0.0),
        heading = heading,
        radius = 1.25
    }, function(selected)
        OpenCashierMenu(casinoId, entityId)
    end)
end

function UnrenderCashierEntity(casinoId, entityId)
    local localCashier = LocalCashiers[casinoId][entityId]
    if not localCashier then return end
    if localCashier.dealerPed then
        DeletePed(localCashier.dealerPed)
    end
    if localCashier.interact then
        DeleteInteraction(localCashier.interact)
    end
    localCashier.interact = nil
    localCashier.dealerPed = nil
end

function DeleteCashierEntity(casinoId, entityId)
    UnrenderCashierEntity(casinoId, entityId)
    LocalCashiers[casinoId][entityId] = nil
end

CreateThread(function()
    while true do 
        local coords = GetEntityCoords(PlayerPedId())
        for casinoId, entities in pairs(LocalCashiers) do
            for entityId, entity in pairs(entities) do
                if not entity.visible and not entity.hidden then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) <= Config.RenderDistance then
                        entity.visible = true
                        RenderCashierEntity(casinoId, entityId)
                    end
                elseif entity.visible then
                    if #(GetEntityCoords(PlayerPedId()) - entity.coords) > Config.RenderDistance then
                        entity.visible = false
                        UnrenderCashierEntity(casinoId, entityId)
                    end
                end
            end
        end
        Wait(1500)
    end
end)

RegisterNetEvent("pickle_casinos:deleteCasinoEntity", function(casinoId, entityId)
    print("deleteCasinoEntity slot", casinoId, entityId)
    if not LocalCashiers[casinoId] then return end
    print("CASINO EXISTS")
    if not LocalCashiers[casinoId][entityId] then return end
    print("CASINO ENTITY EXISTS")
    DeleteCashierEntity(casinoId, entityId)
end)

RegisterNetEvent("pickle_casinos:setCasinoEntityHidden", function(casinoId, entityId, toggle)
    if not LocalCashiers[casinoId] then return end
    if not LocalCashiers[casinoId][entityId] then return end
    local slotMachine = LocalCashiers[casinoId][entityId]
    slotMachine.hidden = toggle
    if toggle then
        slotMachine.visible = false
        UnrenderCashierEntity(casinoId, entityId)
    else
        local playerCoords = GetEntityCoords(PlayerPedId())
        if #(playerCoords - slotMachine.coords) <= Config.RenderDistance then
            slotMachine.visible = true
            RenderCashierEntity(casinoId, entityId)
        end
    end
end)

RegisterNetEvent("pickle_casinos:refreshCasinoEntity", function(casinoId, entityId)
    if not LocalCashiers[casinoId] then return end
    if not LocalCashiers[casinoId][entityId] then return end
    local slotMachine = LocalCashiers[casinoId][entityId]
    local casinoEntity = GetCasinoEntity(casinoId, entityId)
    slotMachine.coords = casinoEntity.settings.location.coords
    slotMachine.heading = casinoEntity.settings.location.rotation.z
    if not slotMachine.visible then return end
    UnrenderCashierEntity(casinoId, entityId)
    Wait(100)
    RenderCashierEntity(casinoId, entityId)
end)


AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k,v in pairs(LocalCashiers) do
            for id, _ in pairs(v) do
                DeleteCashierEntity(k, id)
            end
        end
    end
end)