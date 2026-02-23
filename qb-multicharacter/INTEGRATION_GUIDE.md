# Integration Guide: Using illenium-appearance with qb-multicharacter

This guide explains how to integrate `illenium-appearance` with `qb-multicharacter` in the QB-Core framework.

## Overview

By default, `qb-multicharacter` uses `qb-clothing` for character appearance. To use `illenium-appearance` instead, you need to modify specific lines in both the client and server files.

## Required Changes

### 1. Client-Side Changes (`client/main.lua`)

#### Line 46: Change the clothing event trigger

**Original Code (Line 46):**
```lua
TriggerEvent('qb-clothing:client:loadPlayerClothing', data, charPed)
```

**Replace With:**
```lua
exports['illenium-appearance']:setPedAppearance(charPed, data)
```

**Explanation:** This change uses illenium-appearance's export function `setPedAppearance` to apply the character's appearance to the preview ped in the character selection screen.

#### Line 115: No Change Required

**Line 115:**
```lua
TriggerEvent('qb-clothes:client:CreateFirstCharacter')
```

**Keep as is!** illenium-appearance includes backward compatibility for this event, so no changes are needed. The event `qb-clothes:client:CreateFirstCharacter` is registered and handled by illenium-appearance automatically.

---

### 2. Server-Side Changes (`server/main.lua`)

#### Lines 209-223: Update the getSkin callback

**Original Code (Lines 200-207 - commented out):**
```lua
QBCore.Functions.CreateCallback('qb-multicharacter:server:getSkin', function(_, cb, cid)
    local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', { cid, 1 })
    if result[1] ~= nil then
        cb(result[1].model, result[1].skin)
    else
        cb(nil)
    end
end)
```

**Use This Code Instead (Lines 209-223 - already present in example):**
```lua
-- This callback queries the 'playerskins' table (not 'players' table)
-- The 'playerskins' table is where illenium-appearance stores character appearance data
QBCore.Functions.CreateCallback("qb-multicharacter:server:getSkin", function(source, cb, cid)
    local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ?', {cid})
    if result[1] then
        local skinData = json.decode(result[1].skin)
        if skinData then
            cb(result[1].skin, skinData.model)
        else
            cb(nil)
        end
    else
        cb(nil)
    end
end)
```

**Important Notes:**
- **Correct Table:** This queries the `playerskins` table, NOT the `players` table. The `playerskins` table is where illenium-appearance stores all character appearance data (skin, clothing, features, etc.).
- **Nil Safety:** The code properly checks if `result[1]` exists before accessing it to prevent crashes when a character has no saved appearance yet.
- **Return Format:** Returns the raw JSON string and the model hash separately, which the client expects.

---

## Summary of Changes

| File | Line(s) | Change Description |
|------|---------|-------------------|
| `client/main.lua` | 46 | Replace `TriggerEvent('qb-clothing:client:loadPlayerClothing', data, charPed)` with `exports['illenium-appearance']:setPedAppearance(charPed, data)` |
| `client/main.lua` | 115 | **No change needed** - illenium-appearance has backward compatibility |
| `server/main.lua` | 209-223 | Update callback to query `playerskins` table (not `players` table) and add nil safety checks |
| `server/main.lua` | 209-219 | Ensure the illenium-appearance version of the callback is active (already present in example) |

---

## Full Code Examples

### Client File: `client/main.lua` (Modified Section - Line 46)

```lua
local function initializePedModel(model, data)
    CreateThread(function()
        if not model then
            model = joaat(randommodels[math.random(#randommodels)])
        end
        loadModel(model)
        charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.w, false, true)
        SetPedComponentVariation(charPed, 0, 0, 0, 2)
        FreezeEntityPosition(charPed, false)
        SetEntityInvincible(charPed, true)
        PlaceObjectOnGroundProperly(charPed)
        SetBlockingOfNonTemporaryEvents(charPed, true)
        if data then
            -- Changed from qb-clothing to illenium-appearance
            exports['illenium-appearance']:setPedAppearance(charPed, data)  -- CHANGED LINE 46
        end
    end)
end
```

### Server File: `server/main.lua` (Callback Section - Lines 209-223)

```lua
-- illenium-appearance callback
-- This callback queries the 'playerskins' table (not 'players' table)
-- The 'playerskins' table is where illenium-appearance stores character appearance data
QBCore.Functions.CreateCallback("qb-multicharacter:server:getSkin", function(source, cb, cid)
    local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ?', {cid})
    if result[1] then
        local skinData = json.decode(result[1].skin)
        if skinData then
            cb(result[1].skin, skinData.model)
        else
            cb(nil)
        end
    else
        cb(nil)
    end
end)
```

---

## Dependencies

Make sure you have the following dependencies installed:

1. **illenium-appearance** - The appearance/clothing system
2. **qb-multicharacter** - The multi-character selection system
3. **ox_lib** - Required by illenium-appearance
4. **oxmysql** - Required for database operations

---

## Installation Steps

1. Install `illenium-appearance` and ensure it's working correctly
2. Locate your `qb-multicharacter` resource folder
3. Open `client/main.lua` and modify line 46 as described above
4. Open `server/main.lua` and verify lines 209-219 match the illenium-appearance version
5. Restart both resources:
   ```
   ensure illenium-appearance
   ensure qb-multicharacter
   ```

---

## Testing

After making these changes:

1. Log into your server
2. Go to character selection screen
3. Click on an existing character with saved appearance
4. Verify the character preview shows the correct clothing and appearance
5. Create a new character and verify appearance is saved correctly

---

## Troubleshooting

### Character preview not showing clothing
- Ensure `illenium-appearance` is started before `qb-multicharacter` in your server.cfg
- Check that the database table `playerskins` exists and has data
- Verify the export is being called correctly (check F8 console for errors)

### New characters not saving appearance
- Ensure you've replaced `qb-clothing` events throughout your server
- Check that character creation triggers the illenium-appearance menu
- Verify database permissions for the `playerskins` table

---

## Backward Compatibility

illenium-appearance includes several backward compatibility events for qb-clothing:

- `qb-clothing:client:openMenu` - Opens the appearance menu
- `qb-clothing:client:openOutfitMenu` - Opens the outfit menu
- `qb-clothing:client:loadOutfit` - Loads a job outfit
- `qb-clothes:client:CreateFirstCharacter` - Opens character creator for new characters

These events are automatically handled by illenium-appearance, so you don't need to change every reference in your resources.

---

## Additional Notes

- The example files in this directory already include the illenium-appearance integration
- You can use these files as a complete reference for your own qb-multicharacter installation
- Make sure to backup your files before making any changes
- If you're migrating from qb-clothing, run the migration script provided by illenium-appearance

---

## Support

For issues with:
- **illenium-appearance**: Visit https://discord.illenium.dev
- **qb-multicharacter**: Visit the QB-Core Discord
- **This integration**: Check the illenium-appearance documentation at https://docs.illenium.dev

---

## Credits

- illenium-appearance by iLLeniumStudios
- qb-multicharacter by QB-Core Framework
