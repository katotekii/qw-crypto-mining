local PlayerCryptoCache = {}

lib.callback.register('qw-crypto-mining:server:getPlayerCryptoMiningData', function(source)
    local src = source
    local citizenId = server.GetIdentifier(src)

    if PlayerCryptoCache[citizenId] ~= nil then
        if Config.Debug then print('Using cached data for ' .. citizenId) end
        return PlayerCryptoCache[citizenId]
    else
        local playerCryptoData = MySQL.query.await('SELECT * FROM player_crypto_mining WHERE citizenid = @citizenid', {
            ['@citizenid'] = citizenId
        })

        if playerCryptoData[1] and playerCryptoData ~= "[]" then 
            if Config.Debug then print('Using database data for ' .. citizenId) end
            cryptoData = playerCryptoData[1]
            PlayerCryptoCache[citizenId] = cryptoData
            TriggerClientEvent('QBCore:Notify', src, 'Rig is Starting up!', 'success')
            return cryptoData
        else
            if Config.Debug then print('No data found for ' .. citizenId) end
            return false
        end
    end

    return false
end)

RegisterNetEvent('qw-crypto-mining:server:purchaseRig', function() 
    local src = source
    local citizenId = server.GetIdentifier(src)

    if PlayerCryptoCache[citizenId] ~= nil then
        if Config.Debug then print('Using cached data for ' .. citizenId) end
        TriggerClientEvent('QBCore:Notify', src, 'You already have a mining rig!', 'error')
        return
    else
        local playerCryptoData = MySQL.query.await('SELECT * FROM player_crypto_mining WHERE citizenid = @citizenid', { ['@citizenid'] = citizenId })

        if playerCryptoData[1] and playerCryptoData ~= "[]" then
            if Config.Debug then print('Using database data for ' .. citizenId) end
            cryptoData = playerCryptoData[1]
            PlayerCryptoCache[citizenId] = cryptoData
            TriggerClientEvent('QBCore:Notify', src, 'You already have a mining rig!', 'error')
        else
            if server.RemoveMoney(src, 'bank', Config.BuyPrice, 'purchase-crypto-rig') then -- REMINDER: BANK LETS YOU GO NEGATIVE
                local temp = {}

                for k, v in pairs(Config.CryptoUpgrades) do
                    temp[k] = 1
                end

                MySQL.query.await('INSERT INTO `player_crypto_mining` (`citizenid`, `rigdata`) VALUES (?, ?)', { citizenId, json.encode(temp) })
            else
                TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money to purchase a Rig right now!', 'error')
            end
        end
    end
end)

RegisterNetEvent('qw-crypto-mining:server:upgradeComponent', function(component, componentIndex) 
    local src = source
    local Player = server.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = server.GetIdentifier(src)

    if not Config.UsingOxLib then
        UpgradeComponent(component.choosenComponent, component.choosenIndex, citizenId, src)
    else
        UpgradeComponent(component, componentIndex, citizenId, src)
    end
end)

RegisterNetEvent('qw-crypto-mining:server:stopRig', function() 
    local src = source
    local Player = server.GetPlayer(src)
    
    if not Player then return end

    local citizenId = server.GetIdentifier(src)

    PlayerCryptoCache[citizenId] = nil

    TriggerClientEvent('QBCore:Notify', src, 'You have stopped your mining rig!', 'success')
end)

RegisterNetEvent('qw-crypto-mining:server:sellRig', function() 
    local src = source
    local Player = server.GetPlayer(src)
    
    if not Player then return end
    
    local citizenId = server.GetIdentifier(src)

    local currentRigData = json.decode(PlayerCryptoCache[citizenId].rigdata)

    local totalValue = 0

    for k, v in pairs(currentRigData) do
        totalValue = totalValue + Config.CryptoUpgrades[k][v].sellPrice
    end

    server.AddMoney(src, 'bank', totalValue, 'sold-crypto-rig')

    MySQL.query.await('DELETE FROM `player_crypto_mining` WHERE citizenid = @citizenid', {['@citizenid'] = citizenId})

    PlayerCryptoCache[citizenId] = nil

    TriggerClientEvent('QBCore:Notify', src, 'You have sold your mining rig for $' .. totalValue, 'success')
end)

RegisterNetEvent('qw-crypto-mining:server:removeFromCache', function(citizenId)
    if PlayerCryptoCache[citizenId] ~= nil then

        PlayerCryptoCache[citizenId] = nil

        if Config.Debug then print('Removing ' .. citizenId .. ' from cache') end
    else
        if Config.Debug then print('No data found for ' .. citizenId) end
    end
end)

