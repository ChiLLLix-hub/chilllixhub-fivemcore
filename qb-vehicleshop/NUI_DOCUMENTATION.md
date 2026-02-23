# Modern NUI Implementation Guide

## Overview

The qb-vehicleshop resource now features a modern, responsive NUI built with React.js, Vite, and Tailwind CSS. This guide explains the new UI system and how it integrates with the existing qb-vehicleshop functionality.

## What's New

### Modern UI Features

1. **Glassmorphism Design** - Beautiful, modern glass-effect UI elements
2. **Responsive Layout** - Works on any screen size
3. **Smooth Animations** - Powered by Framer Motion
4. **Interactive Finance Calculator** - Real-time payment calculations with sliders
5. **Test Drive Timer Overlay** - Clean, persistent timer during test drives
6. **Category & Vehicle Grids** - Easy browsing with card-based layouts
7. **ESC Key Support** - Quick UI dismissal

### Technical Stack

- **React 18.2** - Modern React with hooks
- **Vite 5.0** - Fast build tool and dev server
- **Tailwind CSS 3.3** - Utility-first CSS framework
- **Framer Motion 10.16** - Animation library

## Architecture

### File Structure

```
qb-vehicleshop/
├── html/                          # NUI files
│   ├── src/
│   │   ├── components/           # React components
│   │   │   ├── VehicleCard.jsx   # Vehicle display card
│   │   │   ├── CategoryGrid.jsx  # Category selection
│   │   │   ├── VehicleGrid.jsx   # Vehicle list
│   │   │   ├── FinanceModal.jsx  # Finance calculator
│   │   │   └── TestDriveOverlay.jsx
│   │   ├── hooks/
│   │   │   └── useNuiEvent.js    # NUI event hooks
│   │   ├── utils/
│   │   │   └── misc.js           # Helper functions
│   │   ├── App.jsx               # Main app component
│   │   ├── main.jsx              # React entry point
│   │   └── index.css             # Global styles
│   ├── dist/                     # Production build (committed)
│   ├── package.json
│   ├── vite.config.js
│   ├── tailwind.config.js
│   └── README.md
├── client_nui.lua                # NUI integration layer
├── client.lua                    # Main client logic (updated)
└── fxmanifest.lua                # Resource manifest (updated)
```

### Communication Flow

```
Player Interaction
    ↓
PolyZone/Target Detection
    ↓
client.lua → OpenVehicleNUI()
    ↓
client_nui.lua → SendNUIMessage()
    ↓
React NUI (html/src/)
    ↓
User Interaction
    ↓
fetchNui() → NUI Callback
    ↓
client_nui.lua → RegisterNUICallback()
    ↓
client.lua → TriggerEvent/TriggerServerEvent
    ↓
Server Processing
```

## Components

### VehicleCard
**Purpose**: Display vehicle information with action buttons

**Props**:
- `vehicle` - Vehicle data object with model, name, brand, price, stats
- `onTestDrive` - Test drive callback
- `onBuy` - Purchase callback
- `onFinance` - Finance callback
- `onSwap` - Swap vehicle callback

**Features**:
- Displays vehicle name, brand, and price
- Shows vehicle stats (speed, acceleration, braking, handling)
- Four action buttons with hover animations
- Glassmorphism card design

### CategoryGrid
**Purpose**: Display vehicle categories or makes

**Props**:
- `categories` - Array of category objects
- `onSelect` - Selection callback
- `onClose` - Close callback

**Features**:
- Grid layout (responsive: 1-3 columns)
- Icon support
- Vehicle count display
- Staggered animation entrance

### VehicleGrid
**Purpose**: Display list of vehicles in a category

**Props**:
- `vehicles` - Array of vehicle objects
- `onSelect` - Selection callback
- `onClose` - Close callback
- `title` - Grid title

**Features**:
- Responsive grid (1-3 columns)
- Vehicle cards with price and details
- Category badges
- Smooth animations

### FinanceModal
**Purpose**: Interactive vehicle financing calculator

**Props**:
- `vehicle` - Vehicle being financed
- `config` - Finance config (minimumDown, maximumPayments)
- `onSubmit` - Submit callback
- `onClose` - Close callback

