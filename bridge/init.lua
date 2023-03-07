shared = {}

if GetResourceState('es_extended'):find('start') then
    shared.Framework = 'esx'
end

if GetResourceState('qb-core'):find('start') then
    shared.Framework = 'qb'
end 