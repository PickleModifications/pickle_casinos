Config = {}
Config.Language = "en"
Config.Debug = false -- This enables debugging prints.
Config.RenderDistance = 50.0
Config.InteractDistance = 2.5
Config.UseTarget = true -- This enables the use of the target system when available.
Config.WaitingTime = 10 -- Time to wait before starting a round for players to place bets.
Config.SeatTurnTime = 10 -- Time to wait for players to place bets / decide before moving to the next player.
Config.UseObjectGizmo = false -- This enables the use of object_gizmo for placing objects. If false, it uses the default movement system.
Config.MaximumChipPurchaseAmount = 1000000 -- Maximum amount of chips a player can purchase at once.
Config.MaximumItemPurchaseAmount = 100 -- Maximum amount of items a player can purchase at once.
Config.ImageDirectory = "nui://ox_inventory/web/images/" -- (QB: nui://qb-inventory/html/images/) This is the directory where the images are stored. It should be a relative path to the resource folder.

Config.Currency = {
    currency = "USD",
    countryCode = "en-US",
}

Config.TargetIcons = {
    cashier = "fa-solid fa-coins",
    stores = "fa-solid fa-basket-shopping",
    management = "fa-solid fa-gear",
    blackjack = "fa-solid fa-play",
    roulette = "fa-solid fa-play",
    baccarat = "fa-solid fa-play",
    poker = "fa-solid fa-play",
    wheel = "fa-solid fa-play",
    horseracing = "fa-solid fa-play",
    slots = "fa-solid fa-play",
}

Config.AdminGroups = { -- These are the groups that are allowed to use the /casino command.
    "admin",
    "superadmin",
    "god",
}

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

Config.TargetedModels = { -- These are the models that when scanning with /mapobjects will be added to the map objects list.
    -- SLOT MACHINES
    `vw_prop_casino_slot_01a`,
    `vw_prop_casino_slot_02a`,
    `vw_prop_casino_slot_03a`,
    `vw_prop_casino_slot_04a`,
    `vw_prop_casino_slot_05a`,
    `vw_prop_casino_slot_06a`,
    `vw_prop_casino_slot_07a`,
    `vw_prop_casino_slot_08a`,
    -- BLACKJACK TABLES
    `vw_prop_casino_blckjack_01`,
    `h4_prop_casino_blckjack_01a`,
    `h4_prop_casino_blckjack_01b`,
    `h4_prop_casino_blckjack_01c`,
    `h4_prop_casino_blckjack_01d`,
    `h4_prop_casino_blckjack_01e`,
    `vw_prop_casino_blckjack_01b`,
    -- ROULETTE TABLES
    `vw_prop_casino_roulette_01`,
    `vw_prop_casino_roulette_01b`,
    -- THREE CARD POKER TABLES
    `vw_prop_casino_3cardpoker_01`,
    `h4_prop_casino_3cardpoker_01c`,
    `h4_prop_casino_3cardpoker_01b`,
    `ch_prop_casino_poker_01a`,
    `h4_prop_casino_3cardpoker_01e`,
    `ch_prop_casino_poker_01b`,
    `h4_prop_casino_3cardpoker_01a`,
    `h4_prop_casino_3cardpoker_01d`,
    -- WHEEL
    `vw_prop_vw_luckywheel_01a`,
    `vw_prop_vw_luckywheel_02a`,
}

Config.FrameworkSettings = {
    -- Note to framework creators: stop breaking your frameworks by moving / removing stuff in big 2025, if it continues I'm making pickle core
    society = "qb-management", -- This is the society that the casinos will use to pay taxes. (qb-management or qb-banking, if using ESX don't worry it's automatic)
}

Config.Casinos = {
    tax = 10, -- Percentage of the profit that the casino pays in tax when withdrawing clean cash from the management system.
    taxRecipients = { -- This should always add up to 100%; above is where you set the percentage of the tax.
        ["police"] = 50, -- The percentage of the tax paid by the casinos to this society.
        ["ambulance"] = 50, -- The percentage of the tax paid by the casinos to this society.
    },
    profitPercent = 5 -- (0-100) Percentage of the profit that the casino takes from the store.
}

Config.CreatorOptions = {
    -- MODELS MUST BE `MODEL_NAME` NOT "MODEL_NAME"
    stores = {
        {
            label = "Burgershot",
            items = {
                {item = "hamburger", price = 10},
                {item = "crisps", price = 3},
                {item = "soda", price = 2},
            }
        },
        {
            label = "Pickle's Brewery",
            items = {
                {item = "cigbox", price = 10},
                {item = "cigarette", price = 2},
                {item = "beer", price = 3},
                {item = "gin_shot", price = 4},
                {item = "vodka_shot", price = 5},
                {item = "whiskey_bottle", price = 15},
                {item = "tequila_bottle", price = 25},
                {item = "vodka_bottle", price = 50},
            }
        },
    },
    dealerModels = {
        {
            label = "Male Dealer #1", 
            model = `s_m_y_casino_01`,
            pedComponents = {
                {id = 0, drawable = 3, texture = 0}, -- Head
                {id = 1, drawable = 1, texture = 0}, -- Beard
                {id = 2, drawable = 3, texture = 0}, -- Hair   
                {id = 3, drawable = 1, texture = 0}, -- Upper
                {id = 4, drawable = 0, texture = 0}, -- Lower
                {id = 5, drawable = 0, texture = 0}, -- Hand
                {id = 6, drawable = 1, texture = 0}, -- Feet
                {id = 7, drawable = 2, texture = 0}, -- Teeth
                {id = 8, drawable = 3, texture = 0}, -- Accessories
                {id = 9, drawable = 0, texture = 0}, -- Task
                {id = 10, drawable = 1, texture = 0}, -- Decals
                {id = 11, drawable = 1, texture = 0}, -- Torso
            }
        },
        {
            label = "Male Dealer #2", 
            model = `s_m_y_casino_01`,
            pedComponents = {
                {id = 0, drawable = 2, texture = 0}, -- Head
                {id = 1, drawable = 1, texture = 0}, -- Beard
                {id = 2, drawable = 4, texture = 0}, -- Hair   
                {id = 3, drawable = 0, texture = 0}, -- Upper
                {id = 4, drawable = 0, texture = 0}, -- Lower
                {id = 5, drawable = 0, texture = 0}, -- Hand
                {id = 6, drawable = 1, texture = 0}, -- Feet
                {id = 7, drawable = 2, texture = 0}, -- Teeth
                {id = 8, drawable = 1, texture = 0}, -- Accessories
                {id = 9, drawable = 0, texture = 0}, -- Task
                {id = 10, drawable = 1, texture = 0}, -- Decals
                {id = 11, drawable = 1, texture = 0}, -- Torso
            }
        },
        {
            label = "Male Dealer #3", 
            model = `s_m_y_casino_01`,
            pedComponents = {
                {id = 0, drawable = 0, texture = 0}, -- Head
                {id = 1, drawable = 0, texture = 0}, -- Beard
                {id = 2, drawable = 0, texture = 0}, -- Hair   
                {id = 3, drawable = 0, texture = 0}, -- Upper
                {id = 4, drawable = 0, texture = 0}, -- Lower
                {id = 5, drawable = 0, texture = 0}, -- Hand
                {id = 6, drawable = 0, texture = 0}, -- Feet
                {id = 7, drawable = 0, texture = 0}, -- Teeth
                {id = 8, drawable = 0, texture = 0}, -- Accessories
                {id = 9, drawable = 0, texture = 0}, -- Task
                {id = 10, drawable = 0, texture = 0}, -- Decals
                {id = 11, drawable = 0, texture = 0}, -- Torso
            }
        },
        {
            label = "Female Dealer #1", 
            model = `s_f_y_casino_01`,
            pedComponents = {
                {id = 0, drawable = 3, texture = 0}, -- Head
                {id = 1, drawable = 0, texture = 0}, -- Beard
                {id = 2, drawable = 3, texture = 0}, -- Hair   
                {id = 3, drawable = 0, texture = 0}, -- Upper
                {id = 4, drawable = 1, texture = 0}, -- Lower
                -- {id = 5, drawable = 1, texture = 0}, -- Hand
                {id = 6, drawable = 1, texture = 0}, -- Feet
                {id = 7, drawable = 1, texture = 0}, -- Teeth
                {id = 8, drawable = 0, texture = 0}, -- Accessories
                -- {id = 9, drawable = 0, texture = 0}, -- Task
                {id = 10, drawable = 0, texture = 0}, -- Decals
                {id = 11, drawable = 0, texture = 0}, -- Torso
            }
        },
        {
            label = "Female Dealer #2", 
            model = `s_f_y_casino_01`,
            pedComponents = {
                {id = 0, drawable = 2, texture = 0}, -- Head
                {id = 1, drawable = 0, texture = 0}, -- Beard
                {id = 2, drawable = 2, texture = 0}, -- Hair   
                {id = 3, drawable = 3, texture = 0}, -- Upper
                {id = 4, drawable = 1, texture = 0}, -- Lower
                -- {id = 5, drawable = 0, texture = 0}, -- Hand
                {id = 6, drawable = 1, texture = 0}, -- Feet
                {id = 7, drawable = 2, texture = 0}, -- Teeth
                {id = 8, drawable = 3, texture = 0}, -- Accessories
                -- {id = 9, drawable = 0, texture = 0}, -- Task
                {id = 10, drawable = 0, texture = 0}, -- Decals
                {id = 11, drawable = 0, texture = 0}, -- Torso
            }
        },
        {
            label = "Female Dealer #3", 
            model = `s_f_y_casino_01`,
            pedComponents = {
                {id = 0, drawable = 0, texture = 0}, -- Head
                {id = 1, drawable = 0, texture = 0}, -- Beard
                {id = 2, drawable = 0, texture = 0}, -- Hair   
                {id = 3, drawable = 0, texture = 0}, -- Upper
                {id = 4, drawable = 0, texture = 0}, -- Lower
                {id = 5, drawable = 0, texture = 0}, -- Hand
                {id = 6, drawable = 0, texture = 0}, -- Feet
                {id = 7, drawable = 0, texture = 0}, -- Teeth
                {id = 8, drawable = 0, texture = 0}, -- Accessories
                {id = 9, drawable = 0, texture = 0}, -- Task
                {id = 10, drawable = 0, texture = 0}, -- Decals
                {id = 11, drawable = 0, texture = 0}, -- Torso
            }
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

------------------------------------------------------------------------------------------------------------------------
-- DO NOT TOUCH THE BELOW UNLESS YOU KNOW WHAT YOU'RE DOING, I WILL NOT HELP YOU WITH THIS (unless i broke it)
------------------------------------------------------------------------------------------------------------------------

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
        model = `fury_p_slot_01`,
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
        model = `fury_p_slot_02`,
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
    ["candybonanza"] = {
        label = "Candy Bonanza",
        model = `fury_p_slot_03`,
        foldername = "candybonanza",
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
            ["Peppermint"] = {
                image = "peppermint.png",
                reels = {15, 12, 10, 10, 15},
                pay = {0, 0, 3, 7, 30},
            },
            ["Candystick"] = {
                image = "candystick.png",
                reels = {15, 15, 10, 10, 15},
                pay = {0, 0, 1.5, 3.5, 10},
            },
            ["Banana Pop"] = {
                image = "banana_pop.png",
                reels = {15, 12, 10, 10, 12},
                pay = {0, 0, 1.2, 2, 6},
            },
            ["Pickle Pop"] = {
                image = "pickle_pop.png",
                reels = {11, 11, 10, 10, 11},
                pay = {0, 0, 0.8, 1.5, 4},
            },
            ["Strawberry Pop"] = {
                image = "strawberry_pop.png",
                reels = {10, 10, 10, 10, 10},
                pay = {0, 0, 0.35, 0.6, 1.75},
            },
            ["Raspberry Pop"] = {
                image = "raspberry_pop.png",
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
    machineModel = `npds_bettingmachine_01`,
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