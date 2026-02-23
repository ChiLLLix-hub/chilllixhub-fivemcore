local cam = nil
local charPed = nil
local loadScreenCheckState = false
local QBCore = exports['qb-core']:GetCoreObject()
local isTransitioning = false  -- Prevent overlapping transitions
local currentEmoteThread = nil -- Track emote thread for cleanup
local currentCharacterCid = nil -- Track currently selected character citizenid

local randommodels = { -- models possible to load when choosing empty slot
    'mp_m_freemode_01',
    'mp_f_freemode_01',
}

-- Main Thread

CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            TriggerEvent('qb-multicharacter:client:chooseChar')
            return
        end
    end
end)

-- Functions

local function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

local function playRandomEmote(ped)
    if not Config.EnableEmotes or not DoesEntityExist(ped) then
        return
    end
    
    -- Stop any existing emote thread
    if currentEmoteThread then
        currentEmoteThread = nil
    end
    
    -- Wait a moment before playing emote
    Wait(Config.EmoteDelay)
    
    -- Select random emote from config
    local emote = Config.AvailableEmotes[math.random(#Config.AvailableEmotes)]
    
    -- Load animation dictionary
    loadAnimDict(emote.dict)
    
    -- Play the emote
    TaskPlayAnim(ped, emote.dict, emote.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
end

local function stopEmote(ped)
    if DoesEntityExist(ped) then
        ClearPedTasks(ped)
    end
    if currentEmoteThread then
        currentEmoteThread = nil
    end
end

local function makeCharacterWalkIn(ped)
    -- Start character from walk-in position
    SetEntityCoords(ped, Config.WalkInCoords.x, Config.WalkInCoords.y, Config.WalkInCoords.z - 0.98)
    SetEntityHeading(ped, Config.WalkInCoords.w)
    FreezeEntityPosition(ped, false)
    
    -- Play walk animation
    loadAnimDict("move_m@confident")
    
    -- Make ped walk to display position using TaskGoStraightToCoord for direct path
    TaskGoStraightToCoord(ped, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.WalkSpeed, -1, Config.PedCoords.w, 0.0)
    
    -- Wait for ped to reach destination
    Wait(Config.WalkDuration)
    
    -- Stop movement, set final heading to face camera
    ClearPedTasks(ped)
    SetEntityHeading(ped, Config.PedCoords.w)
    FreezeEntityPosition(ped, false)
    
    -- Play random emote after character is in position
    if Config.EnableEmotes then
        currentEmoteThread = CreateThread(function()
            playRandomEmote(ped)
        end)
    end
end

local function makeCharacterRunOut(ped, callback)
    if not DoesEntityExist(ped) then
        if callback then callback() end
        return
    end
    
    CreateThread(function()
        -- Stop any emotes and clear animations
        stopEmote(ped)
        Wait(100) -- Small delay to ensure emote is cleared
        ClearPedTasks(ped)
        
        -- Unfreeze ped
        FreezeEntityPosition(ped, false)
        
        -- Make character run to walk-out position (outside camera)
        -- Using TaskGoStraightToCoord for direct path with running
        TaskGoStraightToCoord(ped, Config.WalkOutCoords.x, Config.WalkOutCoords.y, Config.WalkOutCoords.z, Config.RunSpeed, -1, 0.0, 0.0)
        
        -- Wait for run animation to complete, but check if ped is still valid
        local startTime = GetGameTimer()
        while DoesEntityExist(ped) and GetGameTimer() - startTime < Config.RunDuration + 500 do
            Wait(100)
        end
        
        -- Delete the ped after reaching walk-out position
        if DoesEntityExist(ped) then
            SetEntityAsMissionEntity(ped, true, true)
            DeleteEntity(ped)
        end
        
        if callback then callback() end
    end)
end

local function makeCharacterWalkOut(ped, callback)
    if not DoesEntityExist(ped) then
        if callback then callback() end
        return
    end
    
    CreateThread(function()
        -- Stop any emotes and clear animations
        stopEmote(ped)
        Wait(100) -- Small delay to ensure emote is cleared
        ClearPedTasks(ped)
        
        -- Unfreeze and make character walk away
        FreezeEntityPosition(ped, false)
        
        -- Walk to walk-out position (outside camera)
        TaskGoStraightToCoord(ped, Config.WalkOutCoords.x, Config.WalkOutCoords.y, Config.WalkOutCoords.z, Config.WalkSpeed, -1, 0.0, 0.0)
        
        -- Wait for walk animation to complete
        local startTime = GetGameTimer()
        while DoesEntityExist(ped) and GetGameTimer() - startTime < Config.WalkDuration + 500 do
            Wait(100)
        end
        
        -- Delete the ped after reaching walk-out position
        if DoesEntityExist(ped) then
            SetEntityAsMissionEntity(ped, true, true)
            DeleteEntity(ped)
        end
        
        if callback then callback() end
    end)
end

local function initializePedModel(model, data, skipWalkIn)
    CreateThread(function()
        if not model then
            model = joaat(randommodels[math.random(#randommodels)])
        end
        loadModel(model)
        
        if skipWalkIn then
            -- Create ped at display position without walk-in (local only, not visible to other players)
            charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.w, false, false)
        else
            -- Create ped at walk-in position (local only, not visible to other players)
            charPed = CreatePed(2, model, Config.WalkInCoords.x, Config.WalkInCoords.y, Config.WalkInCoords.z, Config.WalkInCoords.w, false, false)
        end
        
        SetPedComponentVariation(charPed, 0, 0, 0, 2)
        SetEntityInvincible(charPed, true)
        PlaceObjectOnGroundProperly(charPed)
        SetBlockingOfNonTemporaryEvents(charPed, true)
        
        if data then
            -- Changed from qb-clothing to illenium-appearance
            exports['illenium-appearance']:setPedAppearance(charPed, data)
        end
        
        -- Make character walk in if not skipped
        if not skipWalkIn then
            makeCharacterWalkIn(charPed)
        else
            FreezeEntityPosition(charPed, false)
        end
    end)
end

local function skyCam(bool)
    TriggerEvent('qb-weathersync:client:DisableSync')
    if bool then
        DoScreenFadeIn(1000)
        
        -- Apply purple post-processing effect if enabled
        if Config.EnablePostProcess then
            -- Clear any existing modifiers first
            ClearTimecycleModifier()
            
            -- Play ChopVision screen effect for purple tint
            AnimpostfxPlay("ChopVision", 0, true)
            
            -- Apply purple timecycle modifier
            SetTimecycleModifier("purple")
            SetTimecycleModifierStrength(Config.PostProcessStrength or 0.7)
        else
            SetTimecycleModifier('hud_def_blur')
            SetTimecycleModifierStrength(1.0)
        end
        
        FreezeEntityPosition(PlayerPedId(), false)
        cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', Config.CamCoords.x, Config.CamCoords.y, Config.CamCoords.z, 0.0, 0.0, Config.CamCoords.w, 60.00, false, 0)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 1, true, true)
    else
        -- Clear post-processing effect
        AnimpostfxStop("ChopVision")
        ClearTimecycleModifier()
        SetTimecycleModifier('default')
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        RenderScriptCams(false, false, 1, true, true)
        FreezeEntityPosition(PlayerPedId(), false)
    end
end

local function openCharMenu(bool)
    QBCore.Functions.TriggerCallback('qb-multicharacter:server:GetNumberOfCharacters', function(result, countries)
        local translations = {}
        for k in pairs(Lang.fallback and Lang.fallback.phrases or Lang.phrases) do
            if k:sub(0, ('ui.'):len()) then
                translations[k:sub(('ui.'):len() + 1)] = Lang:t(k)
            end
        end
        SetNuiFocus(bool, bool)
        SendNUIMessage({
            action = 'ui',
            customNationality = Config.customNationality,
            toggle = bool,
            nChar = result,
            enableDeleteButton = Config.EnableDeleteButton,
            translations = translations,
            countries = countries,
        })
        skyCam(bool)
        if not loadScreenCheckState then
            ShutdownLoadingScreenNui()
            loadScreenCheckState = true
        end
    end)
end

-- Events

RegisterNetEvent('qb-multicharacter:client:closeNUIdefault', function() -- This event is only for no starting apartments
    DeleteEntity(charPed)
    SetNuiFocus(false, false)
    DoScreenFadeOut(500)
    Wait(2000)
    SetEntityCoords(PlayerPedId(), Config.DefaultSpawn.x, Config.DefaultSpawn.y, Config.DefaultSpawn.z)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    Wait(500)
    openCharMenu()
    SetEntityVisible(PlayerPedId(), true)
    Wait(500)
    DoScreenFadeIn(250)
    TriggerEvent('qb-weathersync:client:EnableSync')
    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
end)

RegisterNetEvent('qb-multicharacter:client:closeNUI', function()
    DeleteEntity(charPed)
    SetNuiFocus(false, false)
end)

RegisterNetEvent('qb-multicharacter:client:chooseChar', function()
    SetNuiFocus(false, false)
    DoScreenFadeOut(10)
    Wait(1000)
    
    -- Load required IPLs if configured (for custom interiors like Vanilla Unicorn)
    if Config.RequiredIPLs and type(Config.RequiredIPLs) == "table" then
        for _, ipl in ipairs(Config.RequiredIPLs) do
            RequestIpl(ipl)
        end
    end
    
    -- Request collision for the area to ensure environment loads
    RequestCollisionAtCoord(Config.Interior.x, Config.Interior.y, Config.Interior.z)
    
    -- Load interior if exists
    local interior = GetInteriorAtCoords(Config.Interior.x, Config.Interior.y, Config.Interior.z - 18.9)
    if interior ~= 0 then
        LoadInterior(interior)
        while not IsInteriorReady(interior) do
            Wait(100)
        end
    end
    
    -- Ensure collision is loaded before proceeding
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) do
        RequestCollisionAtCoord(Config.Interior.x, Config.Interior.y, Config.Interior.z)
        Wait(100)
    end
    
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityCoords(PlayerPedId(), Config.HiddenCoords.x, Config.HiddenCoords.y, Config.HiddenCoords.z)
    Wait(1500)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    openCharMenu(true)
end)

RegisterNetEvent('qb-multicharacter:client:spawnLastLocation', function(coords, cData)
    QBCore.Functions.TriggerCallback('apartments:GetOwnedApartment', function(result)
        if result then
            TriggerEvent('apartments:client:SetHomeBlip', result.type)
            local ped = PlayerPedId()
            SetEntityCoords(ped, coords.x, coords.y, coords.z)
            SetEntityHeading(ped, coords.w)
            FreezeEntityPosition(ped, false)
            SetEntityVisible(ped, true)
            local PlayerData = QBCore.Functions.GetPlayerData()
            local insideMeta = PlayerData.metadata['inside']
            DoScreenFadeOut(500)

            if insideMeta.house then
                TriggerEvent('qb-houses:client:LastLocationHouse', insideMeta.house)
            elseif insideMeta.apartment.apartmentType and insideMeta.apartment.apartmentId then
                TriggerEvent('qb-apartments:client:LastLocationHouse', insideMeta.apartment.apartmentType, insideMeta.apartment.apartmentId)
            else
                SetEntityCoords(ped, coords.x, coords.y, coords.z)
                SetEntityHeading(ped, coords.w)
                FreezeEntityPosition(ped, false)
                SetEntityVisible(ped, true)
            end

            TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
            TriggerEvent('QBCore:Client:OnPlayerLoaded')
            Wait(2000)
            DoScreenFadeIn(250)
        end
    end, cData.citizenid)
end)

-- NUI Callbacks

RegisterNUICallback('closeUI', function(_, cb)
    local cData = data.cData
    DoScreenFadeOut(10)
    TriggerServerEvent('qb-multicharacter:server:loadUserData', cData)
    openCharMenu(false)
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    if Config.SkipSelection then
        SetNuiFocus(false, false)
        skyCam(false)
    else
        openCharMenu(false)
    end
    cb('ok')
end)

RegisterNUICallback('disconnectButton', function(_, cb)
    stopEmote(charPed)
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    TriggerServerEvent('qb-multicharacter:server:disconnect')
    cb('ok')
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    local cData = data.cData
    stopEmote(charPed)
    DoScreenFadeOut(500) -- Increased from 10ms to 500ms for smoother transition
    Wait(100) -- Small wait to ensure fade starts
    TriggerServerEvent('qb-multicharacter:server:loadUserData', cData)
    openCharMenu(false)
    -- Clean up character selection ped
    if DoesEntityExist(charPed) then
        SetEntityAsMissionEntity(charPed, true, true)
        DeleteEntity(charPed)
        charPed = nil
        currentCharacterCid = nil
    end
    cb('ok')
end)

RegisterNUICallback('cDataPed', function(nData, cb)
    local cData = nData.cData
    
    -- Get citizenid from character data
    local selectedCid = cData and cData.citizenid or nil
    
    -- Prevent selecting the same character that's already displayed
    if selectedCid and currentCharacterCid == selectedCid and DoesEntityExist(charPed) then
        cb("ok")
        return
    end
    
    -- Prevent overlapping transitions (character still spawning/walking/running)
    if isTransitioning then
        cb("ok")
        return
    end
    
    if DoesEntityExist(charPed) then
        isTransitioning = true
        currentCharacterCid = nil -- Clear current character during transition
        
        -- Store old ped reference
        local oldPed = charPed
        charPed = nil
        
        -- Load new character model FIRST, then start BOTH animations simultaneously
        if cData ~= nil then
            QBCore.Functions.TriggerCallback('qb-multicharacter:server:getSkin', function(skinData)
                if skinData then
                    local model = joaat(skinData.model)
                    CreateThread(function()
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Wait(0)
                        end
                        
                        -- NOW start run-out (when new model is ready)
                        makeCharacterRunOut(oldPed, nil)
                        
                        -- IMMEDIATELY create and walk-in new character (simultaneous)
                        charPed = CreatePed(2, model, Config.WalkInCoords.x, Config.WalkInCoords.y, Config.WalkInCoords.z, Config.WalkInCoords.w, false, false)
                        SetPedComponentVariation(charPed, 0, 0, 0, 2)
                        SetEntityInvincible(charPed, true)
                        PlaceObjectOnGroundProperly(charPed)
                        SetBlockingOfNonTemporaryEvents(charPed, true)
                        exports['illenium-appearance']:setPedAppearance(charPed, skinData)
                        
                        -- Make character walk in and play emote (runs parallel to run-out)
                        makeCharacterWalkIn(charPed)
                        
                        -- Set current character and unlock after walk-in completes
                        Wait(Config.WalkDuration + 100) -- Wait for walk-in + small buffer
                        currentCharacterCid = selectedCid
                        isTransitioning = false
                    end)
                else
                    CreateThread(function()
                        local randommodels = {
                            "mp_f_freemode_01",
                        }
                        local model = joaat(randommodels[math.random(1, #randommodels)])
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Wait(0)
                        end
                        
                        -- NOW start run-out (when new model is ready)
                        makeCharacterRunOut(oldPed, nil)
                        
                        -- IMMEDIATELY create and walk-in new character (simultaneous)
                        charPed = CreatePed(2, model, Config.WalkInCoords.x, Config.WalkInCoords.y, Config.WalkInCoords.z, Config.WalkInCoords.w, false, false)
                        SetPedComponentVariation(charPed, 0, 0, 0, 2)
                        SetEntityInvincible(charPed, true)
                        PlaceObjectOnGroundProperly(charPed)
                        SetBlockingOfNonTemporaryEvents(charPed, true)
                        
                        -- Make character walk in and play emote (runs parallel to run-out)
                        makeCharacterWalkIn(charPed)
                        
                        -- Set current character and unlock after walk-in completes
                        Wait(Config.WalkDuration + 100) -- Wait for walk-in + small buffer
                        currentCharacterCid = selectedCid
                        isTransitioning = false
                    end)
                end
                cb("ok")
            end, cData.citizenid)
        else
            CreateThread(function()
                local randommodels = {
                    "mp_m_freemode_01",
                    "mp_f_freemode_01",
                }
                local model = joaat(randommodels[math.random(1, #randommodels)])
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(0)
                end
                
                -- NOW start run-out (when new model is ready)
                makeCharacterRunOut(oldPed, nil)
                
                -- IMMEDIATELY create and walk-in new character (simultaneous)
                charPed = CreatePed(2, model, Config.WalkInCoords.x, Config.WalkInCoords.y, Config.WalkInCoords.z, Config.WalkInCoords.w, false, false)
                SetPedComponentVariation(charPed, 0, 0, 0, 2)
                SetEntityInvincible(charPed, true)
                PlaceObjectOnGroundProperly(charPed)
                SetBlockingOfNonTemporaryEvents(charPed, true)
                
                -- Make character walk in and play emote (runs parallel to run-out)
                makeCharacterWalkIn(charPed)
                
                -- Set current character and unlock after walk-in completes
                Wait(Config.WalkDuration + 100) -- Wait for walk-in + small buffer
                currentCharacterCid = selectedCid
                isTransitioning = false
            end)
            cb("ok")
        end
    else
        -- No existing ped, create new one directly
        isTransitioning = true -- Lock during first character walk-in
        
        if cData ~= nil then
            QBCore.Functions.TriggerCallback('qb-multicharacter:server:getSkin', function(skinData)
                if skinData then
                    local model = joaat(skinData.model)
                    CreateThread(function()
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Wait(0)
                        end
                        charPed = CreatePed(2, model, Config.WalkInCoords.x, Config.WalkInCoords.y, Config.WalkInCoords.z, Config.WalkInCoords.w, false, false)
                        SetPedComponentVariation(charPed, 0, 0, 0, 2)
                        SetEntityInvincible(charPed, true)
                        PlaceObjectOnGroundProperly(charPed)
                        SetBlockingOfNonTemporaryEvents(charPed, true)
                        exports['illenium-appearance']:setPedAppearance(charPed, skinData)
                        
                        -- Make character walk in
                        makeCharacterWalkIn(charPed)
                        
                        -- Set current character and unlock after walk-in completes
                        Wait(Config.WalkDuration + 100) -- Wait for walk-in + small buffer
                        currentCharacterCid = selectedCid
                        isTransitioning = false
                    end)
                else
                    CreateThread(function()
                        local randommodels = {
                            "mp_f_freemode_01",
                        }
                        local model = joaat(randommodels[math.random(1, #randommodels)])
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Wait(0)
                        end
                        charPed = CreatePed(2, model, Config.WalkInCoords.x, Config.WalkInCoords.y, Config.WalkInCoords.z, Config.WalkInCoords.w, false, false)
                        SetPedComponentVariation(charPed, 0, 0, 0, 2)
                        SetEntityInvincible(charPed, true)
                        PlaceObjectOnGroundProperly(charPed)
                        SetBlockingOfNonTemporaryEvents(charPed, true)
                        
                        -- Make character walk in
                        makeCharacterWalkIn(charPed)
                        
                        -- Set current character and unlock after walk-in completes
                        Wait(Config.WalkDuration + 100) -- Wait for walk-in + small buffer
                        currentCharacterCid = selectedCid
                        isTransitioning = false
                    end)
                end
                cb("ok")
            end, cData.citizenid)
        else
            CreateThread(function()
                local randommodels = {
                    "mp_m_freemode_01",
                    "mp_f_freemode_01",
                }
                local model = joaat(randommodels[math.random(1, #randommodels)])
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(0)
                end
                charPed = CreatePed(2, model, Config.WalkInCoords.x, Config.WalkInCoords.y, Config.WalkInCoords.z, Config.WalkInCoords.w, false, false)
                SetPedComponentVariation(charPed, 0, 0, 0, 2)
                SetEntityInvincible(charPed, true)
                PlaceObjectOnGroundProperly(charPed)
                SetBlockingOfNonTemporaryEvents(charPed, true)
                
                -- Make character walk in
                makeCharacterWalkIn(charPed)
                
                -- Set current character and unlock after walk-in completes
                Wait(Config.WalkDuration + 100) -- Wait for walk-in + small buffer
                currentCharacterCid = selectedCid
                isTransitioning = false
            end)
            cb("ok")
        end
    end
end)

RegisterNUICallback('setupCharacters', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-multicharacter:server:setupCharacters', function(result)
        cached_player_skins = {}
        SendNUIMessage({
            action = 'setupCharacters',
            characters = result
        })
        cb('ok')
    end)
end)

RegisterNUICallback('removeBlur', function(_, cb)
    ClearTimecycleModifier()
    SetTimecycleModifier('default')
    cb('ok')
end)

RegisterNUICallback('createNewCharacter', function(data, cb)
    local cData = data
    DoScreenFadeOut(150)
    if cData.gender == Lang:t('ui.male') then
        cData.gender = 0
    elseif cData.gender == Lang:t('ui.female') then
        cData.gender = 1
    end
    TriggerServerEvent('qb-multicharacter:server:createCharacter', cData)
    Wait(500)
    cb('ok')
end)

RegisterNUICallback('removeCharacter', function(data, cb)
    TriggerServerEvent('qb-multicharacter:server:deleteCharacter', data.citizenid)
    DeletePed(charPed)
    TriggerEvent('qb-multicharacter:client:chooseChar')
    cb('ok')
end)

-- ============================================================================
-- TEST COMMANDS - For visual testing of character selection animations
-- These commands simulate selecting characters to understand the complete flow:
-- spawn → walk-in → emote → run-out → despawn
-- Easy to remove: Delete this entire section when testing is complete
-- ============================================================================

--[[ Test function to simulate character selection
local function testCharacterSelection(pedModel, characterName)
    print("[TEST] Simulating selection of " .. characterName)
    
    -- Prevent overlapping during testing
    if isTransitioning then
        print("[TEST] Already transitioning, please wait...")
        return
    end
    
    -- If a character exists, run it out simultaneously with new character walking in
    if DoesEntityExist(charPed) then
        print("[TEST] Character exists - starting SIMULTANEOUS run-out and walk-in...")
        isTransitioning = true
        currentCharacterCid = nil
        
        -- Store old ped reference and clear charPed
        local oldPed = charPed
        charPed = nil
        
        -- Start run-out in background (no callback - runs independently)
        print("[TEST] Running out current character (background thread)...")
        makeCharacterRunOut(oldPed, nil)
        
        -- IMMEDIATELY spawn new character (simultaneous with run-out)
        print("[TEST] Spawning new character SIMULTANEOUSLY...")
        CreateThread(function()
            local model = joaat(pedModel)
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(0)
            end
            
            print("[TEST] Creating ped at walk-in position: " .. Config.WalkInCoords.x .. ", " .. Config.WalkInCoords.y .. ", " .. Config.WalkInCoords.z)
            charPed = CreatePed(2, model, Config.WalkInCoords.x, Config.WalkInCoords.y, Config.WalkInCoords.z, Config.WalkInCoords.w, false, false)
            SetPedComponentVariation(charPed, 0, 0, 0, 2)
            SetEntityInvincible(charPed, true)
            PlaceObjectOnGroundProperly(charPed)
            SetBlockingOfNonTemporaryEvents(charPed, true)
            
            print("[TEST] Starting walk-in animation (runs parallel to run-out)...")
            makeCharacterWalkIn(charPed)
            
            -- Wait for walk-in to complete
            Wait(Config.WalkDuration + 100)
            currentCharacterCid = characterName
            isTransitioning = false
            print("[TEST] " .. characterName .. " is now in preview position, playing emote")
        end)
    else
        -- No existing character, just spawn directly
        print("[TEST] No existing character, spawning directly...")
        CreateThread(function()
            isTransitioning = true
            local model = joaat(pedModel)
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(0)
            end
            
            print("[TEST] Creating ped at walk-in position: " .. Config.WalkInCoords.x .. ", " .. Config.WalkInCoords.y .. ", " .. Config.WalkInCoords.z)
            charPed = CreatePed(2, model, Config.WalkInCoords.x, Config.WalkInCoords.y, Config.WalkInCoords.z, Config.WalkInCoords.w, false, false)
            SetPedComponentVariation(charPed, 0, 0, 0, 2)
            SetEntityInvincible(charPed, true)
            PlaceObjectOnGroundProperly(charPed)
            SetBlockingOfNonTemporaryEvents(charPed, true)
            
            print("[TEST] Starting walk-in animation...")
            makeCharacterWalkIn(charPed)
            
            -- Wait for walk-in to complete
            Wait(Config.WalkDuration + 100)
            currentCharacterCid = characterName
            isTransitioning = false
            print("[TEST] " .. characterName .. " is now in preview position, playing emote")
        end)
    end
end

-- Command: /charac1 - Simulates selecting Character 1 (Male)
RegisterCommand('charac1', function()
    print("========================================")
    print("[TEST COMMAND] Simulating Character 1 Selection")
    print("[TEST] Using model: a_m_m_business_01 (Business Male)")
    print("========================================")
    testCharacterSelection('a_m_m_business_01', 'Character 1')
end, false)

-- Command: /charac2 - Simulates selecting Character 2 (Female)
RegisterCommand('charac2', function()
    print("========================================")
    print("[TEST COMMAND] Simulating Character 2 Selection")
    print("[TEST] Using model: a_f_y_business_01 (Business Female)")
    print("========================================")
    testCharacterSelection('a_f_y_business_01', 'Character 2')
end, false)

-- Command: /testcleanup - Clean up test character
RegisterCommand('testcleanup', function()
    print("[TEST] Cleaning up test character...")
    if DoesEntityExist(charPed) then
        stopEmote(charPed)
        SetEntityAsMissionEntity(charPed, true, true)
        DeleteEntity(charPed)
        charPed = nil
        currentCharacterCid = nil
        isTransitioning = false
        print("[TEST] Cleanup complete")
    else
        print("[TEST] No character to clean up")
    end
end, false)

print("^2[qb-multicharacter] Test commands loaded:^0")
print("^3  /charac1^0 - Simulate selecting Character 1 (Business Male)")
print("^3  /charac2^0 - Simulate selecting Character 2 (Business Female)")
print("^3  /testcleanup^0 - Clean up test character")
print("^1Note: These commands are for testing only. Remove this section from main.lua when done.^0") --]]

-- ============================================================================
-- END OF TEST COMMANDS SECTION
-- ============================================================================
