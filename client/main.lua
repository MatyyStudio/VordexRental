local rentedVehicle = nil
local isRenting = false
local rentalTimer = 0
local currentPlate = ""
local currentDeposit = 0
local basePricePerMin = 0
local spawnedPeds = {}

-- Inicializace NPC a Blipů při startu
CreateThread(function()
    for i, v in ipairs(Config.Locations) do
        -- 1. Vytvoření blipu na mapě
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

        -- 2. Načtení a spawn NPC
        RequestModel(v.pedModel)
        while not HasModelLoaded(v.pedModel) do 
            Wait(10) 
        end

        local ped = CreatePed(0, v.pedModel, v.pedCoords.x, v.pedCoords.y, v.pedCoords.z - 1.0, v.pedCoords.w, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        table.insert(spawnedPeds, ped)

        -- OPRAVA: Počkáme 200ms, než se entita bezpečně zapíše do sítě klienta
        Wait(200)

        -- 3. Přidání targetu přímo na vytvořené NPC
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'vordex_rental_npc_' .. i,
                icon = 'fas fa-car-side',
                label = locale('target_npc'),
                distance = 2.0, -- Hráč musí být blízko, aby to fungovalo
                onSelect = function()
                    OpenRentalMainMenu(v)
                end,
                canInteract = function()
                    return not isRenting
                end
            }
        })

        -- 4. Návratová zóna
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

-- Smazání NPC při restartu scriptu (aby ti tam nezůstávali stát kloni)
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, ped in ipairs(spawnedPeds) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
    end
end)