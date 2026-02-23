# Vehicle Shop Menu System Documentation

## Overview
The qb-vehicleshop uses a sophisticated menu system built on top of **qb-menu** and **qb-input** to provide an interactive vehicle shopping experience. This document explains how the menu system works, what code controls it, and how different components interact.

---

## Menu Dependencies

### Required Resources
1. **qb-menu** - Main menu framework for displaying interactive menus
2. **qb-input** - Input dialog framework for collecting user input (player IDs, payment amounts, etc.)
3. **PolyZone** - Zone detection system for triggering menus when players enter specific areas

---

## Menu Architecture

### 1. Menu Types
The system has **two primary shop types**, each with different menu flows:

#### A. Free-Use Shops (`Type: 'free-use'`)
- **No player interaction required** - Players can directly buy vehicles
- Examples: PDM, Boat Shop, Air Shop, Truck Shop
- Features:
  - Test Drive (player can try the vehicle)
  - Buy Vehicle (instant purchase)
  - Finance Vehicle (payment plan)
  - Swap Vehicle (change display vehicle)

#### B. Managed Shops (`Type: 'managed'`)
- **Requires employee interaction** - Real players with specific jobs must sell vehicles
- Example: Luxury Vehicle Shop (requires `cardealer` job)
- Features:
  - Test Drive for Customer (employee selects customer by ID)
  - Sell Vehicle (employee sells to customer by ID)
  - Finance Vehicle (employee finances to customer by ID)
  - Swap Vehicle (change display vehicle)

---

## Menu Control Code

### Static Menu Headers (Lines 61-91 in client.lua)

These are predefined menu structures that never change:

```lua
-- Vehicle interaction header (shown when near a vehicle)
local vehHeaderMenu = {
    {
        header = Lang:t('menus.vehHeader_header'),  -- "Vehicle Options"
        txt = Lang:t('menus.vehHeader_txt'),         -- "Interact with the current vehicle"
        icon = 'fa-solid fa-car',
        params = {
            event = 'qb-vehicleshop:client:showVehOptions'
        }
    }
}

-- Finance menu header (shown at finance zones)
local financeMenu = {
    {
        header = Lang:t('menus.financed_header'),    -- "Financed Vehicles"
        txt = Lang:t('menus.finance_txt'),           -- "Browse your owned vehicles"
        icon = 'fa-solid fa-user-ninja',
        params = {
            event = 'qb-vehicleshop:client:getVehicles'
        }
    }
}

-- Test drive return menu (shown when returning from test drive)
local returnTestDrive = {
    {
        header = Lang:t('menus.returnTestDrive_header'), -- "Finish Test Drive"
        icon = 'fa-solid fa-flag-checkered',
        params = {
            event = 'qb-vehicleshop:client:TestDriveReturn'
        }
    }
}
```

### Dynamic Menu Generation

The main vehicle interaction menu is **dynamically built** based on:
- Current shop type (free-use or managed)
- Closest vehicle to player
- Player's job

---

## How Menus Are Triggered

### Zone-Based Triggers

#### 1. Vehicle Interaction Zones (Lines 199-242)
When `Config.UsingTarget = false`, BoxZones are created around each showroom vehicle:

```lua
local function createVehZones(shopName, entity)
    if not Config.UsingTarget then
        -- Creates BoxZone for each vehicle in the showroom
        for i = 1, #Config.Shops[shopName]['ShowroomVehicles'] do
            zones[#zones + 1] = BoxZone:Create(
                vector3(x, y, z),  -- Vehicle position
                Config.Shops[shopName]['Zone']['size'],  -- Zone size
                Config.Shops[shopName]['Zone']['size'],
                { name = 'box_zone_' .. shopName .. '_' .. i }
            )
        end
        
        -- When player enters zone, show header menu
        combo:onPlayerInOut(function(isPointInside)
            if isPointInside then
                exports['qb-menu']:showHeader(vehHeaderMenu)  -- Shows header
            else
                exports['qb-menu']:closeMenu()  -- Closes menu
            end
        end)
    end
end
```

When `Config.UsingTarget = true`, qb-target is used instead:
```lua
exports['qb-target']:AddTargetEntity(entity, {
    options = {
        {
            type = 'client',
            event = 'qb-vehicleshop:client:showVehOptions',
            icon = 'fas fa-car',
            label = Lang:t('general.vehinteraction'),
        }
    },
    distance = 3.0
})
```

#### 2. Shop Zones (Lines 245-313 and 315-387)

