inGizmo = false

function StartMovement(prop)
    local coords = GetEntityCoords(PlayerPedId())
    local heading = 0.0
    local hasSetHeading = false
    FreezeEntityPosition(prop, true)
    SetEntityCollision(prop, false, false)
    local isFrozen = false
    while true do
        local speedMode = 1
        local hit, hitCoords, entity = GetDirectionCoords()
        if hit and hitCoords then 
            if not isFrozen then
                coords = vector3(hitCoords.x, hitCoords.y, hitCoords.z)
                heading = GetGameplayCamRot(2).z
                SetEntityCoords(prop, coords.x, coords.y, coords.z)
                SetEntityRotation(prop, 0, 0, heading, 2) 
            end
        end
        ShowInteractText(
            '[G]     - ' .. (isFrozen and "Unfreeze" or "Freeze") .. '  \n' ..
            (isFrozen and '[ARROW KEYS]     - Position  \n[SCROLL UP / DOWN]     - Rotate  \n[SHIFT]     - Faster Movement  \n' or '') ..
            '[E]     - Save Position'
        )
        if IsControlPressed(1, 21) then
            speedMode = 4
        end
        if IsControlJustPressed(1, 47) then
            isFrozen = not isFrozen
        end
        if isFrozen then
            local forwardVector --[[ vector3 ]], rightVector --[[ vector3 ]], upVector --[[ vector3 ]], position --[[ vector3 ]] = GetEntityMatrix(prop)
            if IsControlPressed(1, 15) then
                heading = heading + (1.0 * speedMode)
                if heading > 360.0 then heading = (360.0 - heading) end
                SetEntityRotation(prop, 0.0, 0.0, heading, 2, true)
                hasSetHeading = true
            elseif IsControlPressed(1, 14) then
                heading = heading - (1.0 * speedMode)
                if heading < 0.0 then heading = (360.0 + heading) end
                SetEntityRotation(prop, 0.0, 0.0, heading, 2, true)
                hasSetHeading = true
            end
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            coords = coords - forwardVector * ((GetDisabledControlNormal(0, 2) * 0.005) * speedMode)
            coords = coords + rightVector * ((GetDisabledControlNormal(0, 1) * 0.005) * speedMode)
            SetEntityCoords(prop, coords.x, coords.y, coords.z)
            -- if IsControlPressed(1, 172) then
            --     coords = coords + forwardVector * (0.005 * speedMode)
            --     SetEntityCoords(prop, coords.x, coords.y, coords.z)
            -- elseif IsControlPressed(1, 173) then
            --     coords = coords - forwardVector * (0.005 * speedMode)
            --     SetEntityCoords(prop, coords.x, coords.y, coords.z)
            -- end
            -- if IsControlPressed(1, 174) then
            --     coords = coords - rightVector * (0.005 * speedMode)
            --     SetEntityCoords(prop, coords.x, coords.y, coords.z)
            -- elseif IsControlPressed(1, 175) then
            --     coords = coords + rightVector * (0.005 * speedMode)
            --     SetEntityCoords(prop, coords.x, coords.y, coords.z)
            -- end
        end
        if IsControlJustPressed(1, 51) then
            break
        end
        Wait(0) 
    end
    return {
        position = coords,
        rotation = vector3(0.0, 0.0, heading),
    }
end

function StartGizmoEditor(data)
    if inGizmo then return false end
    inGizmo = true
    local ped = PlayerPedId()
    local coords = data.coords or (GetEntityCoords(ped) + GetEntityForwardVector(ped) * 3)
    local rotation = data.rotation or vector3(0.0, 0.0, GetEntityHeading(ped))
    if data.entity then
        SetEntityCoords(data.entity, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityRotation(data.entity, rotation.x, rotation.y, rotation.z, 2, true)
        local result
        if Config.UseObjectGizmo and GetResourceState("object_gizmo") == "started" then
            result = exports.object_gizmo:useGizmo(data.entity)
        else
            result = StartMovement(data.entity)
        end
        inGizmo = false
        return result
    else
        gizmoEntity = CreateProp(data.model, coords.x, coords.y, coords.z, false, false, false)
        SetEntityRotation(gizmoEntity, rotation.x, rotation.y, rotation.z, 2, true)
        SetEntityCollision(gizmoEntity, false, false)
        local result
        if Config.UseObjectGizmo and GetResourceState("object_gizmo") == "started" then
            result = exports.object_gizmo:useGizmo(gizmoEntity)
        else
            result = StartMovement(gizmoEntity)
        end
        DeleteScriptObject(gizmoEntity)
        gizmoEntity = nil
        inGizmo = false
        return result
    end
end