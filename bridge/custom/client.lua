if GetResourceState('es_extended') == 'started' then return end
if GetResourceState('qb-core') == 'started' then return end

debugPrint("You are not using a supported framework, it will be required to make edits to the bridge files.")

-- Client callbacks are framework-agnostic: they always go through ox_lib. This
-- matches the ESX/QB bridges and needs no custom implementation.
function ServerCallback(name, cb, ...)
    lib.callback(name, false, cb, ...)
end