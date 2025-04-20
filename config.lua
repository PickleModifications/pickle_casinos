Config = {}
Config.Language = "en"
Config.Debug = false -- This enables debugging prints.
Config.RenderDistance = 50.0
Config.InteractDistance = 2.0
Config.UseTarget = true -- This enables the use of the target system when available.
Config.WaitingTime = 10 -- Time to wait before starting a round for players to place bets.
Config.SeatTurnTime = 10 -- Time to wait for players to place bets / decide before moving to the next player.

Config.Chips = {
    {color = "#15803D", value = 1},
    {color = "#C2410C", value = 5},
    {color = "#BE185D", value = 10},
    {color = "#3F3F46", value = 100},
    {color = "#0369A1", value = 1000},
    {color = "#15803D", value = 10000},
    {color = "#C2410C", value = 25000},
    {color = "#BE185D", value = 100000},
    {color = "#3F3F46", value = 250000},
    {color = "#0369A1", value = 1000000},
}

Config.CreatorOptions = {
     -- MODELS MUST BE `MODEL_NAME` NOT "MODEL_NAME"
    dealerModels = {
        {
            label = "Dealer #1", 
            model = `s_m_y_casino_01`,
            pedComponents = {}
        },
        {
            label = "Dealer #2", 
            model = `s_f_y_casino_01`,
            pedComponents = {}
        },
    },
    blackjack = {
        tableModels = {
            {label = "Table #1", model = `h4_prop_casino_blckjack_01a`},
            {label = "Table #2", model = `vw_prop_casino_blckjack_01`},
            {label = "Table #3", model = `h4_prop_casino_blckjack_01c`},
            {label = "Table #4", model = `h4_prop_casino_blckjack_01e`},
            {label = "Table #5", model = `vw_prop_casino_blckjack_01b`},
            {label = "Table #6", model = `h4_prop_casino_blckjack_01d`},
            {label = "Table #7", model = `h4_prop_casino_blckjack_01b`},
        }
    },
    roulette = {
        tableModels = {
            {label = "Table #1", model = `vw_prop_casino_roulette_01`},
            {label = "Table #2", model = `vw_prop_casino_roulette_01b`},
        }
    },
    baccarat = {
        tableModels = {
            {label = "Table #1", model = `fury_p_baccarat`},
        }
    },
    poker = {
        tableModels = {
            {label = "Table #1", model = `fury_p_poker_table`},
        }
    },
    wheel = {}, -- No additional settings
    horseracing = {}, -- No additional settings
    slots = {}, -- No additional settings
}

-- Config.Casinos = {
--     ["casino-1"] = {
--         entities = {
--             {
--                 id = "blackjack-1",
--                 type = "blackjack",
--                 coords = vector3(1102.4396972656, -2315.6953125, 23.347464752197),
--                 rotation = vector3(0.0, 0.0, 172.6324),
--                 settings = {
--                     dealerModel = `s_f_y_casino_01`,
--                     tableModel = `vw_prop_casino_blckjack_01b`,
--                 }
--             },
--             {
--                 id = "roulette-1",
--                 type = "roulette",
--                 coords = vector3(-964.8375, -3009.5615, 12.9451),
--                 rotation = vector3(0.0, 0.0, 60.9669),
--                 settings = {
--                     dealerModel = `s_f_y_casino_01`,
--                     tableModel = `vw_prop_casino_roulette_01`,
--                 }
--             },
--             {
--                 id = "baccarat-1",
--                 type = "baccarat",
--                 coords = vector3(-959.4362, -3008.0134, 12.9451),
--                 rotation = vector3(0.0, 0.0, 240.9669),
--                 settings = {
--                     dealerModel = `s_f_y_casino_01`,
--                     tableModel = `fury_p_baccarat`,
--                 }
--             },
--             -- {
--             --     id = "slot-1",
--             --     type = "slot",
--             --     coords = vector3(1075.7423, -2323.3606, 23.4540),
--             --     rotation = vector3(0.0, 0.0, 84.3254),
--             --     settings = {
--             --         game = "spacewarriors",
--             --         betRange = {min = 1000, max = 10000},
--             --     }
--             -- },
--             {
--                 id = "poker-1",
--                 type = "poker",
--                 coords = vector3(1100.8215, -2326.7092, 23.2540),
--                 rotation = vector3(0.0, 0.0, 264.6634),
--                 settings = {
--                     smallBlind = 10,
--                     bigBlind = 15,
--                     dealerModel = `s_f_y_casino_01`,
--                     tableModel = `fury_p_poker_table`,
--                 }
--             },
--             {
--                 id = "poker-2",
--                 type = "poker",
--                 coords = vector3(1096.9214, -2326.3220, 23.2540),
--                 rotation = vector3(0.0, 0.0, 85.4802),
--                 settings = {
--                     dealerModel = `s_f_y_casino_01`,
--                     tableModel = `fury_p_poker_table`,
--                 }
--             },
--             {
--                 id = "wheel-1",
--                 type = "wheel",
--                 coords = vector3(1076.3964, -2316.6580, 23.4540),
--                 rotation = vector3(0.0, 0.0, 263.7225),
--                 settings = {}
--             },
--             {
--                 id = "horseracing-1",
--                 type = "horseracing",
--                 coords = vector3(1100.4280, -2310.2136, 23.4540),
--                 rotation = vector3(0.0, 0.0, 178.0722),
--                 settings = {}
--             }
--         }
--     }
-- }

