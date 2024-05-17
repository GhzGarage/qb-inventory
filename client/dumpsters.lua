CreateThread(function()
    exports['qb-target']:AddTargetModel(Config.BinObjects, {
        options = {
            {
                type = 'server',
                event = 'qb-inventory:server:openBin',
                icon = 'fa-solid fa-cash-register',
                label = Lang:t('menu.bin'),
            },
        },
        distance = 2.5
    })
end)
