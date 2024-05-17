QBCore = exports['qb-core']:GetCoreObject()
local hotbarShown = false
local currentWeapon = nil

-- Handlers

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    LocalPlayer.state:set('inv_busy', false, true)
    PlayerData = QBCore.Functions.GetPlayerData()
    GetDrops()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    LocalPlayer.state:set('inv_busy', true, true)
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:UpdateObject', function()
    QBCore = exports['qb-core']:GetCoreObject()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        PlayerData = QBCore.Functions.GetPlayerData()
    end
end)

-- Functions

function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

local function FormatWeaponAttachments(itemdata)
    if not itemdata.info or not itemdata.info.attachments or #itemdata.info.attachments == 0 then
        return {}
    end
    local attachments = {}
    local weaponName = itemdata.name
    local WeaponAttachments = exports['qb-weapons']:getConfigWeaponAttachments()
    if not WeaponAttachments then return {} end
    for attachmentType, weapons in pairs(WeaponAttachments) do
        local componentHash = weapons[weaponName]
        if componentHash then
            for _, attachmentData in pairs(itemdata.info.attachments) do
                if attachmentData.component == componentHash then
                    local label = QBCore.Shared.Items[attachmentType] and QBCore.Shared.Items[attachmentType].label or 'Unknown'
                    attachments[#attachments + 1] = {
                        attachment = attachmentType,
                        label = label
                    }
                end
            end
        end
    end
    return attachments
end

-- Events

RegisterNetEvent('qb-inventory:client:requiredItems', function(items, bool)
    local itemTable = {}
    if bool then
        for k in pairs(items) do
            itemTable[#itemTable + 1] = {
                item = items[k].name,
                label = QBCore.Shared.Items[items[k].name]['label'],
                image = items[k].image,
            }
        end
    end

    SendNUIMessage({
        action = 'requiredItem',
        items = itemTable,
        toggle = bool
    })
end)

RegisterNetEvent('qb-inventory:client:hotbar', function(items)
    hotbarShown = not hotbarShown
    SendNUIMessage({
        action = 'toggleHotbar',
        open = hotbarShown,
        items = items
    })
end)

RegisterNetEvent('qb-inventory:client:closeInv', function()
    SendNUIMessage({
        action = 'close',
    })
end)

RegisterNetEvent('qb-inventory:client:updateInventory', function(items)
    SendNUIMessage({
        action = 'update',
        inventory = items
    })
end)

RegisterNetEvent('qb-inventory:client:ItemBox', function(itemData, type)
    SendNUIMessage({
        action = 'itemBox',
        item = itemData,
        type = type
    })
end)

RegisterNetEvent('qb-inventory:server:RobPlayer', function(TargetId)
    SendNUIMessage({
        action = 'RobMoney',
        TargetId = TargetId,
    })
end)

RegisterNetEvent('qb-inventory:client:openInventory', function(items, other)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        inventory = items,
        slots = Config.MaxSlots,
        maxweight = Config.MaxWeight,
        other = other
    })
end)

RegisterNetEvent('qb-inventory:client:UseWeapon', function(weaponData, shootbool)
    local ped = PlayerPedId()
    local weaponName = tostring(weaponData.name)
    local weaponHash = joaat(weaponData.name)
    if currentWeapon == weaponName then
        TriggerEvent('weapons:client:DrawWeapon', nil)
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        RemoveAllPedWeapons(ped, true)
        TriggerEvent('weapons:client:SetCurrentWeapon', nil, shootbool)
        currentWeapon = nil
    elseif weaponName == 'weapon_stickybomb' or weaponName == 'weapon_pipebomb' or weaponName == 'weapon_smokegrenade' or weaponName == 'weapon_flare' or weaponName == 'weapon_proxmine' or weaponName == 'weapon_ball' or weaponName == 'weapon_molotov' or weaponName == 'weapon_grenade' or weaponName == 'weapon_bzgas' then
        TriggerEvent('weapons:client:DrawWeapon', weaponName)
        GiveWeaponToPed(ped, weaponHash, 1, false, false)
        SetPedAmmo(ped, weaponHash, 1)
        SetCurrentPedWeapon(ped, weaponHash, true)
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)
        currentWeapon = weaponName
    elseif weaponName == 'weapon_snowball' then
        TriggerEvent('weapons:client:DrawWeapon', weaponName)
        GiveWeaponToPed(ped, weaponHash, 10, false, false)
        SetPedAmmo(ped, weaponHash, 10)
        SetCurrentPedWeapon(ped, weaponHash, true)
        TriggerServerEvent('inventory:server:snowball', 'remove')
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)
        currentWeapon = weaponName
    else
        TriggerEvent('weapons:client:DrawWeapon', weaponName)
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)
        local ammo = tonumber(weaponData.info.ammo) or 0

        if weaponName == 'weapon_petrolcan' or weaponName == 'weapon_fireextinguisher' then
            ammo = 4000
        end

        GiveWeaponToPed(ped, weaponHash, ammo, false, false)
        SetPedAmmo(ped, weaponHash, ammo)
        SetCurrentPedWeapon(ped, weaponHash, true)

        if weaponData.info.attachments then
            for _, attachment in pairs(weaponData.info.attachments) do
                GiveWeaponComponentToPed(ped, weaponHash, joaat(attachment.component))
            end
        end

        if weaponData.info.tint then
            SetPedWeaponTintIndex(ped, weaponHash, weaponData.info.tint)
        end

        currentWeapon = weaponName
    end
