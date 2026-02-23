# Menu Flow Diagram

## Visual Overview of Menu System

```
┌─────────────────────────────────────────────────────────────────┐
│                     PLAYER ENTERS SHOP ZONE                      │
│                    (PolyZone triggers event)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                ┌────────────────────────┐
                │  insideShop = shopName │
                │   (Global variable)    │
                └────────────┬───────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │ Thread starts updating       │
              │ closest vehicle & menu       │
              │ every 1 second               │
              └──────────────┬───────────────┘
                             │
        ┌────────────────────┴────────────────────┐
        │                                         │
        ▼                                         ▼
┌───────────────┐                        ┌───────────────┐
│  FREE-USE     │                        │   MANAGED     │
│  SHOP MENU    │                        │  SHOP MENU    │
└───────┬───────┘                        └───────┬───────┘
        │                                        │
        │                                        │
┌───────▼────────────────────────────┐  ┌────────▼──────────────────────────┐
│  PLAYER APPROACHES VEHICLE         │  │  EMPLOYEE APPROACHES VEHICLE      │
│  (BoxZone or qb-target triggers)   │  │  (BoxZone or qb-target triggers)  │
└───────┬────────────────────────────┘  └────────┬──────────────────────────┘
        │                                        │
        ▼                                        ▼
┌──────────────────┐                   ┌──────────────────┐
│  showHeader()    │                   │  showHeader()    │
│  "Vehicle        │                   │  "Vehicle        │
│   Options"       │                   │   Options"       │
└───────┬──────────┘                   └────────┬─────────┘
        │                                       │
        │ (Player Interacts)                    │ (Employee Interacts)
        ▼                                       ▼
┌──────────────────────────────────┐  ┌──────────────────────────────────┐
│   MAIN VEHICLE MENU (FREE-USE)   │  │   MAIN VEHICLE MENU (MANAGED)    │
├──────────────────────────────────┤  ├──────────────────────────────────┤
│ [Header: Brand Name - $Price]    │  │ [Header: Brand Name - $Price]    │
│                                  │  │                                  │
│ 1. Test Drive                    │  │ 1. Test Drive for Customer       │
│    └─> Spawn vehicle             │  │    └─> Input: Player ID          │
│        └─> Timer starts          │  │        └─> Spawn vehicle         │
│            └─> Return zone       │  │            └─> Timer starts      │
│                                  │  │                └─> Return zone   │
│ 2. Buy Vehicle                   │  │                                  │
│    └─> Server: Purchase          │  │ 2. Sell to Customer              │
│        └─> Spawn vehicle         │  │    └─> Input: Player ID          │
│                                  │  │        └─> Server: Sell          │
│ 3. Finance Vehicle               │  │            └─> Spawn vehicle     │
│    └─> Input Dialog ────────┐   │  │                                  │
│        ├─> Down Payment      │   │  │ 3. Finance to Customer           │
│        └─> Payment Amount    │   │  │    └─> Input Dialog ──────────┐ │
│            └─> Server        │   │  │        ├─> Player ID          │ │
│                              │   │  │        ├─> Down Payment       │ │
│ 4. Swap Vehicle              │   │  │        └─> Payment Amount     │ │
│    └─> See Flow Below        │   │  │            └─> Server         │ │
│                              │   │  │                               │ │
└──────────────────────────────┘   │  │ 4. Swap Vehicle               │ │
                                   │  │    └─> See Flow Below         │ │
                                   │  │                               │ │
                                   │  └───────────────────────────────┘ │
                                   │                                    │
                                   └────────────────────────────────────┘
```

## Vehicle Swap Flow

```
┌──────────────────────────┐
│  Swap Vehicle (Clicked)  │
└───────────┬──────────────┘
            │
            ▼
    ┌───────────────────┐
    │ FilterByMake?     │
    │ (Config setting)  │
    └───┬───────────┬───┘
        │ YES       │ NO
        ▼           ▼
┌───────────────┐  │
│  MAKES MENU   │  │
├───────────────┤  │
│ Ferrari       │  │
│ Lamborghini   │  │
│ Porsche       │  │
│ etc...        │  │
└───────┬───────┘  │
        │          │
        └──────┬───┘
               ▼
     ┌──────────────────┐
     │ CATEGORIES MENU  │
     ├──────────────────┤
     │ Sports           │
     │ SUVs             │
     │ Sedans           │
     │ Motorcycles      │
     │ etc...           │
     └────────┬─────────┘
              │
              ▼
   ┌────────────────────────┐
   │  VEHICLES MENU         │
   ├────────────────────────┤
   │ Adder - $1,000,000     │
   │ Zentorno - $725,000    │
   │ Entity XF - $795,000   │
   │ etc...                 │
   └────────┬───────────────┘
            │
            ▼
   ┌────────────────────────┐
   │ SERVER: swapVehicle    │
   │ ├─> Delete old vehicle │
   │ └─> Spawn new vehicle  │
   └────────────────────────┘
```

## Finance Zone Flow

