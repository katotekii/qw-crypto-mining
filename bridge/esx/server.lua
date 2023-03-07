if GetResourceState('es_extended') ~= 'started' then return end

server = {}
server.Framework = 'esx'
local ESX = exports['es_extended']:getSharedObject()


function server.GetPlayer(src)
    if src then
        return ESX.GetPlayerFromId(src)
    end

    return false -- either notify
end

function server.GetIdentifier(src)
    if src then
        return ESX.GetPlayerFromId(src).identifier
    end

    return false
end


function server.GetPlayerByCitizenId(citizenId)
    if citizenId then
        return ESX.GetPlayerFromIdentifier(citizenId)
    end

    return false
end

-- description does nothing here
function server.AddMoney(src, type, money, description)
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer then
        xPlayer.addAccountMoney(type, money)
    end
end

function server.RemoveMoney(src, type, money, description)
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer then
        xPlayer.removeAccountMoney(type, money)
    end
end