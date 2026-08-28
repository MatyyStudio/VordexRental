-- ==========================================
-- FRAMEWORK BRIDGE (ESX / QBCore / ox_core)
-- ==========================================
local QBCore = GetResourceState('qb-core') == 'started' and exports['qb-core']:GetCoreObject() or nil
local ESX = GetResourceState('es_extended') == 'started' and exports['es_extended']:getSharedObject() or nil

function GetPlayerMoney(source, account)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.getAccount(account).money
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player.PlayerData.money[account]
    end
    return 0
end

function RemovePlayerMoney(source, account, amount)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getAccount(account).money >= amount then
            xPlayer.removeAccountMoney(account, amount)
            return true
        end
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player.PlayerData.money[account] >= amount then
            Player.Functions.RemoveMoney(account, amount, 'vordex-rental')
            return true
        end
    end
    return false
end

function AddPlayerMoney(source, account, amount)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.addAccountMoney(account, amount)
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        Player.Functions.AddMoney(account, amount, 'vordex-rental-refund')
    end
end

-- ==========================================
-- RENTAL LOGIC
-- ==========================================
local currentPlateNumber = 1

-- Generování SPZ "RENT 01" atd.
local function GeneratePlate()
    local plate = string.format("%s %02d", Config.PlatePrefix, currentPlateNumber)
    currentPlateNumber = currentPlateNumber + 1
    if currentPlateNumber > 99 then 
        currentPlateNumber = 1 
    end
    return plate
end

-- Platba za půjčení
lib.callback.register('vordex_rental:pay', function(source, minutes, pricePerMin, deposit, payMethod)
    local totalCost = (minutes * pricePerMin) + deposit
    
    if RemovePlayerMoney(source, payMethod, totalCost) then
        local plate = GeneratePlate()
        return true, plate
    else
        return false, nil
    end
end)

-- Platba za prodloužení (Penalizace)
lib.callback.register('vordex_rental:extend', function(source, penaltyPrice, payMethod)
    if RemovePlayerMoney(source, payMethod, penaltyPrice) then
        return true
    else
        return false
    end
end)

-- Vrácení kauce
lib.callback.register('vordex_rental:refund', function(source, refundAmount)
    if refundAmount > 0 then
        -- Vždy vracíme na bankovní účet z bezpečnostních důvodů, nebo podle nastavení
        AddPlayerMoney(source, 'bank', refundAmount) 
    end
    return true
end)

-- Smazání vozidla ze server-side (zabraňuje desyncu a ghost autům)
RegisterNetEvent('vordex_rental:deleteVehicle', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end)