# Menu System Documentation Index

## 📚 Documentation Overview

This repository includes comprehensive documentation explaining how the vehicle shop menu system works. The documentation is split into two main files for easier navigation:

---

## 📖 Available Documentation

### 1. [MENU_DOCUMENTATION.md](./MENU_DOCUMENTATION.md) - Comprehensive Technical Guide
**Complete technical reference covering:**
- 🎯 Menu system overview and architecture
- 🔧 Required dependencies (qb-menu, qb-input, PolyZone)
- 🏪 Shop types (Free-Use vs Managed)
- 📝 Static menu headers and dynamic menu generation
- 🌐 Zone-based menu triggering system
- 🎮 All menu events and their callbacks
- 💡 Helper functions and utilities
- 🔍 Code line references for each component
- 🐛 Troubleshooting guide

**Best for:** Developers who want to understand or modify the menu system

---

### 2. [MENU_FLOW_DIAGRAM.md](./MENU_FLOW_DIAGRAM.md) - Visual Flow Guide
**Visual diagrams and quick reference including:**
- 📊 ASCII flow diagrams showing menu navigation
- 🔄 Vehicle swap flow visualization
- 💰 Finance zone flow diagram
- 🚗 Test drive process flow
- 📋 Menu API calls reference
- 🗺️ Zone types explanation
- ⚙️ Configuration impact table
- 🔑 Key variables reference

**Best for:** Understanding how menus flow and interact visually

---

## 🚀 Quick Start Guide

### Understanding the Menu System in 5 Minutes

1. **Menu Dependencies:**
   - `qb-menu` - Displays interactive menus
   - `qb-input` - Collects user input (IDs, payment amounts)
   - `PolyZone` - Detects when players enter shop areas

2. **Two Shop Types:**
   - **Free-Use** (`'free-use'`): Players buy vehicles directly
   - **Managed** (`'managed'`): Employees sell to customers

3. **How Menus Are Triggered:**
   - Player enters shop zone → Menu system activates
   - Player approaches vehicle → Header menu appears
   - Player interacts → Full menu opens with options

4. **Main Menu Options:**
   - **Test Drive** - Try the vehicle for limited time
   - **Buy/Sell** - Purchase or sell vehicle
   - **Finance** - Set up payment plan
   - **Swap Vehicle** - Change display vehicle

5. **Menu Flow:**
   ```
   Shop Zone → Vehicle Interaction → Main Menu → Action/Sub-Menu → Result
   ```

---

## 🎯 Key Files in Repository

| File | Purpose |
|------|---------|
| `client.lua` | Client-side menu logic and event handlers |
| `config.lua` | Shop definitions, zones, and settings |
| `server.lua` | Server-side purchase/finance processing |
| `locales/en.lua` | Menu text and translations |
| `MENU_DOCUMENTATION.md` | Complete technical documentation |
| `MENU_FLOW_DIAGRAM.md` | Visual flow diagrams |

---

## 🔧 Common Menu Configuration

### Enable/Disable Features

```lua
-- In config.lua

-- Use qb-target instead of zones
Config.UsingTarget = true/false

-- Filter by manufacturer before category
Config.FilterByMake = true/false

-- Sort menu items alphabetically
Config.SortAlphabetically = true/false

-- Skip category menu if only one category exists
Config.HideCategorySelectForOne = true/false
```

### Shop Configuration

```lua
Config.Shops = {
    ['shopname'] = {
        ['Type'] = 'free-use',  -- or 'managed'
        ['Job'] = 'none',       -- or specific job like 'cardealer'
        ['Zone'] = {...},       -- Polygon defining shop area
        ['ShowroomVehicles'] = {...},  -- Display vehicles
        ['FinanceZone'] = vector3(...), -- Finance desk location
    }
}
```

---

## 📌 Menu Code Locations

### Quick Reference to Code Sections

| Feature | File | Lines |
|---------|------|-------|
| Static menu headers | client.lua | 61-91 |
| Free-use shop menu | client.lua | 245-313 |
| Managed shop menu | client.lua | 315-387 |
| Vehicle swap flow | client.lua | 537-643 |
| Finance input dialogs | client.lua | 682-736 |
| Finance vehicle list | client.lua | 782-865 |
| Zone creation | client.lua | 199-242 |

---

## 🎓 Learning Path

### Recommended Reading Order

1. **For Quick Understanding:**
   - Read this INDEX file (you are here!)
   - Review [MENU_FLOW_DIAGRAM.md](./MENU_FLOW_DIAGRAM.md)
   - Experiment in-game

2. **For Development:**
   - Read [MENU_DOCUMENTATION.md](./MENU_DOCUMENTATION.md)
   - Review `client.lua` code
   - Check `config.lua` for settings

3. **For Customization:**
   - Understand zone system in documentation
   - Modify `Config.Shops` for your needs
   - Adjust menu options in `client.lua`

---

## ❓ FAQ

**Q: How do I add a new shop?**
A: Add a new entry to `Config.Shops` in `config.lua` with zone coordinates and settings.

**Q: How do I change menu text?**
A: Edit the locale files in the `locales/` directory.

**Q: Can I add custom menu options?**
A: Yes, modify the `vehicleMenu` table in the shop zone creation functions.

**Q: Why isn't my menu showing?**
A: Check if:
- Player is inside the shop zone
- `qb-menu` resource is running
- Player has the correct job (for managed shops)
- Zone coordinates are correct

**Q: How do I use qb-target instead of zones?**
A: Set `Config.UsingTarget = true` in `config.lua`

---

## 🔗 Related Resources

- [QBCore Framework](https://github.com/qbcore-framework)
- [qb-menu Documentation](https://github.com/qbcore-framework/qb-menu)
- [qb-input Documentation](https://github.com/qbcore-framework/qb-input)
- [PolyZone Documentation](https://github.com/mkafrin/PolyZone/wiki)

---

## 📝 Summary

The qb-vehicleshop menu system is a **zone-based, event-driven architecture** that provides an immersive vehicle shopping experience. It uses:

- **PolyZone** for detecting shop entry
- **qb-menu** for interactive menus
- **qb-input** for data collection
- **Dynamic menu generation** based on context
- **Separate flows** for public and employee experiences

For complete details, see:
- 📖 [MENU_DOCUMENTATION.md](./MENU_DOCUMENTATION.md) - Technical reference
- 📊 [MENU_FLOW_DIAGRAM.md](./MENU_FLOW_DIAGRAM.md) - Visual diagrams

---

## 📞 Support

If you have questions about the menu system:
1. Read the documentation files thoroughly
2. Check the troubleshooting section in MENU_DOCUMENTATION.md
3. Review the code with line references provided
4. Test in-game to see the flow in action

---

**Last Updated:** December 11, 2024
**Documentation Version:** 1.0
**Compatible with:** qb-vehicleshop v2.1.0
