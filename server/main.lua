-- Commands

QBCore.Commands.Add('giveitem', 'Give An Item (Admin Only)', { { name = 'id', help = 'Player ID' }, { name = 'item', help = 'Name of the item (not a label)' }, { name = 'amount', help = 'Amount of items' } }, false, function(source, args)
    local id = tonumber(args[1])
    local Player = QBCore.Functions.GetPlayer(id)
    local amount = tonumber(args[3]) or 1
    local itemData = QBCore.Shared.Items[tostring(args[2]):lower()]
    if Player then
        if itemData then
            -- check iteminfo
            local info = {}
            if itemData['name'] == 'id_card' then
                info.citizenid = Player.PlayerData.citizenid
                info.firstname = Player.PlayerData.charinfo.firstname
                info.lastname = Player.PlayerData.charinfo.lastname
                info.birthdate = Player.PlayerData.charinfo.birthdate
                info.gender = Player.PlayerData.charinfo.gender
                info.nationality = Player.PlayerData.charinfo.nationality
            elseif itemData['name'] == 'driver_license' then
                info.firstname = Player.PlayerData.charinfo.firstname
                info.lastname = Player.PlayerData.charinfo.lastname
                info.birthdate = Player.PlayerData.charinfo.birthdate
                info.type = 'Class C Driver License'
            elseif itemData['type'] == 'weapon' then
                amount = 1
                info.serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
                info.quality = 100
            elseif itemData['name'] == 'harness' then
                info.uses = 20
            elseif itemData['name'] == 'markedbills' then
                info.worth = math.random(5000, 10000)
            elseif itemData['name'] == 'labkey' then
                info.lab = exports['qb-methlab']:GenerateRandomLab()
            elseif itemData['name'] == 'printerdocument' then
                info.url = 'https://cdn.discordapp.com/attachments/870094209783308299/870104331142189126/Logo_-_Display_Picture_-_Stylized_-_Red.png'
            end

            if AddItem(id, itemData['name'], amount, false, info) then
                QBCore.Functions.Notify(source, Lang:t('notify.yhg') .. GetPlayerName(id) .. ' ' .. amount .. ' ' .. itemData['name'] .. '', 'success')
            else
                QBCore.Functions.Notify(source, Lang:t('notify.cgitem'), 'error')
            end
        else
            QBCore.Functions.Notify(source, Lang:t('notify.idne'), 'error')
        end
    else
        QBCore.Functions.Notify(source, Lang:t('notify.pdne'), 'error')
    end
end, 'admin')

RegisterCommand('randomitems', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    local playerInventory = Player.PlayerData.items
    local filteredItems = {}
    for k, v in pairs(QBCore.Shared.Items) do
        if QBCore.Shared.Items[k]['type'] ~= 'weapon' then
            filteredItems[#filteredItems + 1] = v
        end
    end
    for _ = 1, 10, 1 do
        local randitem = filteredItems[math.random(1, #filteredItems)]
        local amount = math.random(1, 10)
        if randitem['unique'] then
            amount = 1
        end
        local emptySlot = nil
        for i = 1, Config.MaxSlots do
            if not playerInventory[i] then
                emptySlot = i
                break
            end
        end
        if emptySlot then
            if AddItem(source, randitem.name, amount, emptySlot) then
                TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items[randitem.name], 'add')
                Player = QBCore.Functions.GetPlayer(source)
                playerInventory = Player.PlayerData.items
            end
            Wait(1000)
        end
    end
end, false)

RegisterCommand('clearinv', function(source)
    ClearInventory(source)
end, false)

RegisterCommand('closeInv', function(source)
    CloseInventory(source)
end, false)

RegisterCommand('hotbar', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player(source).state.inv_busy then return end
    if not Player or Player.PlayerData.metadata['isdead'] or Player.PlayerData.metadata['inlaststand'] or Player.PlayerData.metadata['ishandcuffed'] then return end
    local hotbarItems = {
        Player.PlayerData.items[1],
        Player.PlayerData.items[2],
        Player.PlayerData.items[3],
        Player.PlayerData.items[4],
        Player.PlayerData.items[5],
    }
    TriggerClientEvent('qb-inventory:client:hotbar', source, hotbarItems)
end, false)

RegisterCommand('inventory', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player(source).state.inv_busy then return end
    if not Player or Player.PlayerData.metadata['isdead'] or Player.PlayerData.metadata['inlaststand'] or Player.PlayerData.metadata['ishandcuffed'] then return end
    local inVehicle = GetVehiclePedIsIn(GetPlayerPed(source), false)
    if inVehicle ~= 0 then
        local plate = GetVehicleNumberPlateText(inVehicle)
        OpenInventory(source, 'glovebox-' .. plate)
        return
    end
    QBCore.Functions.TriggerClientCallback('qb-inventory:client:vehicleCheck', source, function(netId, class)
        if netId then
            local vehicle = NetworkGetEntityFromNetworkId(netId)
            local plate = GetVehicleNumberPlateText(vehicle)
            OpenInventory(source, 'trunk-' .. plate)
            return
        end
        OpenInventory(source)
    end)
end, false)
