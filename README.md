# qb-inventory

## Dependencies
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [qb-logs](https://github.com/qbcore-framework/qb-logs) - For logging transfer and other history

## Screenshots
![General]()
![ID Card]()
![Weapon]()
![Shop]()
![Glovebox]()
![Trunk]()

## Features
- Stashes (Personal and/or Shared)
- Vehicle Trunk & Glovebox
- Weapon Attachments
- Shops
- Item Drops

## Installation
### Manual
- Download the script and put it in the `[qb]` directory.
- Import `qb-inventory.sql` in your database
- Add the following code to your server.cfg/resouces.cfg

# Migrating from old qb-inventory

## Database
### Upload the new `inventory.sql` file to create the new `inventories` table
### Use the provided `migrate.sql` file to migrate all of your saved inventory data from stashes, trunks, etc
### Once complete, you can delete `gloveboxitems` `stashitems` and `trunkitems` tables from your database

## Opening the inventory
### The event `inventory:server:OpenInventory` has been removed, it will no longer open the inventory
### How to open the inventory (server-side)
```
exports['qb-inventory']:OpenInventory(source) or exports['qb-inventory']:OpenInventory(source, identifier)
```
### Example (server)
```
local ped = GetPlayerPed(source)
local vehicle = GetVehiclePedIsIn(ped, false)
local plate = GetVehicleNumberPlateText(vehicle)
exports['qb-inventory']:OpenInventory(source, 'glovebox-'..plate)
```
### WE WILL NOT BE CREATING A WRAPPER FOR THE OLD EVENT

## Shops
### How to create a shop (example from qb-shops)
### We include coords in our shops because the inventory does distance checks, if you don't need a distance check you can put false or nil
```
CreateThread(function()
    local shopInfo = {}
    for shop, data in pairs(Config.Locations) do
        shopInfo[shop] = {
            name = shop,
            label = data.label,
            coords = data.coords,
            items = data.products,
        }
    end
    exports['qb-inventory']:CreateShop(shopInfo)
end)
```

### How to open a shop (server-side)
```
exports['qb-inventory']:OpenShop(shopName) -- shopName is what's registered when you create the shop above
```

# License

    QBCore Framework
    Copyright (C) 2021 Joshua Eger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>