**Free-Use Shop Zones:**
```lua
local function createFreeUseShop(shopShape, name)
    local zone = PolyZone:Create(shopShape, {...})
    
    zone:onPlayerInOut(function(isPointInside)
        if isPointInside then
            insideShop = name  -- Track which shop player is in
            
            -- Continuously update vehicle menu while inside
            CreateThread(function()
                while insideShop do
                    setClosestShowroomVehicle()  -- Find closest vehicle
                    
                    -- Build dynamic menu
                    vehicleMenu = {
                        {
                            isMenuHeader = true,
                            header = getVehBrand() .. ' ' .. getVehName() .. ' - $' .. getVehPrice(),
                        },
                        { -- Test Drive option
                            header = Lang:t('menus.test_header'),
                            params = { event = 'qb-vehicleshop:client:TestDrive' }
                        },
                        { -- Buy option
                            header = Lang:t('menus.freeuse_buy_header'),
                            params = { 
                                isServer = true,
                                event = 'qb-vehicleshop:server:buyShowroomVehicle'
                            }
                        },
                        { -- Finance option
                            header = Lang:t('menus.finance_header'),
                            params = { event = 'qb-vehicleshop:client:openFinance' }
                        },
                        { -- Swap Vehicle option
                            header = Lang:t('menus.swap_header'),
                            params = { event = 'qb-vehicleshop:client:vehCategories' }
                        },
                    }
                    Wait(1000)  -- Update every second
                end
            end)
        end
    end)
end
```

**Managed Shop Zones:**
```lua
local function createManagedShop(shopShape, name)
    -- Similar structure but different menu options
    vehicleMenu = {
        { -- Header showing vehicle info
            isMenuHeader = true,
            header = getVehBrand() .. ' ' .. getVehName() .. ' - $' .. getVehPrice(),
        },
        { -- Test Drive for Customer (requires player ID input)
            header = Lang:t('menus.test_header'),
            params = { 
                event = 'qb-vehicleshop:client:openIdMenu',
                args = { vehicle = ..., type = 'testDrive' }
            }
        },
        { -- Sell to Customer (requires player ID input)
            header = Lang:t('menus.managed_sell_header'),
            params = { 
                event = 'qb-vehicleshop:client:openIdMenu',
                args = { vehicle = ..., type = 'sellVehicle' }
            }
        },
        { -- Finance to Customer (requires player ID and payment info)
            header = Lang:t('menus.finance_header'),
            params = { event = 'qb-vehicleshop:client:openCustomFinance' }
        },
        { -- Swap Vehicle
            header = Lang:t('menus.swap_header'),
            params = { event = 'qb-vehicleshop:client:vehCategories' }
        },
    }
end
```

#### 3. Finance Zone (Lines 389-406)
```lua
local function createFinanceZone(coords, name)
    local financeZone = BoxZone:Create(coords, 2.0, 2.0, {...})
    
    financeZone:onPlayerInOut(function(isPointInside)
        if isPointInside then
            exports['qb-menu']:showHeader(financeMenu)  -- Show finance menu
        else
            exports['qb-menu']:closeMenu()
        end
    end)
end
```

---

## Menu Flow and Events

### Main Menu Opening Events

#### 1. Show Vehicle Options (Line 450-452)
```lua
RegisterNetEvent('qb-vehicleshop:client:showVehOptions', function()
    exports['qb-menu']:openMenu(vehicleMenu, true, true)
end)
```
- **Triggered by:** Player interacting with vehicle (zone or target)
- **Opens:** The dynamically generated `vehicleMenu`

#### 2. Home Menu (Line 445-447)
```lua
RegisterNetEvent('qb-vehicleshop:client:homeMenu', function()
    exports['qb-menu']:openMenu(vehicleMenu)
end)
```
- **Triggered by:** Going back from sub-menus
- **Opens:** Main vehicle menu

---

### Vehicle Selection Flow

When a player wants to swap vehicles, they go through this menu hierarchy:

```
Main Vehicle Menu
    └─> Swap Vehicle (clicked)
         └─> Vehicle Makes (if Config.FilterByMake = true) (Line 645-680)
              └─> Vehicle Categories (Line 537-583)
                   └─> Individual Vehicles (Line 585-643)
                        └─> Server: Swap Vehicle (swaps display)
```

