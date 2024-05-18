function LoadInventory(source, citizenid)
    local inventory = MySQL.prepare.await('SELECT inventory FROM players WHERE citizenid = ?', { citizenid })
    local loadedInventory = {}
    local missingItems = {}
    inventory = json.decode(inventory)
    if not inventory or not next(inventory) then return loadedInventory end

    for _, item in pairs(inventory) do
        if item then
            local itemInfo = QBCore.Shared.Items[item.name:lower()]

            if itemInfo then
                loadedInventory[item.slot] = {
                    name = itemInfo['name'],
                    amount = item.amount,
                    info = item.info or '',
                    label = itemInfo['label'],
                    description = itemInfo['description'] or '',
                    weight = itemInfo['weight'],
                    type = itemInfo['type'],
                    unique = itemInfo['unique'],
                    useable = itemInfo['useable'],
                    image = itemInfo['image'],
                    shouldClose = itemInfo['shouldClose'],
                    slot = item.slot,
                    combinable = itemInfo['combinable']
                }
            else
                missingItems[#missingItems + 1] = item.name:lower()
            end
        end
    end

    if #missingItems > 0 then
        print(('The following items were removed for player %s as they no longer exist'):format(GetPlayerName(source)))
    end

    return loadedInventory
end

exports('LoadInventory', LoadInventory)

function SaveInventory(source, offline)
    local PlayerData
    if offline then
        PlayerData = source
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return end
        PlayerData = Player.PlayerData
    end

    local items = PlayerData.items
    local ItemsJson = {}

    if items and next(items) then
        for slot, item in pairs(items) do
            if item then
                ItemsJson[#ItemsJson + 1] = {
                    name = item.name,
                    amount = item.amount,
                    info = item.info,
                    type = item.type,
                    slot = slot,
                }
            end
        end
        MySQL.prepare('UPDATE players SET inventory = ? WHERE citizenid = ?', { json.encode(ItemsJson), PlayerData.citizenid })
    else
        MySQL.prepare('UPDATE players SET inventory = ? WHERE citizenid = ?', { '[]', PlayerData.citizenid })
    end
end

exports('SaveInventory', SaveInventory)

function GetTotalWeight(items)
    if not items then return 0 end

    local weight = 0
    for _, item in pairs(items) do
        weight = weight + (item.weight * item.amount)
    end

    return tonumber(weight)
end

exports('GetTotalWeight', GetTotalWeight)

function GetSlotsByItem(items, itemName)
    local slotsFound = {}

    if not items then return slotsFound end

    for slot, item in pairs(items) do
        if item.name:lower() == itemName:lower() then
            slotsFound[#slotsFound + 1] = slot
        end
    end

    return slotsFound
end

exports('GetSlotsByItem', GetSlotsByItem)

function GetFirstSlotByItem(items, itemName)
    if not items then return nil end

    for slot, item in pairs(items) do
        if item.name:lower() == itemName:lower() then
            return tonumber(slot)
        end
    end

    return nil
end

exports('GetFirstSlotByItem', GetFirstSlotByItem)

function GetItemBySlot(source, slot)
    return QBCore.Functions.GetPlayer(source).PlayerData.items[tonumber(slot)]
end

exports('GetItemBySlot', GetItemBySlot)

local function GetFirstFreeSlot(items, maxSlots)
    for i = 1, maxSlots do
        if items[i] == nil then
            return i
        end
    end
    return nil
end

exports('GetFirstFreeSlot', GetFirstFreeSlot)

function GetItemByName(source, item)
    local PlayerItems = QBCore.Functions.GetPlayer(source).PlayerData.items
    local slot = GetFirstSlotByItem(PlayerItems, tostring(item):lower())
    return PlayerItems[slot]
end

exports('GetItemByName', GetItemByName)

function GetItemsByName(source, item)
    local PlayerItems = QBCore.Functions.GetPlayer(source).PlayerData.items
    item = tostring(item):lower()
    local items = {}

    for _, slot in pairs(GetSlotsByItem(PlayerItems, item)) do
        if slot then
            items[#items + 1] = PlayerItems[slot]
        end
    end

    return items
end

exports('GetItemsByName', GetItemsByName)

function CanAddItem(source, item, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local itemData = QBCore.Shared.Items[item:lower()]
    if not itemData then return false end

    local weight = itemData.weight * amount
    local totalWeight = GetTotalWeight(Player.PlayerData.items) + weight

    if totalWeight > Config.MaxWeight then
        return false, 'weight'
    end

    local slotsUsed = 0
    for _, v in pairs(Player.PlayerData.items) do
        if v then
            slotsUsed = slotsUsed + 1
        end
    end

    if slotsUsed >= Config.MaxSlots then
        return false, 'slots'
    end

    return true
end

exports('CanAddItem', CanAddItem)

function ClearInventory(source, filterItems)
    local Player = QBCore.Functions.GetPlayer(source)
    local savedItemData = {}

    if filterItems then
        if type(filterItems) == 'string' then
            local item = GetItemByName(source, filterItems)
            if item then savedItemData[item.slot] = item end
        elseif type(filterItems) == 'table' then
            for _, itemName in ipairs(filterItems) do
                local item = GetItemByName(source, itemName)
                if item then savedItemData[item.slot] = item end
            end
        end
    end

    Player.Functions.SetPlayerData('items', savedItemData)

    if not Player.Offline then
        local logMessage = string.format('**%s (citizenid: %s | id: %s)** inventory cleared', GetPlayerName(source), Player.PlayerData.citizenid, source)
        TriggerEvent('qb-log:server:CreateLog', 'playerinventory', 'ClearInventory', 'red', logMessage)
        TriggerClientEvent('qb-inventory:client:updateInventory', source, savedItemData)
    end
end

exports('ClearInventory', ClearInventory)

function SetInventory(source, items)
    local Player = QBCore.Functions.GetPlayer(source)

    Player.Functions.SetPlayerData('items', items)

    if not Player.Offline then
        local logMessage = string.format('**%s (citizenid: %s | id: %s)** items set: %s', GetPlayerName(source), Player.PlayerData.citizenid, source, json.encode(items))
        TriggerEvent('qb-log:server:CreateLog', 'playerinventory', 'SetInventory', 'blue', logMessage)
    end
end

exports('SetInventory', SetInventory)

function SetItemData(source, itemName, key, val)
    if not itemName or not key then return false end

    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local item = GetItemByName(source, itemName)
    if not item then return false end

    item[key] = val
    Player.PlayerData.items[item.slot] = item
    Player.Functions.SetPlayerData('items', Player.PlayerData.items)

    return true
end

exports('SetItemData', SetItemData)

function HasItem(source, items, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local isTable = type(items) == 'table'
    local isArray = isTable and table.type(items) == 'array'
    local totalItems = isArray and #items or 0
    local count = 0
    local kvIndex = isArray and 2 or 1

    if isTable and not isArray then
        for _ in pairs(items) do totalItems = totalItems + 1 end
    end

    if isTable then
        for k, v in pairs(items) do
            local itemKV = { k, v }
            local item = GetItemByName(source, itemKV[kvIndex])
            local validAmount = isArray and (not amount or item.amount >= amount) or (item.amount >= v)

            if item and validAmount then
                count = count + 1
            end
        end
        return count == totalItems
    else
        local item = GetItemByName(source, items)
        return item and (not amount or item.amount >= amount)
    end
end

exports('HasItem', HasItem)

function CreateUsableItem(itemName, data)
    QBCore.Functions.CreateUseableItem(itemName, data)
end

exports('CreateUsableItem', CreateUsableItem)

function GetUsableItem(itemName)
    return QBCore.Functions.CanUseItem(itemName)
end

exports('GetUsableItem', GetUsableItem)

function UseItem(itemName, ...)
    local itemData = GetUsableItem(itemName)
    local callback = type(itemData) == 'table' and (rawget(itemData, '__cfx_functionReference') and itemData or itemData.cb or itemData.callback) or type(itemData) == 'function' and itemData
    if not callback then return end
    callback(...)
end

exports('UseItem', UseItem)

function CloseInventory(source, identifier)
    if identifier and Inventories[identifier] then
        Inventories[identifier].isOpen = false
    end
    Player(source).state.inv_busy = false
    TriggerClientEvent('qb-inventory:client:closeInv', source)
end

exports('CloseInventory', CloseInventory)

function OpenInventoryById(source, targetId)
    local Player = QBCore.Functions.GetPlayer(source)
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not Player or not TargetPlayer then return end
    local playerItems = Player.PlayerData.items
    local targetItems = TargetPlayer.PlayerData.items
    local formattedInventory = {
        name = 'otherplayer-' .. targetId,
        label = GetPlayerName(targetId),
        maxweight = Config.MaxWeight,
        slots = Config.MaxSlots,
        inventory = targetItems
    }
    TriggerClientEvent('qb-inventory:client:openInventory', source, playerItems, formattedInventory)
end

exports('OpenInventoryById', OpenInventoryById)

local function SetupShopItems(shopItems)
    local items = {}
    local slot = 1
    if shopItems and next(shopItems) then
        for _, item in pairs(shopItems) do
            local itemInfo = QBCore.Shared.Items[item.name:lower()]
            if itemInfo then
                items[slot] = {
                    name = itemInfo['name'],
                    amount = tonumber(item.amount),
                    info = item.info or {},
                    label = itemInfo['label'],
                    description = itemInfo['description'] or '',
                    weight = itemInfo['weight'],
                    type = itemInfo['type'],
                    unique = itemInfo['unique'],
                    useable = itemInfo['useable'],
                    price = item.price,
                    image = itemInfo['image'],
                    slot = slot,
                }
                slot = slot + 1
            end
        end
    end
    return items
end

function CreateShop(shopData)
    if shopData.name then
        RegisteredShops[shopData.name] = {
            name = shopData.name,
            label = shopData.label,
            coords = shopData.coords,
            slots = #shopData.items,
            items = SetupShopItems(shopData.items)
        }
    else
        for key, data in pairs(shopData) do
            if type(data) == 'table' then
                if data.name then
                    local shopName = type(key) == 'number' and data.name or key
                    RegisteredShops[shopName] = {
                        name = shopName,
                        label = data.label,
                        coords = data.coords,
                        slots = #data.items,
                        items = SetupShopItems(data.items)
                    }
                else
                    CreateShop(data)
                end
            end
        end
    end
end

exports('CreateShop', CreateShop)

function OpenShop(source, name)
    local src = source
    if not name then return end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not RegisteredShops[name] then return end
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    if RegisteredShops[name].coords then
        local shopDistance = vector3(RegisteredShops[name].coords.x, RegisteredShops[name].coords.y, RegisteredShops[name].coords.z)
        if shopDistance then
            local distance = #(playerCoords - shopDistance)
            if distance > 5.0 then return end
        end
    end
    local formattedInventory = {
        name = 'shop-' .. RegisteredShops[name].name,
        label = RegisteredShops[name].label,
        maxweight = 5000000,
        slots = #RegisteredShops[name].items,
        inventory = RegisteredShops[name].items
    }
    TriggerClientEvent('qb-inventory:client:openInventory', source, Player.PlayerData.items, formattedInventory)
end

exports('OpenShop', OpenShop)

local function InitializeInventory(inventoryId, data)
    Inventories[inventoryId] = {
        items = {},
        isOpen = false,
        maxweight = data and data.maxweight or Config.MaxWeight,
        slots = data and data.slots or Config.MaxSlots
    }
    return Inventories[inventoryId]
end

function OpenInventory(source, identifier, data)
    if Player(source).state.inv_busy then return end
    local QBPlayer = QBCore.Functions.GetPlayer(source)
    if not QBPlayer then return end

    if not identifier then
        Player(source).state.inv_busy = true
        TriggerClientEvent('qb-inventory:client:openInventory', source, QBPlayer.PlayerData.items)
        return
    end

    if type(identifier) ~= 'string' then
        print('Inventory tried to open an invalid identifier')
        return
    end

    local inventory = Inventories[identifier]

    if inventory and inventory.isOpen then
        QBCore.Functions.Notify(source, 'This inventory is currently in use.', 'error')
        return
    end

    if not inventory then inventory = InitializeInventory(identifier, data) end
    inventory.maxweight = (inventory and inventory.maxweight) or (data and data.maxweight) or Config.MaxWeight
    inventory.slots = (inventory and inventory.slots) or data and data.slots or Config.MaxSlots
    inventory.isOpen = true

    local formattedInventory = {
        name = identifier,
        label = identifier,
        maxweight = inventory.maxweight,
        slots = inventory.slots,
        inventory = inventory.items
    }
    TriggerClientEvent('qb-inventory:client:openInventory', source, QBPlayer.PlayerData.items, formattedInventory)
end

exports('OpenInventory', OpenInventory)

function AddItem(identifier, item, amount, slot, info, reason)
    local inventory, inventoryWeight
    local player = QBCore.Functions.GetPlayer(identifier)

    if player then
        inventory = player.PlayerData.items
    elseif Inventories[identifier] then
        inventory = Inventories[identifier].items
        inventoryWeight = Inventories[identifier].maxweight
    elseif Drops[identifier] then
        inventory = Drops[identifier].items
        inventoryWeight = Drops[identifier].maxweight
    end

    if not inventory then
        print('Inventory not found')
        return false
    end

    local itemInfo = QBCore.Shared.Items[item:lower()]
    if not itemInfo then
        print('Item does not exist')
        return false
    end

    local totalWeight = GetTotalWeight(inventory)
    local maxWeight = player and Config.MaxWeight or inventoryWeight
    if totalWeight + (itemInfo.weight * amount) > maxWeight then
        print('Not enough space in inventory')
        return false
    end

    amount = tonumber(amount) or 1
    local updated = false

    if not itemInfo.unique then
        slot = slot or GetFirstSlotByItem(inventory, item)
        if slot then
            for _, invItem in pairs(inventory) do
                if invItem.slot == slot then
                    invItem.amount = invItem.amount + amount
                    updated = true
                    break
                end
            end
        end
    end

    if not updated then
        slot = slot or GetFirstFreeSlot(inventory, Config.MaxSlots)
        if not slot then
            print('No free slot available')
            return false
        end

        inventory[slot] = {
            name = item,
            amount = amount,
            info = info or {},
            label = itemInfo.label,
            description = itemInfo.description or '',
            weight = itemInfo.weight,
            type = itemInfo.type,
            unique = itemInfo.unique,
            useable = itemInfo.useable,
            image = itemInfo.image,
            shouldClose = itemInfo.shouldClose,
            slot = slot,
            combinable = itemInfo.combinable
        }

        if QBCore.Shared.SplitStr(item, '_')[1] == 'weapon' then
            if not inventory[slot].info.serie then
                inventory[slot].info.serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
            end
            if not inventory[slot].info.quality then
                inventory[slot].info.quality = 100
            end
        end
    end

    if player then
        player.Functions.SetPlayerData('items', inventory)
        -- if Player(identifier).state.inv_busy then
        --     local updatedItems = QBCore.Functions.GetPlayer(identifier).PlayerData.items
        --     TriggerClientEvent('qb-inventory:client:updateInventory', identifier, updatedItems)
        -- end
    end
    local invName = player and GetPlayerName(identifier) .. ' (' .. identifier .. ')' or identifier
    local addReason = reason or 'No reason specified'
    local resourceName = GetInvokingResource() or 'qb-inventory'
    TriggerEvent(
        'qb-log:server:CreateLog',
        'playerinventory',
        'Item Added',
        'green',
        '**Inventory:** ' .. invName .. ' (Slot: ' .. slot .. ')\n' ..
        '**Item:** ' .. item .. '\n' ..
        '**Amount:** ' .. amount .. '\n' ..
        '**Reason:** ' .. addReason .. '\n' ..
        '**Resource:** ' .. resourceName
    )
    return true
end

exports('AddItem', AddItem)

function RemoveItem(identifier, item, amount, slot, reason)
    local inventory
    local player = QBCore.Functions.GetPlayer(identifier)

    if player then
        inventory = player.PlayerData.items
    elseif Inventories[identifier] then
        inventory = Inventories[identifier].items
    elseif Drops[identifier] then
        inventory = Drops[identifier].items
    end

    if not inventory then
        print('Inventory not found')
        return false
    end

    slot = tonumber(slot) or GetFirstSlotByItem(inventory, item)

    if not slot then
        print('Item not found in inventory')
        return false
    end

    local inventoryItem = inventory[slot]
    if not inventoryItem or inventoryItem.name:lower() ~= item:lower() then
        print('Item not found in the specified slot')
        return false
    end

    amount = tonumber(amount)
    if inventoryItem.amount < amount then
        print('Not enough quantity to remove')
        return false
    end

    inventoryItem.amount = inventoryItem.amount - amount
    if inventoryItem.amount <= 0 then
        inventory[slot] = nil
    end

    if player then
        player.Functions.SetPlayerData('items', inventory)
        -- if Player(identifier).state.inv_busy then
        --     local updatedItems = QBCore.Functions.GetPlayer(identifier).PlayerData.items
        --     TriggerClientEvent('qb-inventory:client:updateInventory', identifier, updatedItems)
        -- end
    end
    local invName = player and GetPlayerName(identifier) .. ' (' .. identifier .. ')' or identifier
    local removeReason = reason or 'No reason specified'
    local resourceName = GetInvokingResource() or 'qb-inventory'
    TriggerEvent(
        'qb-log:server:CreateLog',
        'playerinventory',
        'Item Removed',
        'red',
        '**Inventory:** ' .. invName .. ' (Slot: ' .. slot .. ')\n' ..
        '**Item:** ' .. item .. '\n' ..
        '**Amount:** ' .. amount .. '\n' ..
        '**Reason:** ' .. removeReason .. '\n' ..
        '**Resource:** ' .. resourceName
    )
    return true
end

exports('RemoveItem', RemoveItem)
