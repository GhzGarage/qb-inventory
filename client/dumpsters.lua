CreateThread(function()
    exports['qb-target']:AddTargetModel(Config.BinObjects, {
        options = {
            {
                icon = 'fa-solid fa-cash-register',
                label = Lang:t('menu.bin'),
                action = function(entity)
                    local netId = NetworkGetNetworkIdFromEntity(entity)
                    TriggerServerEvent('qb-inventory:server:openBin', netId)
                end
            },
        },
        distance = 2.5
    })
end)