end)

-- NUI Callbacks

RegisterNUICallback('PlayDropFail', function(_, cb)
    PlaySound(-1, 'Place_Prop_Fail', 'DLC_Dmod_Prop_Editor_Sounds', 0, 0, 1)
    cb('ok')
end)

RegisterNUICallback('AttemptPurchase', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-inventory:server:attemptPurchase', function(canPurchase)
        cb(canPurchase)
    end, data)
end)

RegisterNUICallback('RobMoney', function(data, cb)
    TriggerServerEvent('police:server:RobPlayer', data.TargetId)
    cb('ok')
end)

RegisterNUICallback('CloseInventory', function(data, cb)
    SetNuiFocus(false, false)
    CloseTrunk()
    if data.name then
        TriggerServerEvent('qb-inventory:server:closeInventory', data.name)
    elseif CurrentDrop then
        TriggerServerEvent('qb-inventory:server:closeInventory', CurrentDrop)
        CurrentDrop = nil
    end
    cb('ok')
end)

RegisterNUICallback('UseItem', function(data, cb)
    TriggerServerEvent('qb-inventory:server:useItem', data.item)
    cb('ok')
end)

RegisterNUICallback('SetInventoryData', function(data, cb)
    TriggerServerEvent('qb-inventory:server:SetInventoryData', data.fromInventory, data.toInventory, data.fromSlot, data.toSlot, data.fromAmount, data.toAmount)
    cb('ok')
end)

RegisterNUICallback('GiveItem', function(data, cb)
    local player, distance = QBCore.Functions.GetClosestPlayer(GetEntityCoords(PlayerPedId()))
    if player ~= -1 and distance < 3 then
        local playerId = GetPlayerServerId(player)
        QBCore.Functions.TriggerCallback('qb-inventory:server:giveItem', function(success)
            cb(success)
        end, playerId, data.item.name)
    else
        QBCore.Functions.Notify(Lang:t('notify.nonb'), 'error')
        cb(false)
    end
end)

RegisterNUICallback('GetWeaponData', function(cData, cb)
    local data = {
        WeaponData = QBCore.Shared.Items[cData.weapon],
        AttachmentData = FormatWeaponAttachments(cData.ItemData)
    }
    cb(data)
end)

RegisterNUICallback('RemoveAttachment', function(data, cb)
    local ped = PlayerPedId()
    local WeaponData = data.WeaponData
    local allAttachments = exports['qb-weapons']:getConfigWeaponAttachments()
    local Attachment = allAttachments[data.AttachmentData.attachment][WeaponData.name]

    QBCore.Functions.TriggerCallback('weapons:server:RemoveAttachment', function(NewAttachments)
        if NewAttachments ~= false then
            local Attachies = {}
            RemoveWeaponComponentFromPed(ped, joaat(WeaponData.name), joaat(Attachment))

            for _, v in pairs(NewAttachments) do
                for attachmentType, weapons in pairs(allAttachments) do
                    local componentHash = weapons[WeaponData.name]
                    if componentHash and v.component == componentHash then
                        local label = QBCore.Shared.Items[attachmentType] and QBCore.Shared.Items[attachmentType].label or 'Unknown'
                        Attachies[#Attachies + 1] = {
                            attachment = attachmentType,
                            label = label,
                        }
                    end
                end
            end
            local DJATA = {
                Attachments = Attachies,
                WeaponData = WeaponData,
            }
            cb(DJATA)
        else
            RemoveWeaponComponentFromPed(ped, joaat(WeaponData.name), joaat(Attachment))
            cb({})
        end
    end, data.AttachmentData, WeaponData)
end)

-- Commands

RegisterCommand('openInv', function()
    ExecuteCommand('inventory')
end, false)

RegisterCommand('toggleHotbar', function()
    ExecuteCommand('hotbar')
end, false)

for i = 1, 5 do
    RegisterCommand('slot_' .. i, function()
        local itemData = PlayerData.items[i]
        if not itemData then return end
        TriggerServerEvent('qb-inventory:server:useItem', itemData)
    end, false)
    RegisterKeyMapping('slot_' .. i, Lang:t('inf_mapping.use_item') .. i, 'keyboard', i)
end

RegisterKeyMapping('openInv', Lang:t('inf_mapping.opn_inv'), 'keyboard', Config.Keybinds.Open)
RegisterKeyMapping('toggleHotbar', Lang:t('inf_mapping.tog_slots'), 'keyboard', Config.Keybinds.Hotbar)
