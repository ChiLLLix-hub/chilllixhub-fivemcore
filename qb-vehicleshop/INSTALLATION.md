# Installation Guide - Modern NUI

This guide will help you install and configure the new React-based NUI for qb-vehicleshop.

## Quick Install

The NUI is already built and ready to use. Simply:

1. **Pull the latest changes** from your repository
2. **Restart the resource**: `ensure qb-vehicleshop`
3. **Done!** The new UI is now active

## What You Get

- ✅ Modern glassmorphism UI design
- ✅ Fully responsive interface
- ✅ Interactive finance calculator
- ✅ Smooth animations
- ✅ Test drive timer overlay
- ✅ Category and vehicle browsing grids

## Troubleshooting

### UI Not Showing

1. **Check Console**: Press F8 in-game and look for errors
2. **Verify Files**: Make sure `qb-vehicleshop/html/dist/` folder exists with files
3. **Clear Cache**: Delete FiveM cache and restart
4. **Restart Resource**: `restart qb-vehicleshop`

### Styling Issues

1. **Force Rebuild**: 
   ```bash
   cd resources/qb-vehicleshop/html
   npm install
   npm run build
   ```
2. **Restart**: `ensure qb-vehicleshop`

## Configuration

The NUI uses your existing `config.lua` settings:

- `Config.MinimumDown` - Minimum down payment %
- `Config.MaximumPayments` - Maximum number of payments
- `Config.TestDriveTimeLimit` - Test drive duration
- All other existing configurations work as before

## Controls

- **E Key** - Open vehicle menu when near a showroom vehicle
- **ESC Key** - Close the UI
- **Mouse** - Navigate and click buttons
- **Sliders** - Adjust finance options

## Customization

### Change Colors

Edit `html/tailwind.config.js` to customize:

```js
colors: {
  primary: {
    500: '#0ea5e9',  // Change this to your color
  }
}
```

Then rebuild:
```bash
cd html
npm run build
```

### Modify Text/Labels

Labels and text come from your locale files in `locales/` folder.

## For Developers

### Development Mode

```bash
cd html
npm install
npm run dev
```

Visit `http://localhost:5173` to see changes in real-time.

### Build for Production

```bash
cd html
npm run build
```

### File Structure

```
html/
├── src/
│   ├── components/     # React components
│   ├── hooks/         # Custom hooks
│   ├── utils/         # Helper functions
│   └── App.jsx        # Main app
├── dist/              # Production build (committed to git)
└── package.json       # Dependencies
```

## Support

- **Documentation**: See [NUI_DOCUMENTATION.md](NUI_DOCUMENTATION.md)
- **Issues**: Report on GitHub
- **Discord**: QBCore Framework Discord

## Migration Notes

### What Changed
- Vehicle browsing now uses React NUI
- Test drives show modern overlay
- Finance uses interactive calculator
- Category selection is now a grid

### What Stayed the Same
- All backend functionality
- Database structure
- Server events
- Configuration file
- Finance zone menu (still uses qb-menu)
- Owned vehicles menu (still uses qb-menu)

## Dependencies

Still requires:
- qb-core
- qb-menu (for finance zone)
- qb-input (for dialogs)
- PolyZone
- oxmysql

## Performance

The new NUI is optimized for performance:
- Production build is minified and compressed
- Lazy loading for better initial load
- Efficient React rendering
- No performance impact on gameplay

## Browser Compatibility

Works with FiveM's CEF (Chromium Embedded Framework).
Compatible with all modern FiveM clients.

## Credits

- **Original**: qb-vehicleshop by Kakarot
- **Modern NUI**: Built with React + Vite + Tailwind CSS
- **Framework**: QBCore Framework

---

**Enjoy your new beautiful vehicle shop UI! 🚗✨**