```
┌─────────────────────────────┐
│ PLAYER ENTERS FINANCE ZONE  │
│ (BoxZone at specific coords)│
└──────────────┬──────────────┘
               │
               ▼
      ┌────────────────┐
      │  showHeader()  │
      │  "Financed     │
      │   Vehicles"    │
      └────────┬───────┘
               │
               │ (Player Interacts)
               ▼
    ┌─────────────────────────┐
    │ FINANCED VEHICLES LIST  │
    ├─────────────────────────┤
    │ Adder (Plate: ABC123)   │
    │ Zentorno (Plate: XYZ789)│
    │ etc...                  │
    └───────────┬─────────────┘
                │
                │ (Select Vehicle)
                ▼
    ┌──────────────────────────────┐
    │  FINANCE DETAILS MENU        │
    ├──────────────────────────────┤
    │ [Balance: $500,000]          │
    │ [Payments Left: 20]          │
    │ [Payment Amount: $25,000]    │
    │                              │
    │ 1. Make a Payment            │
    │    └─> Input Dialog          │
    │        └─> Amount            │
    │            └─> Server        │
    │                              │
    │ 2. Pay Off Vehicle           │
    │    └─> Server: Full Payment  │
    │        └─> Clear balance     │
    └──────────────────────────────┘
```

## Test Drive Flow

```
┌──────────────────────────┐
│  Test Drive (Clicked)    │
└───────────┬──────────────┘
            │
            ▼
    ┌───────────────┐
    │ Server        │
    │ Spawns        │
    │ Vehicle       │
    └───────┬───────┘
            │
            ▼
    ┌───────────────┐
    │ Player Warped │
    │ Into Vehicle  │
    └───────┬───────┘
            │
            ▼
    ┌───────────────────┐
    │ Timer Starts      │
    │ (Countdown shown) │
    └───────┬───────────┘
            │
            ▼
    ┌───────────────────┐
    │ Return Zone       │
    │ Created           │
    └───────┬───────────┘
            │
    ┌───────┴─────────┐
    │                 │
    ▼                 ▼
┌─────────┐    ┌──────────────┐
│ Timer   │    │ Player       │
│ Expires │    │ Returns to   │
│         │    │ Return Zone  │
└────┬────┘    └──────┬───────┘
     │                │
     │                ▼
     │        ┌───────────────┐
     │        │ showHeader()  │
     │        │ "Finish Test  │
     │        │  Drive"       │
     │        └───────┬───────┘
     │                │
     │                │ (Player Clicks)
     │                ▼
     └────────────────┤
                      ▼
              ┌───────────────┐
              │ Vehicle       │
              │ Deleted       │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ Player        │
              │ Teleported    │
              │ Back          │
              └───────────────┘
```

## Menu API Calls Reference

### Opening Menus
```lua
-- Show small header preview
exports['qb-menu']:showHeader(menuTable)

-- Open full menu
exports['qb-menu']:openMenu(menuTable, sortAlphabetically, keepInputActive)

-- Close menu
exports['qb-menu']:closeMenu()
```

### Input Dialogs
```lua
-- Show input dialog
local dialog = exports['qb-input']:ShowInput({
    header = "Title",
    submitText = "Submit",
    inputs = {
        {
            type = 'number',      -- or 'text'
            isRequired = true,
            name = 'fieldName',
            text = 'Placeholder text'
        }
    }
})

if dialog then
    -- dialog.fieldName contains the value
end
```

## Zone Types

### 1. Shop Zones (PolyZone)
- Polygon shape surrounding entire shop
- Triggers when player enters/exits
- Sets `insideShop` variable
- Starts menu update thread

### 2. Vehicle Zones (BoxZone or qb-target)
- Small box around each showroom vehicle
- Triggers vehicle interaction menu
- Uses either proximity (BoxZone) or targeting (qb-target)

### 3. Finance Zones (BoxZone)
- Small box at finance desk
- Triggers financed vehicles menu
- Independent of shop zone

### 4. Test Drive Return Zone (BoxZone)
- Created dynamically during test drive
- Only active during test drive
- Allows player to return early

## Key Variables

```lua
-- Global state variables
local insideShop = nil           -- Current shop name or nil
local ClosestVehicle = 1         -- Index of closest showroom vehicle
local vehicleMenu = {}           -- Dynamically built menu
local testDriveVeh = 0           -- Network ID of test drive vehicle
local inTestDrive = false        -- Test drive active flag
local tempShop = nil             -- Saved shop during test drive
```

## Configuration Impact on Menus

| Config Setting | Effect on Menus |
|----------------|----------------|
| `UsingTarget = true` | Uses qb-target for vehicle interaction |
| `UsingTarget = false` | Uses BoxZone proximity detection |
| `FilterByMake = true` | Adds make selection menu before categories |
| `FilterByMake = false` | Goes directly to categories |
| `SortAlphabetically = true` | Sorts all menu items A-Z |
| `HideCategorySelectForOne = true` | Skips category menu if only one exists |
| `Shop.Type = 'free-use'` | Self-service menu options |
| `Shop.Type = 'managed'` | Employee-assisted menu options |
| `Shop.Job = 'none'` | Anyone can access |
| `Shop.Job = 'cardealer'` | Only cardealers can access |

## Event Flow Summary

```
Player Action → Zone Detection → Event Triggered → Menu Opened
                     ↓
              Menu Item Clicked → Event Triggered → Action Performed
                     ↓
              Server Response → Update UI/State
```
