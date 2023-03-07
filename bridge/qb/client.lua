if GetResourceState('qb_core') ~= 'started' then return end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createMenuZone()
end)