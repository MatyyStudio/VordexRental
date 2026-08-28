Config = {}

-- | Framework Settings | --
-- We will use ox_core or bridge, but it's good to specify if needed.
Config.MoneyAccount = 'bank' -- 'cash' or 'bank'

-- | Rental Settings | --
Config.PlatePrefix = 'RENT' -- Max 4 characters recommended
Config.PenaltyMultiplier = 2.0 -- How much more it costs to extend when time expires (e.g., 2.0 = double the normal price)
Config.ExtensionTime = 10 -- How many minutes the penalty extension gives

Config.TimeLimits = {
    min = 5,
    max = 120
}

Config.DamageSettings = {
    -- If vehicle health drops below this, deposit starts getting reduced
    threshold = 950.0, 
    -- Max percentage of deposit that can be lost due to damage (0.0 to 1.0)
    maxDepositLoss = 1.0 
}

-- | Locations | --
Config.Locations = {
    {
        -- NPC spawn location
        pedCoords = vector4(-239.04, -987.05, 29.28, 160.5),
        pedModel = `a_m_y_business_02`,
        
        -- Where the rented vehicle will spawn
        vehicleSpawn = vector4(-241.0, -985.0, 29.28, 160.0),
        
        -- Where to return the vehicle (zone radius)
        returnZone = vector3(-241.0, -985.0, 29.28),
        returnRadius = 5.0,
        
        -- Blip settings
        blip = {
            enabled = true,
            sprite = 524,
            color = 2,
            scale = 0.8,
            label = "Vehicle Rental"
        }
    }
}

-- | Vehicle Categories & Pricing | --
Config.Vehicles = {
    ['bikes'] = {
        label = 'menu_bikes', -- refers to locale
        icon = 'bicycle',     -- FontAwesome icon for ox_lib menu
        list = {
            { model = 'bmx', label = 'BMX', pricePerMinute = 2, deposit = 50 },
            { model = 'scorcher', label = 'Scorcher', pricePerMinute = 3, deposit = 100 }
        }
    },
    ['cars'] = {
        label = 'menu_cars',
        icon = 'car',
        list = {
            { model = 'panto', label = 'Panto', pricePerMinute = 15, deposit = 1000 },
            { model = 'blista', label = 'Blista', pricePerMinute = 20, deposit = 1500 },
            { model = 'asbo', label = 'Asbo', pricePerMinute = 25, deposit = 2000 }
        }
    }
}