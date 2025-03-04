Config = {}

-- General Settings
Config.Debug = true -- Set to true to enable debug prints
Config.AdminGroups = { -- Groups that can use the /placebag command
    ['admin'] = true,
    ['god'] = true
}

-- Blip Settings
Config.BlipSettings = {
    sprite = 501, -- Default blip sprite (501 = present/gift)
    color = 2, -- Default blip color (2 = green)
    scale = 0.8, -- Size of the blip on the map
    name = "Mystery Bag", -- Default name shown on the map
    shortRange = true -- Whether the blip is only shown when nearby
}

-- Prop Settings
Config.PropSettings = {
    defaultProp = "prop_cs_heist_bag_01", -- Default prop model
    defaultRotation = {x = 0.0, y = 0.0, z = 0.0}, -- Default rotation of the prop
}

-- Item Types Configuration
Config.ItemTypes = {
    -- Drugs
    ["drugs"] = {
        items = {
            ["weed_white-widow"] = {
                label = "White Widow",
                amount = {min = 1, max = 3}, -- Random amount between min and max
                chance = 70, -- % chance this item will be selected when type is "drugs"
                blipColor = 2, -- Green
                blipName = "Drug Package"
            },
            ["cokebaggy"] = {
                label = "Bag of Coke",
                amount = {min = 3, max = 8},
                chance = 50,
                blipColor = 1, -- Red
                blipName = "Drug Package"
            },
            ["meth"] = {
                label = "Meth",
                amount = {min = 3, max = 10},
                chance = 40,
                blipColor = 3, -- Blue
                blipName = "Drug Package"
            }
        },
        prop = "hei_prop_pill_bag_01", -- Custom prop for drug packages
    },
    
    -- Weapons
    ["weapons"] = {
        items = {
            ["weapon_pistol"] = {
                label = "Pistol",
                amount = 1,
                chance = 60,
                blipColor = 1, -- Red
                blipName = "Weapon Stash"
            },
            ["weapon_smg"] = {
                label = "SMG",
                amount = 1,
                chance = 30,
                blipColor = 1, -- Red
                blipName = "Weapon Stash"
            },
            ["weapon_pumpshotgun"] = {
                label = "Pump Shotgun",
                amount = 1,
                chance = 20,
                blipColor = 1, -- Red
                blipName = "Weapon Stash"
            },
            ["pistol_ammo"] = {
                label = "Pistol Ammo",
                amount = {min = 10, max = 30},
                chance = 80,
                blipColor = 1, -- Red
                blipName = "Ammo Stash"
            }
        },
        prop = "prop_gun_case_01", -- Custom prop for weapon packages
    },
    
    -- Money/Valuables
    ["valuables"] = {
        items = {
            ["markedbills"] = {
                label = "Marked Bills",
                amount = {min = 1, max = 3},
                chance = 50,
                blipColor = 5, -- Yellow
                blipName = "Valuable Package"
            },
            ["goldbar"] = {
                label = "Gold Bar",
                amount = {min = 1, max = 2},
                chance = 20,
                blipColor = 5, -- Yellow
                blipName = "Valuable Package"
            },
            ["diamond"] = {
                label = "Diamond",
                amount = {min = 1, max = 3},
                chance = 10,
                blipColor = 5, -- Yellow
                blipName = "Valuable Package"
            }
        },
        prop = "prop_cash_case_02", -- Custom prop for valuable packages
    }
} 