#### A. Vehicle Makes Menu (Optional - if `Config.FilterByMake = true`)
```lua
RegisterNetEvent('qb-vehicleshop:client:vehMakes', function()
    local makeMenu = {
        { header = "Go Back", params = { event = 'qb-vehicleshop:client:homeMenu' } }
    }
    
    -- Build list of all vehicle brands in this shop
    for k, v in pairs(QBCore.Shared.Vehicles) do
        if QBCore.Shared.Vehicles[k]['shop'] == insideShop then
            makeMenu[#makeMenu + 1] = {
                header = v.brand,  -- e.g., "Ferrari", "Lamborghini"
                params = { 
                    event = 'qb-vehicleshop:client:vehCategories',
                    args = { make = v.brand }
                }
            }
        end
    end
    
    exports['qb-menu']:openMenu(makeMenu, Config.SortAlphabetically, true)
end)
```

#### B. Vehicle Categories Menu
```lua
RegisterNetEvent('qb-vehicleshop:client:vehCategories', function(data)
    local categoryMenu = {
        { header = "Go Back", params = { event = 'qb-vehicleshop:client:homeMenu' } }
    }
    
    -- Build list of categories (e.g., "Sports", "SUVs", "Sedans")
    for k, v in pairs(QBCore.Shared.Vehicles) do
        if QBCore.Shared.Vehicles[k]['shop'] == insideShop then
            categoryMenu[#categoryMenu + 1] = {
                header = v.category,  -- e.g., "sports", "suvs"
                params = { 
                    event = 'qb-vehicleshop:client:openVehCats',
                    args = { catName = k }
                }
            }
        end
    end
    
    exports['qb-menu']:openMenu(categoryMenu, Config.SortAlphabetically, true)
end)
```

#### C. Individual Vehicles Menu
```lua
RegisterNetEvent('qb-vehicleshop:client:openVehCats', function(data)
    local vehMenu = {
        { header = "Go Back", params = { event = 'qb-vehicleshop:client:vehCategories' } }
    }
    
    -- List all vehicles in selected category
    for k, v in pairs(QBCore.Shared.Vehicles) do
        if QBCore.Shared.Vehicles[k]['category'] == data.catName then
            vehMenu[#vehMenu + 1] = {
                header = v.name,  -- e.g., "Adder"
                txt = 'Price: $' .. v.price,
                params = {
                    isServer = true,
                    event = 'qb-vehicleshop:server:swapVehicle',
                    args = { toVehicle = v.model }
                }
            }
        end
    end
    
    exports['qb-menu']:openMenu(vehMenu, Config.SortAlphabetically, true)
end)
```

---

## Input Dialogs (qb-input)

Some menu options require additional user input. These use **qb-input** dialogs:

### 1. Finance Payment Input (Line 682-705)
```lua
RegisterNetEvent('qb-vehicleshop:client:openFinance', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = getVehBrand() .. ' ' .. data.buyVehicle .. ' - $' .. data.price,
        submitText = "Submit",
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'downPayment',
                text = 'Down Payment Amount - Min ' .. Config.MinimumDown .. '%'
            },
            {
                type = 'number',
                isRequired = true,
                name = 'paymentAmount',
                text = 'Total Payments - Max ' .. Config.MaximumPayments
            }
        }
    })
    
    if dialog then
        TriggerServerEvent('qb-vehicleshop:server:financeVehicle', 
            dialog.downPayment, dialog.paymentAmount, data.buyVehicle)
    end
end)
```

### 2. Custom Finance Input (Managed Shops) (Line 707-736)
```lua
RegisterNetEvent('qb-vehicleshop:client:openCustomFinance', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = getVehBrand() .. ' ' .. data.vehicle .. ' - $' .. data.price,
        inputs = {
            { type = 'number', name = 'downPayment', text = 'Down Payment...' },
            { type = 'number', name = 'paymentAmount', text = 'Total Payments...' },
            { type = 'number', name = 'playerid', text = 'Server ID (#)' }  -- Employee enters customer ID
        }
    })
    
    if dialog then
        TriggerServerEvent('qb-vehicleshop:server:sellfinanceVehicle', 
            dialog.downPayment, dialog.paymentAmount, data.vehicle, dialog.playerid)
    end
end)
```

### 3. Player ID Input (Managed Shops) (Line 886-907)
```lua
RegisterNetEvent('qb-vehicleshop:client:openIdMenu', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = QBCore.Shared.Vehicles[data.vehicle]['name'],
        inputs = {
            { type = 'number', name = 'playerid', text = 'Server ID (#)' }
        }
    })
    
    if dialog then
        if data.type == 'testDrive' then
            TriggerServerEvent('qb-vehicleshop:server:customTestDrive', 
                data.vehicle, dialog.playerid)
        elseif data.type == 'sellVehicle' then
            TriggerServerEvent('qb-vehicleshop:server:sellShowroomVehicle', 
                data.vehicle, dialog.playerid)
        end
    end
end)
```

