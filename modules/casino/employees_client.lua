print("^2[pickle_casinos] employees_client.lua loaded^0")

-- Wraps a NUI cb so it can only resolve once, and always resolves within
-- `timeoutMs` (defaults to 5s) with `fallback` if the underlying server
-- callback never responds. Prevents the EmployeesTab spinner from getting
-- stuck if anything upstream silently fails (missing bridge, server error,
-- callback never registered, etc).
local function SafeCb(cb, fallback, timeoutMs)
    local done = false
    local function resolve(value)
        if done then return end
        done = true
        cb(value)
    end
    SetTimeout(timeoutMs or 5000, function()
        if not done then resolve(fallback) end
    end)
    return resolve
end

RegisterNUICallback("getEmployees", function(data, cb)
    local resolve = SafeCb(cb, {})
    if not data or not data.casinoId then resolve({}); return end
    lib.callback("pickle_casinos:getEmployees", false, function(employees)
        resolve(employees or {})
    end, tonumber(data.casinoId))
end)

RegisterNUICallback("getJobGrades", function(data, cb)
    local resolve = SafeCb(cb, {})
    if not data or not data.casinoId then resolve({}); return end
    lib.callback("pickle_casinos:getJobGrades", false, function(grades)
        resolve(grades or {})
    end, tonumber(data.casinoId))
end)

RegisterNUICallback("setEmployeeGrade", function(data, cb)
    cb("ok")
    if not data or not data.casinoId then return end
    lib.callback("pickle_casinos:setEmployeeGrade", false, function(success, msg)
        if success then
            ShowNotification("Grade updated")
        else
            ShowNotification(msg or "Failed to update grade")
        end
    end, tonumber(data.casinoId), tonumber(data.targetSource), tonumber(data.grade))
end)

RegisterNUICallback("fireEmployee", function(data, cb)
    cb("ok")
    if not data or not data.casinoId then return end
    lib.callback("pickle_casinos:fireEmployee", false, function(success, msg)
        if success then
            ShowNotification("Employee fired")
        else
            ShowNotification(msg or "Failed to fire employee")
        end
    end, tonumber(data.casinoId), tonumber(data.targetSource))
end)

RegisterNUICallback("hirePlayer", function(data, cb)
    cb("ok")
    if not data or not data.casinoId then return end
    lib.callback("pickle_casinos:hirePlayer", false, function(success, msg)
        if success then
            ShowNotification("Player hired!")
        else
            ShowNotification(msg or "Failed to hire player")
        end
    end, tonumber(data.casinoId), tonumber(data.targetSource))
end)

RegisterNUICallback("getNearbyPlayers", function(data, cb)
    local resolve = SafeCb(cb, {})
    lib.callback("pickle_casinos:getNearbyPlayers", false, function(players)
        resolve(players or {})
    end)
end)
