if GetResourceState('es_extended') ~= 'started' then return end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	createMenuZone()
end)