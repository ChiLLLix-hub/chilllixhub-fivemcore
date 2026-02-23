# Modern Vehicle Shop NUI

This is a modern, responsive NUI for the qb-vehicleshop resource built with React.js, Vite, and Tailwind CSS.

## Features

- ✨ Beautiful glassmorphism design
- 📱 Fully responsive (mobile-friendly)
- 🎨 Modern Tailwind CSS styling
- ⚡ Fast and smooth animations with Framer Motion
- 🎯 Intuitive user experience

## Components

### VehicleCard
Displays the currently selected vehicle with options to:
- Test drive
- Buy now
- Finance
- Swap vehicle

### CategoryGrid
Shows all available vehicle categories with icons and vehicle counts.

### VehicleGrid
Displays all vehicles in a selected category as cards.

### FinanceModal
Interactive financing calculator with sliders for:
- Down payment percentage
- Number of payments
- Real-time monthly payment calculation

### TestDriveOverlay
Persistent overlay during test drives showing:
- Time remaining
- Quick return button

## Development

### Prerequisites
- Node.js 16+
- npm or yarn

### Setup
```bash
cd html
npm install
```

### Development Server
```bash
npm run dev
```

### Build for Production
```bash
npm run build
```

The build output will be in `html/dist/` which is referenced by the FiveM resource.

## Integration

The NUI communicates with the Lua client using NUI callbacks defined in `client_nui.lua`:

### Events from Lua to NUI
- `setVisible` - Show/hide the UI
- `openVehicleMenu` - Show vehicle card with data
- `openCategoryMenu` - Show category selection
- `openVehicleList` - Show vehicle grid
- `openFinanceMenu` - Show finance calculator
- `startTestDrive` - Show test drive overlay
- `updateTestDriveTime` - Update test drive timer
- `endTestDrive` - Hide test drive overlay

### Callbacks from NUI to Lua
- `closeUI` - Close the NUI
- `testDrive` - Start test drive
- `buyVehicle` - Purchase vehicle
- `financeVehicle` - Finance vehicle
- `swapVehicle` - Open vehicle swap menu
- `selectCategory` - Select a category
- `selectVehicle` - Select a vehicle to display
- `returnTestDrive` - End test drive

## Customization

### Colors
Edit `html/tailwind.config.js` to customize the color scheme:
```js
theme: {
  extend: {
    colors: {
      primary: {
        // Your custom colors here
      }
    }
  }
}
```

### Animations
Modify `html/tailwind.config.js` animations section or use Framer Motion props in components.

### Layout
All components are in `html/src/components/` and can be customized as needed.

## Dependencies

- React 18.2
- React DOM 18.2
- Framer Motion 10.16
- Vite 5.0
- Tailwind CSS 3.3

## Browser Compatibility

Works with the CEF (Chromium Embedded Framework) version used in FiveM.
