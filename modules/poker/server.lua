local PendingSpins = {}

function InitializePokerEntity(casinoId, data)
    local entity = data or { id = "ERR_NO_ID_POKER" }
    return entity
end

function GetPlayerPokerInfo(source)
    if not source or source < 1 then return end
    for k,v in pairs(Casinos) do
        for i=1, #v.entities do
            local entity = v.entities[i]
            -- if entity.type == "slot" and entity.currentPlayer and entity.currentPlayer.source == source then
            --     return {casinoId = k, entityId = entity.id, seatId = 1}
            -- end
        end
    end
end

RegisterNetEvent("pickle_casinos:poker:leaveTable", function()
    local playerInfo = GetPlayerPokerInfo(source)
    if not playerInfo then return end
end)

RegisterCallback("pickle_casinos:poker:requestSeat", function(source, cb, casinoId, entityId, seatId)
    local casino = Casinos[casinoId]
    if not casino then return end
    local entity = GetCasinoEntity(casinoId, entityId)
    if not entity then return end
    cb(seatId)
end)