Config.Poker = {
    buttonModel = `vw_prop_vw_colle_imporage`, -- This prop indicates who is the dealer.
}

Config.WheelMultiplier = {
    two = 2,
    three = 3,
    five = 5,
    eleven = 11,
    twentyThree = 23,
    -- Bonus is handled in Config.WheelBonus
}

Config.WheelBonus = {
    {
        multiplier = 5,
        chance = 115,
    },
    {
        multiplier = 10,
        chance = 110,
    },
    {
        multiplier = 25,
        chance = 105,
    },
    {
        multiplier = 50,
        chance = 100,
    },
    {
        multiplier = 100,
        chance = 25,
    },
    {
        multiplier = 1000,
        chance = 1,
    },
}

Config.Slots = {
    ["bananabonanza"] = {
        label = "Banana Bonanza",
        model = `vw_prop_casino_slot_05a`,
        foldername = "bananabonanza",
        headerTextImage = "header_title.png",
        backgroundImage = "background.png",
        reelCount = 5,
        reelSymbols = 3,
        paylineWinThreshold = 3,
        bonusTriggerCount = 3,
        bonusFreeSpins = 15,
        bonusSymbol = "Bonus Symbol",
        slotSymbols = {
            ["Bonus Symbol"] = {
                image = "bonus.png",
                reels = {8, 8, 1, 1, 1},
                pay = {0, 0, 0, 0, 0},
            },
            ["Monkey"] = {
                image = "monkey.png",
                reels = {15, 12, 10, 10, 15},
                pay = {0, 0, 3, 7, 30},
            },
            ["Coconut"] = {
                image = "coconut.png",
                reels = {15, 15, 10, 10, 15},
                pay = {0, 0, 1.5, 3.5, 10},
            },
            ["Coconut Tree Bundle"] = {
                image = "tree_2.png",
                reels = {15, 12, 10, 10, 12},
                pay = {0, 0, 1.2, 2, 6},
            },
            ["Coconut Tree"] = {
                image = "tree_1.png",
                reels = {11, 11, 10, 10, 11},
                pay = {0, 0, 0.8, 1.5, 4},
            },
            ["Banana Bunch"] = {
                image = "banana_2.png",
                reels = {10, 10, 10, 10, 10},
                pay = {0, 0, 0.35, 0.6, 1.75},
            },
            ["Banana"] = {
                image = "banana_1.png",
                reels = {10, 10, 10, 10, 10},
                pay = {0, 0, 0.2, 0.35, 1.25},
            },
        },
        paylines = {
            {1, 1, 1, 1, 1},
            {0, 0, 0, 0, 0},
            {2, 2, 2, 2, 2},
            {0, 1, 2, 1, 0},
            {2, 1, 0, 1, 2},
            {1, 0, 0, 0, 1},
            {1, 2, 2, 2, 1},
            {0, 0, 1, 2, 2},
            {2, 2, 1, 0, 0},
            {1, 2, 1, 0, 1},
            {1, 0, 1, 2, 1},
            {0, 1, 1, 1, 0},
            {2, 1, 1, 1, 2},
            {0, 1, 0, 1, 0},
            {2, 1, 2, 1, 2},
            {1, 1, 0, 1, 1},
            {1, 1, 2, 1, 1},
            {0, 0, 2, 0, 0},
            {2, 2, 0, 2, 2},
            {0, 2, 2, 2, 0},
        },
    },
    ["spacewarriors"] = {
        label = "Space Warriors",
        model = `vw_prop_casino_slot_03a`,
        foldername = "spacewarriors",
        headerTextImage = "header_title.png",
        backgroundImage = "background.png",
        reelCount = 5,
        reelSymbols = 3,
        paylineWinThreshold = 3,
        bonusTriggerCount = 3,
        bonusFreeSpins = 15,
        bonusSymbol = "Bonus Symbol",
        slotSymbols = {
            ["Bonus Symbol"] = {
                image = "bonus.png",
                reels = {8, 8, 1, 1, 1},
                pay = {0, 0, 0, 0, 0},
            },
            ["Spaceship"] = {
                image = "spaceship.png",
                reels = {15, 12, 10, 10, 15},
                pay = {0, 0, 3, 7, 30},
            },
            ["Rocket"] = {
                image = "rocket.png",
                reels = {15, 15, 10, 10, 15},
                pay = {0, 0, 1.5, 3.5, 10},
            },
            ["Blaster"] = {
                image = "blaster.png",
                reels = {15, 12, 10, 10, 12},
                pay = {0, 0, 1.2, 2, 6},
            },
            ["Mars"] = {
                image = "mars.png",
                reels = {11, 11, 10, 10, 11},
                pay = {0, 0, 0.8, 1.5, 4},
            },
            ["Earth"] = {
                image = "earth.png",
                reels = {10, 10, 10, 10, 10},
                pay = {0, 0, 0.35, 0.6, 1.75},
            },
            ["Asteroid"] = {
                image = "asteroid.png",
                reels = {10, 10, 10, 10, 10},
                pay = {0, 0, 0.2, 0.35, 1.25},
            },
        },
        paylines = {
            {1, 1, 1, 1, 1},
            {0, 0, 0, 0, 0},
            {2, 2, 2, 2, 2},
            {0, 1, 2, 1, 0},
            {2, 1, 0, 1, 2},
            {1, 0, 0, 0, 1},
            {1, 2, 2, 2, 1},
            {0, 0, 1, 2, 2},
            {2, 2, 1, 0, 0},
            {1, 2, 1, 0, 1},
            {1, 0, 1, 2, 1},
            {0, 1, 1, 1, 0},
            {2, 1, 1, 1, 2},
            {0, 1, 0, 1, 0},
            {2, 1, 2, 1, 2},
            {1, 1, 0, 1, 1},
            {1, 1, 2, 1, 1},
            {0, 0, 2, 0, 0},
            {2, 2, 0, 2, 2},
            {0, 2, 2, 2, 0},
        },
    },
}