-- Functions

function UpgradeComponent(component, componentIndex, citizenId, src)
    local currentRigData = json.decode(PlayerCryptoCache[citizenId].rigdata)

    currentRigData[component] = componentIndex
    PlayerCryptoCache[citizenId].rigdata = json.encode(currentRigData)
    
    if Config.Debug then print('Updating cache for player ' .. citizenId) end

    if server.RemoveMoney(src, 'bank', Config.CryptoUpgrades[component][componentIndex].price, 'purchase-crypto-upgrade') then
        MySQL.query.await('UPDATE `player_crypto_mining` SET `rigdata` = @rigdata WHERE citizenid = @citizenid', {['@rigdata'] = json.encode(currentRigData), ['@citizenid'] = citizenId})

        TriggerClientEvent('QBCore:Notify', src, 'You have upgraded your ' .. component .. ' to level ' .. componentIndex, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money to purchase that upgrade!', 'error')
    end
end

function Payout()
    local totalPayout = 0

    for k, v in pairs(PlayerCryptoCache) do
        local currentRigData = json.decode(v.rigdata)
        local totalValue = 0

        for k2, v2 in pairs(currentRigData) do
            totalValue = totalValue + Config.CryptoUpgrades[k2][v2].hashRate * Config.HashRateMultiplier
        end

        totalPayout = totalPayout + totalValue

        local Player = server.GetPlayerByCitizenId(k)
        local src

        -- since esx doesn't have crypto as account money we put here at bank
        if server.Framework == 'esx' then 
            src = Player.source
            server.AddMoney(src, 'bank', totalValue, 'crypto-payout')
        end
        if server.Framework == 'qb' then 
            src = Player.PlayerData.source
            server.AddMoney(src, 'crypto', totalValue, 'crypto-payout')
        end

        TriggerClientEvent('QBCore:Notify', src, 'You have mined '..totalPayout..' crypto while running your Rig', 'primary')
    end
end

function ChargeForPower()

    local totalAmountToCharge = 0

    for k, v in pairs(PlayerCryptoCache) do
        local currentRigData = json.decode(v.rigdata)
        local totalValue = 0

        for k2, v2 in pairs(currentRigData) do
            totalValue = totalValue + (Config.CryptoUpgrades[k2][v2].powerUsage * Config.PowerUsageMultiplier) * Config.PowerUsageBasePrice
        end

        totalAmountToCharge = totalAmountToCharge + totalValue

        local Player = QBCore.Functions.GetPlayerByCitizenId(k)

        local Player = server.GetPlayerByCitizenId(k)
        local src

        if server.Framework == 'esx' then 
            src = Player.source
            if server.RemoveMoney(src, 'bank', totalAmountToCharge, 'crypto-power-costs') then
                TriggerClientEvent('QBCore:Notify', src, 'You were charged $'..totalAmountToCharge..' for your mining equipment', 'primary')
            else
                TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money to pay for your mining equipment! We are turning your rig off now!', 'error')
                PlayerCryptoCache[k] = nil
            end
        end
        if server.Framework == 'qb' then 
            src = Player.PlayerData.source
            if server.RemoveMoney(src, 'bank', totalAmountToCharge, 'crypto-power-costs') then
                TriggerClientEvent('QBCore:Notify', src, 'You were charged $'..totalAmountToCharge..' for your mining equipment', 'primary')
            else
                TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money to pay for your mining equipment! We are turning your rig off now!', 'error')
                PlayerCryptoCache[k] = nil
            end
        end
    end

end

RegisterNetEvent("qw-crypto-mining:server:startPayoutClock", function()
    if Config.Debug then print('Starting payout clock') end
    CreateThread(function()
        while true do
            Citizen.Wait(Config.MiningInterval * 1000)
            Payout()
        end
    end)
end)

RegisterNetEvent("qw-crypto-mining:server:startPowerUsageClock", function()
    if Config.Debug then print('Starting power usage clock') end
    CreateThread(function()
        while true do
            Citizen.Wait(Config.PowerUsageInterval * 1000)
            ChargeForPower()
        end
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local citizenId = server.GetIdentifier(src)

    TriggerEvent('qw-crypto-mining:server:removeFromCache', citizenId)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if cache.resource == resourceName then
        TriggerEvent('qw-crypto-mining:server:startPayoutClock')
        TriggerEvent('qw-crypto-mining:server:startPowerUsageClock')
    end
end)
