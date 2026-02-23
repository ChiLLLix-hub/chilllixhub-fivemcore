# Quick Reference: Line Changes for illenium-appearance Integration

This is a quick reference guide showing exactly which lines to change in your qb-multicharacter files to integrate with illenium-appearance.

---

## Client File: `client/main.lua`

### ❌ OLD (Line 46) - Using qb-clothing:
```lua
TriggerEvent('qb-clothing:client:loadPlayerClothing', data, charPed)
```

### ✅ NEW (Line 46) - Using illenium-appearance:
```lua
exports['illenium-appearance']:setPedAppearance(charPed, data)
```

**Location:** Inside the `initializePedModel` function, within the `if data then` block

---

### ✅ Line 115 - No Change Needed:
```lua
TriggerEvent('qb-clothes:client:CreateFirstCharacter')
```

**Keep as is!** illenium-appearance has backward compatibility for this event.

---

## Server File: `server/main.lua`

The server file in this example **already has the correct code** for illenium-appearance (lines 209-223).

If your qb-multicharacter server file has the old qb-clothing callback, replace it with:

### ❌ OLD - qb-clothing version:
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

### ✅ NEW - illenium-appearance version (Lines 209-223):
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

**Note:** The key differences are:
1. **Correct Table:** Queries `playerskins` table (where illenium-appearance stores skins), not `players` table
2. Removed the `active` column check (illenium-appearance doesn't require filtering by active)
3. Added nil safety check to prevent crashes when no skin data exists
4. Returns the raw JSON string and model hash separately

---

## That's It!

You only need to change **1 line in the client file (line 46)** and verify the server callback is using the illenium-appearance version.

Most other qb-clothing events are automatically handled by illenium-appearance's backward compatibility layer!

For detailed explanations and troubleshooting, see [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