### 4. Finance Payment Menu (Paying Off Vehicles) (Line 867-884)
```lua
RegisterNetEvent('qb-vehicleshop:client:financePayment', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = 'Vehicle Payment',
        inputs = {
            { type = 'number', name = 'paymentAmount', text = 'Payment Amount ($)' }
        }
    })
    
    if dialog then
        TriggerServerEvent('qb-vehicleshop:server:financePayment', 
            dialog.paymentAmount, data.vehData)
    end
end)
```

---

## Finance Vehicle Management

### Viewing Financed Vehicles (Line 782-811)
```lua
RegisterNetEvent('qb-vehicleshop:client:getVehicles', function()
    QBCore.Functions.TriggerCallback('qb-vehicleshop:server:getVehicles', function(vehicles)
        local ownedVehicles = {}
        
        -- Build menu of financed vehicles
        for _, v in pairs(vehicles) do
            if v.balance ~= 0 then  -- Only show vehicles with remaining balance
                ownedVehicles[#ownedVehicles + 1] = {
                    header = vehData.name,
                    txt = 'Plate: ' .. v.plate,
                    params = {
                        event = 'qb-vehicleshop:client:getVehicleFinance',
                        args = { vehiclePlate = v.plate, balance = v.balance, ... }
                    }
                }
            end
        end
        
        exports['qb-menu']:openMenu(ownedVehicles)
    end)
end)
```

### Finance Details Menu (Line 813-865)
```lua
RegisterNetEvent('qb-vehicleshop:client:getVehicleFinance', function(data)
    local vehFinance = {
        { header = "Go Back", params = { event = 'qb-vehicleshop:client:getVehicles' } },
        { isMenuHeader = true, header = "Total Balance Remaining", txt = '$' .. data.balance },
        { isMenuHeader = true, header = "Total Payments Remaining", txt = data.paymentsLeft },
        { isMenuHeader = true, header = "Recurring Payment Amount", txt = '$' .. data.paymentAmount },
        {
            header = "Make a payment",
            params = { event = 'qb-vehicleshop:client:financePayment', args = data }
        },
        {
            header = "Payoff vehicle",
            params = { 
                isServer = true,
                event = 'qb-vehicleshop:server:financePaymentFull',
                args = { vehBalance = data.balance, vehPlate = data.vehiclePlate }
            }
        },
    }
    
    exports['qb-menu']:openMenu(vehFinance)
end)
```

---

## Helper Functions

### Getting Current Vehicle Information

These functions retrieve data about the closest showroom vehicle:

```lua
local function getVehName()
    return QBCore.Shared.Vehicles[Config.Shops[insideShop]['ShowroomVehicles'][ClosestVehicle].chosenVehicle]['name']
end

local function getVehPrice()
    return comma_value(QBCore.Shared.Vehicles[Config.Shops[insideShop]['ShowroomVehicles'][ClosestVehicle].chosenVehicle]['price'])
end

local function getVehBrand()
    return QBCore.Shared.Vehicles[Config.Shops[insideShop]['ShowroomVehicles'][ClosestVehicle].chosenVehicle]['brand']
end
```

### Finding Closest Vehicle (Line 137-157)
```lua
local function setClosestShowroomVehicle()
    local pos = GetEntityCoords(PlayerPedId(), true)
    local current = nil
    local dist = nil
    
    -- Loop through all showroom vehicles in current shop
    for id in pairs(Config.Shops[insideShop]['ShowroomVehicles']) do
        local dist2 = #(pos - vector3(x, y, z))  -- Calculate distance
        
        if current then
            if dist2 < dist then
                current = id  -- Update if closer
                dist = dist2
            end
        else
            dist = dist2
            current = id
        end
    end
    
    if current ~= ClosestVehicle then
        ClosestVehicle = current  -- Update global variable
    end
end
```

---

## Menu Parameters Explained

### Menu Item Structure
```lua
{
    header = "Title Text",              -- Main title of menu item
    txt = "Description text",           -- Optional description
    icon = 'fa-solid fa-car',          -- Font Awesome icon
    isMenuHeader = true,                -- If true, item is not clickable (just displays info)
    params = {
        event = 'event:name',           -- Event to trigger
        isServer = false,               -- If true, triggers server event
        args = { key = value }          -- Arguments passed to event
    }
}
```

