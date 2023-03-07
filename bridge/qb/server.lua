if GetResourceState('qb_core') ~= 'started' then return end

server = {}
server.Framework = 'qb'
local QBCore = exports.qb_core:GetCoreObject()


function server.GetPlayer(src)
    if src then
        return QBCore.Functions.GetPlayer(src)
    end

    return false -- either notify
end

function server.GetIdentifier(src)
    if src then
        return QBCore.Functions.GetPlayer(src).PlayerData.citizenid
    end

    return false
end

function server.GetPlayerByCitizenId(citizenId)
    if citizenId then
        return QBCore.Functions.GetPlayerByCitizenId(citizenId)
    end

    return false
end

function server.AddMoney(src, type, money, description)
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        Player.Functions.AddMoney(type, money, description)
    end
end

function server.RemoveMoney(src, type, money, description)
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        Player.Functions.RemoveMoney(type, money, description)
    end
end