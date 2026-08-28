local rentedVehicle = nil
local isRenting = false
local rentalTimer = 0
local currentPlate = ""
local currentDeposit = 0
local basePricePerMin = 0

-- Inicializace NPC a Blipů při startu
CreateThread(function()
    for k, v in pairs(Config.Locations) do
        -- Blip
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

        -- NPC Ped
        RequestModel(v.pedModel)
        while not HasModelLoaded(v.pedModel) do Wait(0) end

        local ped = CreatePed(0, v.pedModel, v.pedCoords.x, v.pedCoords.y, v.pedCoords.z - 1.0, v.pedCoords.w, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        -- ox_target interaction na NPC
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'vordex_rental_npc',
                icon = 'fas fa-car-side',
                label = locale('target_npc'),
                onSelect = function()
                    OpenRentalMainMenu(v)
                end,
                canInteract = function()
                    return not isRenting -- NPC komunikuje jen pokud hráč zrovna nemá půjčené vozidlo
                end
            }
        })

        -- Návratová zóna (BoxZone)
        exports.ox_target:addBoxZone({
            coords = v.returnZone,
            size = vec3(v.returnRadius, v.returnRadius, 3.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'vordex_rental_return',
                    icon = 'fas fa-undo',
                    label = locale('target_return'),
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

-- Hlavní menu (Kategorie)
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

-- Seznam vozidel v kategorii
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

-- Proces půjčení (Čas a Platba)
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

    -- Callback na server pro zaplacení
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

-- Spawn vozidla
function SpawnRentalVehicle(model, coords, plate)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    rentedVehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w, true, false)
    SetVehicleNumberPlateText(rentedVehicle, plate)
    currentPlate = plate
    
    TaskWarpPedIntoVehicle(PlayerPedId(), rentedVehicle, -1)
    SetEntityAsMissionEntity(rentedVehicle, true, true)
    
    -- Odemknutí klíčů (Pokud používáš např. qb-vehiclekeys nebo ox_ignition, přidej export zde)
end

-- Logika odpočtu času
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

            -- Varování 1 min před koncem
            if rentalTimer == 60 then
                lib.notify({ title = locale('menu_title'), description = locale('notify_time_warning'), type = 'warning', duration = 5000 })
            end

            -- Čas vypršel
            if rentalTimer <= 0 then
                HandleExpiration(lastPayMethod)
                break
            end
        end
        lib.hideTextUI()
    end)
end

-- Konec času (Penalizace nebo odebrání)
function HandleExpiration(payMethod)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local penaltyPrice = math.floor((basePricePerMin * Config.ExtensionTime) * Config.PenaltyMultiplier)

    if veh == rentedVehicle and rentedVehicle ~= 0 then
        -- Hráč je ve vozidle
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
            -- Pokus o prodloužení
            lib.callback('vordex_rental:extend', false, function(success)
                if success then
                    rentalTimer = Config.ExtensionTime * 60
                    SetVehicleEngineOn(rentedVehicle, true, true, false)
                    -- Timer continues (isRenting is still true)
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
        -- Hráč není ve vozidle - rovnou smazat
        ForceRemoveVehicle()
    end
end

function ForceRemoveVehicle()
    isRenting = false
    if DoesEntityExist(rentedVehicle) then
        local netId = NetworkGetNetworkIdFromEntity(rentedVehicle)
        TriggerServerEvent('vordex_rental:deleteVehicle', netId)
    end
    rentedVehicle = nil
    currentPlate = ""
end

-- Vrácení vozidla přes target
function ReturnVehicle()
    local health = GetVehicleBodyHealth(rentedVehicle)
    local damageMultiplier = 0.0

    if health < Config.DamageSettings.threshold then
        local damageTaken = Config.DamageSettings.threshold - health
        damageMultiplier = (damageTaken / Config.DamageSettings.threshold) * Config.DamageSettings.maxDepositLoss
        if damageMultiplier > Config.DamageSettings.maxDepositLoss then damageMultiplier = Config.DamageSettings.maxDepositLoss end
    end

    local lostDeposit = math.floor(currentDeposit * damageMultiplier)
    local refundAmount = currentDeposit - lostDeposit

    lib.callback('vordex_rental:refund', false, function(success)
        if success then
            if lostDeposit > 0 then
                lib.notify({ title = locale('menu_title'), description = locale('notify_returned_dmg', refundAmount, lostDeposit), type = 'info' })
            else
                lib.notify({ title = locale('menu_title'), description = locale('notify_returned_full', refundAmount), type = 'success' })
            end
            ForceRemoveVehicle()
        end
    end, refundAmount)
end