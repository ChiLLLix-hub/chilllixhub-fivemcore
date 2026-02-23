# Visual Integration Flow

## Character Selection Flow with illenium-appearance

```
┌─────────────────────────────────────────────────────────────────┐
│                    qb-multicharacter Flow                        │
└─────────────────────────────────────────────────────────────────┘

1. Player Opens Character Selection
   ↓
2. qb-multicharacter:client:chooseChar
   ↓
3. setupCharacters (loads character list)
   ↓
4. cDataPed (when hovering over character)
   │
   ├─→ Server: qb-multicharacter:server:getSkin
   │   │
   │   ├─→ Query: SELECT * FROM playerskins WHERE citizenid = ?
   │   │
   │   └─→ Returns: json.decode(skin), model
   │
   └─→ Client: initializePedModel(model, data)
       │
       └─→ exports['illenium-appearance']:setPedAppearance(charPed, data)
           └─→ Applies appearance to preview ped ✓

5. Player Selects Character
   ↓
6. selectCharacter → loadUserData
   ↓
7. Player Spawns
   ↓
8. illenium-appearance automatically loads character appearance
```

---

## Integration Points

### Client-Side (client/main.lua)

```lua
Line 46: Character Preview
┌──────────────────────────────────────────────────┐
│ Function: initializePedModel(model, data)       │
│                                                  │
│ OLD: TriggerEvent('qb-clothing:...')           │
│ NEW: exports['illenium-appearance']:setPed...  │
│                                                  │
│ Purpose: Shows character clothing in preview    │
└──────────────────────────────────────────────────┘

Line 115: New Character Creation
┌──────────────────────────────────────────────────┐
│ Event: qb-multicharacter:client:closeNUIdefault │
│                                                  │
│ TriggerEvent('qb-clothes:client:CreateFirst...')│
│                                                  │
│ Status: No change needed ✓                      │
│ Reason: Backward compatibility in illenium      │
└──────────────────────────────────────────────────┘
```

### Server-Side (server/main.lua)

```lua
Lines 209-223: Get Character Appearance
┌──────────────────────────────────────────────────┐
│ Callback: qb-multicharacter:server:getSkin      │
│                                                  │
│ Database Table: playerskins (NOT players)       │
│                                                  │
│ 1. Query playerskins table for citizenid        │
│ 2. Check if result exists (nil safety)          │
│ 3. Decode JSON skin data                        │
│ 4. Return: (result[1].skin, skinData.model)    │
│                                                  │
│ Status: Correct in example ✓                    │
└──────────────────────────────────────────────────┘
```

**Important:** The `playerskins` table stores character appearance data. The `players` table stores general character information (name, money, job, etc.). These are separate tables!

---

## Data Flow Diagram

```
┌─────────────┐
│  Database   │
│  playerskins│
└──────┬──────┘
       │
       │ SELECT * FROM playerskins WHERE citizenid = ?
       ↓
┌──────────────────────┐
│  Server Callback     │
│  getSkin()           │
│                      │
│  Decodes JSON        │
│  Returns appearance  │
└──────┬───────────────┘
       │
       │ cb(skinData, skinData.model)
       ↓
┌────────────────────────────────┐
│  Client NUI Callback           │
│  cDataPed                      │
│                                │
│  cached_player_skins[cid] =    │
│    { model: model, data: data }│
└──────┬─────────────────────────┘
       │
       │ initializePedModel(model, data)
       ↓
┌────────────────────────────────────────────────┐
│  illenium-appearance Export                    │
│  setPedAppearance(charPed, data)              │
│                                                │
│  Applies to preview ped:                       │
│  - Components (clothing)                       │
│  - Props (accessories)                         │
│  - Head blend (face)                           │
│  - Face features                               │
│  - Head overlays (makeup, beard, etc.)        │
│  - Hair & color                                │
│  - Eye color                                   │
│  - Tattoos                                     │
└────────────────────────────────────────────────┘
```

---

## Comparison: qb-clothing vs illenium-appearance

### qb-clothing Method
```lua
-- Uses an event
TriggerEvent('qb-clothing:client:loadPlayerClothing', data, charPed)

-- Limited to what the event handles
-- No direct control over the ped
```

### illenium-appearance Method
```lua
-- Uses an export (more reliable)
exports['illenium-appearance']:setPedAppearance(charPed, data)

-- Full appearance system
-- Direct ped control
-- Better performance
```

---

## Benefits of illenium-appearance

✓ **Modern UI** - Uses ox_lib for a better user experience
✓ **More Features** - Tattoos, hair textures, makeup colors, etc.
✓ **Better Performance** - Optimized appearance application
✓ **Backward Compatible** - Works with existing qb-clothing events
✓ **Export System** - More reliable than event-based systems
✓ **Active Development** - Regular updates and bug fixes

---

## Testing Your Integration

### Step 1: Check Character Preview
1. Open character selection
2. Hover over existing character
3. Verify clothing appears correctly
4. Check that tattoos, makeup, etc. display

### Step 2: Test New Character
1. Click "Create New Character"
2. Verify appearance menu opens
3. Create character with custom appearance
4. Return to selection screen
5. Verify new character shows correct preview

### Step 3: Test Character Loading
1. Select a character
2. Spawn into the game
3. Verify all appearance features loaded
4. Check /reloadskin command works

---

## Common Issues and Solutions

### Issue: Character preview shows default ped
**Solution:** 
- Check illenium-appearance is started before qb-multicharacter
- Verify line 46 change was made correctly
- Check database has skin data for the character

### Issue: New characters can't customize appearance
**Solution:**
- Verify illenium-appearance is installed
- Check that events are not conflicting with qb-clothing
- Remove qb-clothing if still installed

### Issue: Appearance doesn't save
**Solution:**
- Check playerskins table exists in database
- Verify database permissions
- Check server console for errors

---

For detailed troubleshooting, see [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
For quick line changes, see [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
