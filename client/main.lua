lib.locale() -- Load translations (fixes the issue with unloaded menu)

local rentedVehicle = nil
local vehicleBlip = nil -- Variable to store the player's personal vehicle blip
local isRenting = false
local rentalTimer = 0
local currentPlate = ""
local currentDeposit = 0
local basePricePerMin = 0
local spawnedPeds = {} -- Table to store NPCs so they can be deleted on resource stop

-- ==========================================
-- INITIALIZATION (Blips, NPCs, Zones)
-- ==========================================
CreateThread(function()
    for i, v in ipairs(Config.Locations) do
        -- 1. Create map blip for rental station
        if v.blip.enabled then
            local blip = AddBlipForCoord(v.pedCoords.x, v.pedCoords.y, v.pedCoords.z)
            SetBlipSprite(blip, v.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, v.blip.scale)
            SetBlipColour(blip, v.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.blip.label)
            EndTextCommandSetBlipName(blip)
        end

        -- 2. Load model and spawn NPC
        RequestModel(v.pedModel)
        while not HasModelLoaded(v.pedModel) do 
            Wait(10) 
        end

        local ped = CreatePed(0, v.pedModel, v.pedCoords.x, v.pedCoords.y, v.pedCoords.z - 1.0, v.pedCoords.w, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        table.insert(spawnedPeds, ped)

        -- 3. Short pause to safely register the entity in the game before adding the target
        Wait(200)

        -- 4. Add target to NPC using SphereZone for maximum reliability
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'vordex_rental_npc_' .. i,
                icon = 'fas fa-car-side',
                label = locale('target_npc'),
                distance = 2.0,
                onSelect = function()
                    OpenRentalMainMenu(v)
                end,
                canInteract = function()
                    return not isRenting -- NPC only interacts if the player is not currently renting a vehicle
                end
            }
        })

        -- 5. Return zone (where the vehicle is returned)
        exports.ox_target:addBoxZone({
            coords = v.returnZone,
            size = vec3(v.returnRadius, v.returnRadius, 3.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'vordex_rental_return_' .. i,
                    icon = 'fas fa-undo',
                    label = locale('target_return'),
                    distance = 3.0,
                    onSelect = function()
                        ReturnVehicle()
                    end,
                    canInteract = function()
                        return isRenting and rentedVehicle ~= nil
                    end
                }
            }
        })
    end
end)

-- Delete NPCs on script stop/restart to prevent duplicates
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, ped in ipairs(spawnedPeds) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
    end
end)

-- ==========================================
-- MENU LOGIC
-- ==========================================
function OpenRentalMainMenu(locationData)
    local options = {}

    for catKey, catData in pairs(Config.Vehicles) do
        table.insert(options, {
            title = locale(catData.label),
            icon = catData.icon,
            onSelect = function()
                OpenCategoryMenu(catKey, locationData)
            end
        })
    end

    lib.registerContext({
        id = 'vordex_rental_main',
        title = locale('menu_title'),
        options = options
    })

    lib.showContext('vordex_rental_main')
end

function OpenCategoryMenu(category, locationData)
    local options = {}

    for _, veh in ipairs(Config.Vehicles[category].list) do
        table.insert(options, {
            title = veh.label,
            description = string.format("$%s / min | Deposit: $%s", veh.pricePerMinute, veh.deposit),
            icon = 'fas fa-key',
            onSelect = function()
                StartRentingProcess(veh, locationData)
            end
        })
    end

    lib.registerContext({
        id = 'vordex_rental_category',
        title = locale(Config.Vehicles[category].label),
        menu = 'vordex_rental_main',
        options = options
    })

    lib.showContext('vordex_rental_category')
end

-- ==========================================
-- RENTAL AND SPAWN LOGIC
-- ==========================================
function StartRentingProcess(vehicleData, locationData)
    local input = lib.inputDialog(locale('time_input_title'), {
        {
            type = 'number', 
            label = locale('time_input_label', Config.TimeLimits.min, Config.TimeLimits.max), 
            required = true, 
            min = Config.TimeLimits.min, 
            max = Config.TimeLimits.max
        },
        {
            type = 'select', 
            label = locale('pay_method_label'), 
            required = true, 
            options = {
                { value = 'cash', label = locale('pay_cash') },
                { value = 'bank', label = locale('pay_bank') }
            }
        }
    })

    if not input then return end

    local minutes = input[1]
    local payMethod = input[2]

    -- Server callback for payment processing
    lib.callback('vordex_rental:pay', false, function(success, plate)
        if success then
            SpawnRentalVehicle(vehicleData.model, locationData.vehicleSpawn, plate)
            StartRentalTimer(minutes, vehicleData.deposit, vehicleData.pricePerMinute, payMethod)
            lib.notify({ title = locale('menu_title'), description = locale('notify_rented', vehicleData.label, minutes, vehicleData.deposit), type = 'success' })
        else
            lib.notify({ title = locale('menu_title'), description = locale('notify_no_money'), type = 'error' })
        end
    end, minutes, vehicleData.pricePerMinute, vehicleData.deposit, payMethod)
end

