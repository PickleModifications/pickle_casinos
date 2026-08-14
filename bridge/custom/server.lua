if GetResourceState('es_extended') == 'started' then return end
if GetResourceState('qb-core') == 'started' then return end

debugPrint("You are not using a supported framework, it will be required to make edits to the bridge files.")

-- Server callbacks are framework-agnostic: they always go through ox_lib. This
-- matches the ESX/QB bridges and needs no custom implementation. Handlers keep
-- the (source, cb, ...) contract used throughout the modules.
function RegisterCallback(name, cb)
    lib.callback.register(name, function(source, ...)
        local results
        cb(source, function(...) results = table.pack(...) end, ...)
        if results then return table.unpack(results, 1, results.n) end
    end)
end