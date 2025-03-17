Config = {}
Config.Language = "en"
Config.Debug = false -- This enables debugging prints.
Config.RenderDistance = 100.0
Config.InteractDistance = 2.0
Config.UseTarget = true -- This enables the use of the target system when available.

Config.Casinos = {
    ["casino-1"] = {
        entities = {
            {
                id = "blackjack-1",
                type = "blackjack",
                coords = vector3(-962.6842, -3006.3818, 12.9451),
                rotation = vector3(0.0, 0.0, 60.9669),
                settings = {
                    dealerModel = `s_f_y_casino_01`,
                    tableModel = `vw_prop_casino_blckjack_01b`,
                }
            },
            {
                id = "roulette-1",
                type = "roulette",
                coords = vector3(-964.8375, -3009.5615, 12.9451),
                rotation = vector3(0.0, 0.0, 60.9669),
                settings = {
                    dealerModel = `s_f_y_casino_01`,
                    tableModel = `vw_prop_casino_roulette_01`,
                }
            },
        }
    }
}