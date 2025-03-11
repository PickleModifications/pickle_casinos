Casinos = {}

function GetCasinoEntity(casinoId, entityId)
    local casino = Config.Casinos[casinoId]
    if not casino then return end
    for i=1, #casino.entities do
        if casino.entities[i].id == entityId then
            return casino.entities[i]
        end
    end
end

function GetCardModel(class, value)
    if class == "hidden" then
        return GetHashKey("vw_prop_cas_card_club_ace")
    end
    return GetHashKey("vw_prop_cas_card_" .. class .. "_" .. value)
end