Config.HorseRacing = {
    machineModel = `ch_prop_arcade_street_01b`,
    tracks = {
        {
            label = "Track #1",
            coords = vector3(1158.0900, 258.6992, 80.8438),
            heading = 147.9117,
            distance = 171.15, -- Length of the track in meters
            renderDistance = 500.0, -- Distance at which the track and horses will render for people nearby.
        },
        {
            label = "Track #2",
            coords = vector3(1266.5555, 191.2764, 80.8438),
            heading = 147.9117,
            distance = 171.15, -- Length of the track in meters
            renderDistance = 500.0, -- Distance at which the track and horses will render for people nearby.
        }
    },
    odds = {
        {
            label = "40/1",
            multiplier = 40,
            chances = 2,
        },
        {
            label = "30/1",
            multiplier = 30,
            chances = 3,
        },
        {
            label = "20/1",
            multiplier = 20,
            chances = 4,
        },
        {
            label = "15/1",
            multiplier = 15,
            chances = 5,
        },
        {
            label = "10/1",
            multiplier = 10,
            chances = 6,
        },
        {
            label = "7/1",
            multiplier = 7,
            chances = 7,
        },
        {
            label = "5/1",
            multiplier = 5,
            chances = 9,
        },
        {
            label = "4/1",
            multiplier = 4,
            chances = 10,
        },
        {
            label = "3/1",
            multiplier = 3,
            chances = 12,
        },
        {
            label = "2/1",
            multiplier = 2,
            chances = 16,
        },
        {
            label = "1/1",
            multiplier = 1,
            chances = 32,
        },
        {
            label = "1/2",
            multiplier = 0.5,
            chances = 64,
        },
    }
}