### Opening Menu Functions
```lua
-- Show header only (small preview menu)
exports['qb-menu']:showHeader(menuTable)

-- Open full menu
exports['qb-menu']:openMenu(menuTable, sortAlphabetically, keepInputActive)

-- Close menu
exports['qb-menu']:closeMenu()
```

---

## Configuration Options Affecting Menus

### Config.lua Settings

```lua
Config.UsingTarget = true/false
-- If true: Uses qb-target for vehicle interaction
-- If false: Uses zone proximity detection

Config.FilterByMake = true/false
-- If true: Adds manufacturer selection before category menu
-- If false: Goes directly to category menu

Config.SortAlphabetically = true/false
-- If true: Sorts all menu items alphabetically
-- If false: Uses default order

Config.HideCategorySelectForOne = true/false
-- If true: Skips category menu if shop only has one category
-- If false: Always shows category menu

Config.MinimumDown = 10
-- Minimum down payment percentage (shown in finance dialog)

Config.MaximumPayments = 24
-- Maximum number of payments allowed (shown in finance dialog)
```

---

## Summary of Menu Flow

### Free-Use Shop Flow:
1. Player enters shop zone → `insideShop` variable set
2. Player approaches vehicle → Zone triggers `showHeader(vehHeaderMenu)`
3. Player interacts → Opens `vehicleMenu` with options:
   - Test Drive
   - Buy Vehicle (instant purchase via server)
   - Finance Vehicle (opens input dialog)
   - Swap Vehicle (opens category/vehicle selection)

### Managed Shop Flow:
1. Employee enters shop zone → `insideShop` variable set
2. Employee approaches vehicle → Zone triggers `showHeader(vehHeaderMenu)`
3. Employee interacts → Opens `vehicleMenu` with options:
   - Test Drive for Customer (opens player ID input)
   - Sell to Customer (opens player ID input)
   - Finance to Customer (opens input with player ID + payment info)
   - Swap Vehicle (opens category/vehicle selection)

### Finance Zone Flow:
1. Player enters finance zone → `showHeader(financeMenu)`
2. Player clicks → Opens list of financed vehicles
3. Player selects vehicle → Shows payment options:
   - Make a payment (partial)
   - Pay off in full

---

## Code Files Reference

### client.lua
- **Lines 61-91:** Static menu headers
- **Lines 125-135:** Vehicle info helper functions
- **Lines 137-157:** Closest vehicle detection
- **Lines 199-242:** Vehicle zone creation
- **Lines 245-313:** Free-use shop zone creation and menu
- **Lines 315-387:** Managed shop zone creation and menu
- **Lines 389-406:** Finance zone creation
- **Lines 445-452:** Menu opening events
- **Lines 537-583:** Category selection menu
- **Lines 585-643:** Individual vehicle selection menu
- **Lines 645-680:** Make selection menu (if enabled)
- **Lines 682-736:** Finance input dialogs
- **Lines 782-865:** Finance vehicle management menus
- **Lines 886-907:** Player ID input dialog

### config.lua
- **Lines 1-12:** Menu behavior configuration
- **Lines 13-297:** Shop definitions (zones, vehicles, jobs)

### locales/en.lua
- All menu text strings and translations

---

## Troubleshooting

### Menu Not Showing
1. Check if player is inside shop zone (`insideShop` variable)
2. Verify `qb-menu` resource is running
3. Check if player has correct job (for managed shops)
4. Verify zone coordinates are correct in config

### Menu Options Missing
1. Check shop type (free-use vs managed)
2. Verify player job matches `Config.Shops[shopName]['Job']`
3. Check `Config.FilterByMake` setting
4. Verify vehicles exist in `QBCore.Shared.Vehicles`

### Input Dialogs Not Working
1. Verify `qb-input` resource is running
2. Check console for errors
3. Ensure all required inputs are filled before submitting

---

## Conclusion

The qb-vehicleshop menu system is a **zone-based, event-driven architecture** that:
- Uses **PolyZone** for detecting when players enter shop areas
- Uses **qb-menu** for displaying interactive menus
- Uses **qb-input** for collecting user data
- Dynamically generates menus based on shop type, player job, and available vehicles
- Separates free-use (self-service) and managed (employee-assisted) shop experiences

The code is modular and well-organized, with clear separation between:
- Zone creation and management
- Menu structure definition
- Event handling
- Helper functions for data retrieval