function SpawnRentalVehicle(model, coords, plate)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    -- Ensure the vehicle doesn't spawn inside another vehicle
    ClearAreaOfVehicles(coords.x, coords.y, coords.z, 3.0, false, false, false, false, false)

    rentedVehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w, true, false)
    SetVehicleNumberPlateText(rentedVehicle, plate)
    currentPlate = plate
    
    TaskWarpPedIntoVehicle(PlayerPedId(), rentedVehicle, -1)
    SetEntityAsMissionEntity(rentedVehicle, true, true)

    -- Create a personal tracking blip attached to the rented vehicle
    vehicleBlip = AddBlipForEntity(rentedVehicle)
    SetBlipSprite(vehicleBlip, 225) -- 225 represents a standard car icon
    SetBlipColour(vehicleBlip, 3)   -- 3 is blue color
    SetBlipScale(vehicleBlip, 0.75)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(locale('blip_rented_vehicle'))
    EndTextCommandSetBlipName(vehicleBlip)
    
    -- If you use qb-vehiclekeys, cd_garage or other key scripts, put the export here.
end

-- ==========================================
-- TIME COUNTDOWN AND PENALTY LOGIC
-- ==========================================
function StartRentalTimer(minutes, deposit, pricePerMin, lastPayMethod)
    isRenting = true
    rentalTimer = minutes * 60
    currentDeposit = deposit
    basePricePerMin = pricePerMin

    CreateThread(function()
        while isRenting do
            Wait(1000)
            rentalTimer = rentalTimer - 1
            
            -- Format UI
            local mins = math.floor(rentalTimer / 60)
            local secs = rentalTimer % 60
            lib.showTextUI(locale('ui_time_left', string.format("%02d:%02d", mins, secs), currentPlate))

            -- Warning 1 minute before expiration
            if rentalTimer == 60 then
                lib.notify({ title = locale('menu_title'), description = locale('notify_time_warning'), type = 'warning', duration = 5000 })
            end

            -- Time expired
            if rentalTimer <= 0 then
                HandleExpiration(lastPayMethod)
                break
            end
        end
        lib.hideTextUI()
    end)
end

function HandleExpiration(payMethod)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local penaltyPrice = math.floor((basePricePerMin * Config.ExtensionTime) * Config.PenaltyMultiplier)

    if veh == rentedVehicle and rentedVehicle ~= 0 then
        -- Player is inside the vehicle
        SetVehicleEngineOn(rentedVehicle, false, true, true)
        
        local alert = lib.alertDialog({
            header = locale('alert_expired_title'),
            content = locale('alert_expired_desc'),
            centered = true,
            cancel = true,
            labels = {
                confirm = locale('btn_extend', penaltyPrice),
                cancel = locale('btn_leave')
            }
        })

        if alert == 'confirm' then
            -- Attempt to extend time
            lib.callback('vordex_rental:extend', false, function(success)
                if success then
                    rentalTimer = Config.ExtensionTime * 60
                    SetVehicleEngineOn(rentedVehicle, true, true, false)
                    -- Countdown continues
                    StartRentalTimer(Config.ExtensionTime, currentDeposit, basePricePerMin, payMethod)
                else
                    lib.notify({ title = locale('menu_title'), description = locale('notify_no_money'), type = 'error' })
                    ForceRemoveVehicle()
                end
            end, penaltyPrice, payMethod)
        else
            ForceRemoveVehicle()
        end
    else
        -- Player is not in the vehicle - force delete
        ForceRemoveVehicle()
    end
end

function ForceRemoveVehicle()
    isRenting = false
    
    -- Remove the personal map blip if it exists
    if vehicleBlip and DoesBlipExist(vehicleBlip) then
        RemoveBlip(vehicleBlip)
        vehicleBlip = nil
    end

    -- Delete the vehicle entity server-side
    if DoesEntityExist(rentedVehicle) then
        local netId = NetworkGetNetworkIdFromEntity(rentedVehicle)
        TriggerServerEvent('vordex_rental:deleteVehicle', netId)
    end
    
    rentedVehicle = nil
    currentPlate = ""
end

-- ==========================================
-- VEHICLE RETURN (Damage and time calculation)
-- ==========================================
function ReturnVehicle()
    local health = GetVehicleBodyHealth(rentedVehicle)
    local damageMultiplier = 0.0

    -- 1. Damage calculation (deposit deduction)
    if health < Config.DamageSettings.threshold then
        local damageTaken = Config.DamageSettings.threshold - health
        damageMultiplier = (damageTaken / Config.DamageSettings.threshold) * Config.DamageSettings.maxDepositLoss
        if damageMultiplier > Config.DamageSettings.maxDepositLoss then 
            damageMultiplier = Config.DamageSettings.maxDepositLoss 
        end
    end

    local lostDeposit = math.floor(currentDeposit * damageMultiplier)
    local depositRefund = currentDeposit - lostDeposit

    -- 2. Early return calculation (time penalty)
    local timeRefund = 0
    local remainingMinutes = math.floor(rentalTimer / 60)
    
    if remainingMinutes > 0 then
        -- Calculate the value of unused time
        local unusedTimeValue = remainingMinutes * basePricePerMin
        -- Refund only a portion to the player based on config
        timeRefund = math.floor(unusedTimeValue * Config.EarlyReturnRefund)
    end

    -- Total refund amount
    local totalRefund = depositRefund + timeRefund

    -- 3. Send to server and display notification
    lib.callback('vordex_rental:refund', false, function(success)
        if success then
            -- Build a clear notification message for the player
            local desc = locale('notify_return_deposit', depositRefund)
            
            if timeRefund > 0 then
                desc = desc .. "\n" .. locale('notify_return_time', timeRefund)
            end
            
            if lostDeposit > 0 then
                desc = desc .. "\n" .. locale('notify_return_dmg_fee', lostDeposit)
            end

            lib.notify({ 
                title = locale('menu_return'), 
                description = desc, 
                type = lostDeposit > 0 and 'warning' or 'success',
                duration = 7000
            })
            
            ForceRemoveVehicle()
        end
    end, totalRefund)
end