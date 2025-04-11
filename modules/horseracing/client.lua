local horses = {}

CreateThread(function()
    Wait(1000)
    print("start")
    local raceCenter = vector3(1158.0900, 258.6992, 80.8438)
    local heading = 147.9117
    local horse = {}
    horse.ped = CreateNPC(`PDHorse`, raceCenter.x, raceCenter.y, raceCenter.z, false, false)
    horse.surfaceObject = CreateProp(`prop_tennis_ball`, raceCenter.x, raceCenter.y, raceCenter.z, false, false, false)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, horse in pairs(horses) do
            DeleteEntity(horse.ped)
            DeleteEntity(horse.surfaceObject)
        end
    end
end)