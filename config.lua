Config = {}

-- | Framework Settings | --
-- We will use ox_core or bridge, but it's good to specify if needed.
Config.MoneyAccount = 'bank' -- 'cash' or 'bank'

-- | Rental Settings | --
Config.PlatePrefix = 'RENT' -- Max 4 characters recommended
Config.PenaltyMultiplier = 2.0 -- How much more it costs to extend when time expires (e.g., 2.0 = double the normal price)
Config.ExtensionTime = 10 -- How many minutes the penalty extension gives
Config.EarlyReturnRefund = 0.5 -- How much of the money for the unused time will be refunded (0.5 = 50%; the remainder is a penalty for early return)

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
    -- 1. Legion Square (Centrum)
    {
        pedCoords = vector4(163.11, -1004.59, 29.35, 340.0),
        pedModel = `a_m_y_business_02`,
        vehicleSpawn = vector4(160.0, -1000.0, 29.3, 340.0),
        returnZone = vector3(160.0, -1000.0, 29.3),
        returnRadius = 5.0,
        blip = { enabled = true, sprite = 524, color = 2, scale = 0.8, label = "Půjčovna - Centrum" }
    },
    -- 2. Letiště (Los Santos International)
    {
        pedCoords = vector4(-1034.6, -2733.6, 20.16, 330.0),
        pedModel = `a_m_y_business_02`,
        vehicleSpawn = vector4(-1030.0, -2730.0, 20.1, 330.0),
        returnZone = vector3(-1030.0, -2730.0, 20.1),
        returnRadius = 5.0,
        blip = { enabled = true, sprite = 524, color = 2, scale = 0.8, label = "Půjčovna - Letiště" }
    },
    -- 3. Sandy Shores
    {
        pedCoords = vector4(1966.1, 3744.1, 32.2, 30.0),
        pedModel = `a_m_m_hillbilly_01`, -- Lokální redneck NPC
        vehicleSpawn = vector4(1960.0, 3750.0, 32.2, 30.0),
        returnZone = vector3(1960.0, 3750.0, 32.2),
        returnRadius = 5.0,
        blip = { enabled = true, sprite = 524, color = 2, scale = 0.8, label = "Půjčovna - Sandy Shores" }
    },
    -- 4. Paleto Bay
    {
        pedCoords = vector4(-117.5, 6461.5, 31.5, 45.0),
        pedModel = `a_m_y_business_02`,
        vehicleSpawn = vector4(-110.0, 6465.0, 31.5, 45.0),
        returnZone = vector3(-110.0, 6465.0, 31.5),
        returnRadius = 5.0,
        blip = { enabled = true, sprite = 524, color = 2, scale = 0.8, label = "Půjčovna - Paleto Bay" }
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