**Features**:
- Down payment slider
- Payment amount slider
- Real-time calculations
- Summary breakdown
- Responsive design

### TestDriveOverlay
**Purpose**: Persistent overlay during test drives

**Props**:
- `timeRemaining` - Formatted time string
- `onReturn` - Return callback

**Features**:
- Top-center positioning
- Time countdown display
- Quick return button
- Non-intrusive design

## Lua Integration

### Opening Menus

```lua
-- Open vehicle menu
local vehicleData = {
    model = 'adder',
    name = 'Adder',
    brand = 'Truffade',
    price = 1000000,
    category = 'super',
    stats = {
        speed = 95,
        acceleration = 88,
        braking = 85,
        handling = 82
    }
}
OpenVehicleNUI(vehicleData)

-- Open category menu
local categories = {
    {id = 'sports', name = 'Sports', icon = '🏎️'},
    {id = 'super', name = 'Super', icon = '🚀'}
}
OpenCategoryNUI(categories)

-- Open vehicle list
local vehicles = {
    {model = 'adder', name = 'Adder', brand = 'Truffade', price = 1000000}
}
OpenVehicleListNUI(vehicles)
```

### Test Drive Management

```lua
-- Start test drive
StartTestDriveNUI()

-- Update timer (call every second)
UpdateTestDriveTime("2:30")

-- End test drive
EndTestDriveNUI()
```

### Closing UI

```lua
CloseNUI()
```

## Customization

### Changing Colors

Edit `html/tailwind.config.js`:

```js
theme: {
  extend: {
    colors: {
      primary: {
        50: '#f0f9ff',   // Lightest
        500: '#0ea5e9',  // Base
        900: '#0c4a6e',  // Darkest
      }
    }
  }
}
```

### Modifying Animations

In `html/tailwind.config.js`:

```js
animation: {
  'fade-in': 'fadeIn 0.3s ease-in-out',
}
```

Or use Framer Motion in components:

```jsx
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.3 }}
>
```

### Adding New Components

1. Create component in `html/src/components/`
2. Import in `App.jsx`
3. Add state and handlers
4. Create corresponding Lua functions in `client_nui.lua`

## Development

### Setup Development Environment

```bash
cd html
npm install
npm run dev
```

Access at: `http://localhost:5173`

### Building for Production

```bash
cd html
npm run build
```

Output goes to `html/dist/` which is referenced by FiveM.

### Testing in FiveM

1. Make changes to components
2. Run `npm run build`
3. Restart resource: `ensure qb-vehicleshop`
4. Test in-game

## Migration Notes

### What Changed

- **Vehicle browsing**: Now uses NUI instead of qb-menu
- **Test drives**: Now shows modern overlay instead of on-screen text
- **Finance**: Interactive calculator instead of input dialog
- **Categories/Makes**: Grid view instead of list menu

### What Stayed the Same

- Finance zone interactions (still uses qb-menu)
- Owned vehicles menu (still uses qb-menu)
- All backend logic and server events
- Database structure
- Configuration file

### Backward Compatibility

The new NUI is designed to work alongside existing qb-menu dependencies for features not yet migrated (finance zone, owned vehicles management).

## Troubleshooting

### NUI Not Showing

1. Check console for errors: F8 in-game
2. Verify files exist: `qb-vehicleshop/html/dist/`
3. Restart resource: `ensure qb-vehicleshop`
4. Check fxmanifest.lua has correct paths

### Styling Issues

1. Rebuild: `cd html && npm run build`
2. Clear FiveM cache
3. Restart resource

### Animations Not Working

1. Verify Framer Motion is installed: `npm list framer-motion`
2. Check browser console (F12) for errors
3. Ensure React is running in production mode

## Future Enhancements

Potential additions:
- Vehicle preview 3D rotation
- Color picker for customization
- Comparison tool for vehicles
- Favorite vehicles system
- Advanced filtering
- Mobile app integration
- Voice command support

## Credits

- Original qb-vehicleshop by Kakarot
- Modern NUI by GitHub Copilot
- Built with React, Vite, and Tailwind CSS
