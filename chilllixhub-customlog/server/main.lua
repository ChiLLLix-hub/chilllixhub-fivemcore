-- ─────────────────────────────────────────────────────────────────
--  chilllixhub-customlog  ·  server/main.lua
--
--  Handles:
--    1. playerConnect    – returning character loaded
--    2. playerDisconnect – player dropped
--    3. playerNew        – brand-new character created
--    4. playerDied       – player death (triggered from client)
--    5. jobChange        – job / grade changed
--
--  Discord messages are sent via webhook using Discord embeds.
--  Chat announcements use okokChat (if running) or native chat.
-- ─────────────────────────────────────────────────────────────────

local QBCore = exports['qb-core']:GetCoreObject()

-- Cache of each player's last-known job, used to detect job changes
-- and to include the previous job in the log entry.
local prevJobs = {}

-- Cache of basic player info (name / citizenid / license) populated
-- when a character finishes loading (QBCore:Server:PlayerLoaded).
-- Consumed by playerDropped so disconnect logs work after QBCore.Players
-- is already cleared.
local playerCache = {}

-- Flag set by the createCharacter handler so that the shared
-- QBCore:Server:PlayerLoaded handler knows whether to log as new or returning.
--
-- Why the ordering is guaranteed:
--   qb-multicharacter's createCharacter handler calls QBCore.Player.Login
--   which calls CheckPlayerData → LoadInventory → MySQL.prepare.await.
--   MySQL.prepare.await suspends qb-multicharacter's coroutine; the Lua
--   scheduler then runs our createCharacter handler coroutine, which sets
--   the flag.  PlayerLoaded can ONLY fire from inside CreatePlayer (called
--   by CheckPlayerData, inside qb-multicharacter's coroutine).  Since that
--   coroutine is suspended until MySQL returns, our flag is always set
--   before PlayerLoaded fires.
local pendingNewChars = {}

-- ── Helpers ──────────────────────────────────────────────────────

--- Return current date (YYYY-MM-DD) and time (HH:MM:SS) strings.
local function GetDateTime()
    return os.date('%Y-%m-%d'), os.date('%H:%M:%S')
end

--- Send one Discord embed to the webhook configured for `logType`.
--- @param logType  string  Key from Config.LogWebhooks
--- @param embed    table   A single Discord embed object
local function SendDiscordEmbed(logType, embed)
    local webhookKey = Config.LogWebhooks[logType]
    if not webhookKey then return end

    local url = Config.Webhooks[webhookKey]
    if not url or url == '' then
        print('^3[chilllixhub-customlog]^7 No webhook URL set for "' .. webhookKey .. '" (log type: ' .. logType .. '). Check config.lua.')
        return
    end

    local date, time = GetDateTime()
    embed.footer = { text = Config.ServerName .. '  •  ' .. date .. '  ' .. time }

    local payload = json.encode({
        username   = Config.BotName,
        avatar_url = Config.BotAvatar ~= '' and Config.BotAvatar or nil,
        embeds     = { embed },
    })

    PerformHttpRequest(url, function(statusCode, responseBody)
        if statusCode ~= 200 and statusCode ~= 204 then
            print('^1[chilllixhub-customlog]^7 Discord webhook error for "' .. logType .. '": HTTP ' .. tostring(statusCode) .. ' – ' .. tostring(responseBody))
        end
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

--- Broadcast a server announcement to all players.
--- Uses the standard FiveM chat:addMessage event.
--- okokChat (chillixhub_okok/okokChat) is a NUI replacement that registers
--- chat:addMessage on the client, so this call works correctly whether
--- okokChat is installed or the native chat is used.
--- @param message  string   Full message text
--- @param color    table    { R, G, B }
local function ChatAnnounce(message, color)
    TriggerClientEvent('chat:addMessage', -1, {
        color     = color,
        multiline = true,
        args      = { 'Server', message },
    })
end

--- Populate the player cache and job cache for a freshly-loaded player.
--- Returns a table of the key fields used by the log embeds.
--- @param src     number   Server source ID
--- @param Player  table    QBCore Player object
local function CachePlayer(src, Player)
    playerCache[src] = {
        name      = Player.PlayerData.name or 'Unknown',
        citizenid = Player.PlayerData.citizenid,
        license   = Player.PlayerData.license,
    }
    local job = Player.PlayerData.job
    prevJobs[src] = {
        name  = job.name,
        label = job.label,
        grade = { level = job.grade.level, name = job.grade.name },
    }
    return {
        name      = playerCache[src].name,
        citizenid = playerCache[src].citizenid,
        license   = playerCache[src].license,
        ip        = GetPlayerEndpoint(src) or 'Unknown',
    }
end

-- ── 1 & 3. playerConnect / playerNew ─────────────────────────────
--
--  WHY QBCore:Server:PlayerLoaded and NOT direct loadUserData/createCharacter handlers:
--
--  QBCore.Player.Login (called inside qb-multicharacter's handlers) uses
--  MySQL.prepare.await which suspends its coroutine. When it yields, our
--  handler coroutine starts. At that moment QBCore.Functions.GetPlayer(src)
--  returns nil because the DB query hasn't completed yet.
--
--  QBCore:Server:PlayerLoaded fires from inside CreatePlayer AFTER
--  QBCore.Players[src] has been set (player.lua line 420-422), so the
--  Player object is always available and correct.
--
--  For distinguishing new vs returning: our createCharacter handler only
--  needs to set a flag (no GetPlayer call). It runs in a separate coroutine
--  while qb-multicharacter's coroutine is suspended at MySQL, so the flag
--  is always set before PlayerLoaded fires.

-- Set the "new character" flag. Runs while qb-multicharacter's handler
-- is suspended at MySQL, so the flag is ready before PlayerLoaded fires.
RegisterNetEvent('qb-multicharacter:server:createCharacter', function()
    pendingNewChars[source] = true
end)

-- Fires after QBCore fully registers the player (new OR returning).
-- Player object is passed directly — no GetPlayer call needed.
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src   = Player.PlayerData.source
    local isNew = pendingNewChars[src]
    pendingNewChars[src] = nil

    local date, time = GetDateTime()
    local info = CachePlayer(src, Player)

    if isNew then
        -- ── 3. playerNew
        SendDiscordEmbed('playerNew', {
            title  = '🆕  New Citizen Arrived',
            color  = Config.Colors.playerNew,
            fields = {
                { name = 'Player Name',  value = info.name,      inline = true  },
                { name = 'Character ID', value = info.citizenid, inline = true  },
                { name = 'License',      value = info.license,   inline = false },
                { name = 'IP Address',   value = info.ip,        inline = true  }, -- Discord only; not in chat
                { name = 'Date',         value = date,           inline = true  },
                { name = 'Time',         value = time,           inline = true  },
            },
        })
        ChatAnnounce('New citizen has arrived. Welcome ' .. info.name .. '!', Config.ChatColors.playerNew)
    else
        -- ── 1. playerConnect (returning character)
        SendDiscordEmbed('playerConnect', {
            title  = '🟢  Player Connected',
            color  = Config.Colors.playerConnect,
            fields = {
                { name = 'Player Name',  value = info.name,      inline = true  },
                { name = 'Character ID', value = info.citizenid, inline = true  },
                { name = 'License',      value = info.license,   inline = false },
                { name = 'IP Address',   value = info.ip,        inline = true  }, -- Discord only; not in chat
                { name = 'Date',         value = date,           inline = true  },
                { name = 'Time',         value = time,           inline = true  },
            },
        })
        ChatAnnounce('Welcome back ' .. info.name .. '!', Config.ChatColors.playerConnect)
    end
end)

-- ── 2. playerDisconnect ──────────────────────────────────────────
--
--  playerCache is populated by QBCore:Server:PlayerLoaded above, so it
--  is always set by the time playerDropped fires.

AddEventHandler('playerDropped', function(reason)
    local src  = source
    local data = playerCache[src]
    if not data then return end          -- player never loaded a character
    playerCache[src] = nil
    prevJobs[src]    = nil

    local date, time = GetDateTime()

    SendDiscordEmbed('playerDisconnect', {
        title  = '🔴  Player Disconnected',
        color  = Config.Colors.playerDisconnect,
        fields = {
            { name = 'Player Name',  value = data.name,            inline = true  },
            { name = 'Character ID', value = data.citizenid,       inline = true  },
            { name = 'License',      value = data.license,         inline = false },
            { name = 'Reason',       value = reason or 'Unknown',  inline = false },
            { name = 'Date',         value = date,                 inline = true  },
            { name = 'Time',         value = time,                 inline = true  },
        },
    })
end)

-- ── 4. playerDied ────────────────────────────────────────────────
--
--  Triggered from client/main.lua (IsPedDeadOrDying polling).
--  External resources can also call:
--      TriggerServerEvent('chilllixhub-customlog:server:playerDied', cause)

RegisterNetEvent('chilllixhub-customlog:server:playerDied')
AddEventHandler('chilllixhub-customlog:server:playerDied', function(cause)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local date, time = GetDateTime()
    local name      = GetPlayerName(src) or 'Unknown'
    local citizenid = Player.PlayerData.citizenid

    SendDiscordEmbed('playerDied', {
        title  = '💀  Player Died',
        color  = Config.Colors.playerDied,
        fields = {
            { name = 'Player Name',    value = name,                inline = true  },
            { name = 'Character ID',   value = citizenid,           inline = true  },
            { name = 'Cause / Reason', value = cause or 'Unknown',  inline = false },
            { name = 'Date',           value = date,                inline = true  },
            { name = 'Time',           value = time,                inline = true  },
        },
    })
end)

-- ── 5. jobChange ─────────────────────────────────────────────────
--
--  QBCore fires QBCore:Server:OnJobUpdate for BOTH actual job changes
--  and on-duty toggles. We compare job name + grade level against the
--  cached previous value and only log real job changes.

AddEventHandler('QBCore:Server:OnJobUpdate', function(src, newJob)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local lastJob = prevJobs[src]

    if not lastJob then
        prevJobs[src] = {
            name  = newJob.name,
            label = newJob.label,
            grade = { level = newJob.grade.level, name = newJob.grade.name },
        }
        return
    end

    -- Duty-only toggle (same job, same grade) → skip
    if lastJob.name == newJob.name
    and lastJob.grade.level == newJob.grade.level then
        return
    end

    local date, time = GetDateTime()
    local name      = GetPlayerName(src) or 'Unknown'
    local citizenid = Player.PlayerData.citizenid

    SendDiscordEmbed('jobChange', {
        title  = '💼  Job Changed',
        color  = Config.Colors.jobChange,
        fields = {
            { name = 'Player Name',       value = name,                                              inline = true  },
            { name = 'Character ID',      value = citizenid,                                         inline = true  },
            { name = 'New Job',           value = newJob.label  or newJob.name,                      inline = true  },
            { name = 'New Job Rank',      value = newJob.grade  and newJob.grade.name  or 'Unknown', inline = true  },
            { name = 'Previous Job',      value = lastJob.label or lastJob.name,                     inline = true  },
            { name = 'Previous Job Rank', value = lastJob.grade and lastJob.grade.name or 'Unknown', inline = true  },
            { name = 'Date',              value = date,                                               inline = true  },
            { name = 'Time',              value = time,                                               inline = true  },
        },
    })

    prevJobs[src] = {
        name  = newJob.name,
        label = newJob.label,
        grade = { level = newJob.grade.level, name = newJob.grade.name },
    }
end)

-- Clean up job cache on logout. playerCache intentionally kept so that
-- the disconnect log still fires if the player quits from char select.
AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    prevJobs[src]        = nil
    pendingNewChars[src] = nil
end)

-- ── Dev / test commands ───────────────────────────────────────────
--
--  God-only commands to verify Discord webhooks and chat announcements
--  before live players trigger real events.
--
--  Usage:  /logplayerconnect   /logplayerdisconnect   /logplayernew
--          /logplayerdied      /logjobchange

QBCore.Commands.Add('logplayerconnect', '[TEST] Send a dummy playerConnect log to Discord', {}, false, function(src)
    local date, time = GetDateTime()
    SendDiscordEmbed('playerConnect', {
        title  = '🟢  Player Connected',
        color  = Config.Colors.playerConnect,
        fields = {
            { name = 'Player Name',  value = 'TestPlayer',           inline = true  },
            { name = 'Character ID', value = 'TEST001',              inline = true  },
            { name = 'License',      value = 'license:abc123def456', inline = false },
            { name = 'IP Address',   value = '203.0.113.1',          inline = true  },
            { name = 'Date',         value = date,                    inline = true  },
            { name = 'Time',         value = time,                    inline = true  },
        },
    })
    ChatAnnounce('Welcome back TestPlayer!', Config.ChatColors.playerConnect)
    TriggerClientEvent('QBCore:Notify', src, '[customlog] playerConnect test fired.', 'success')
end, 'god')

QBCore.Commands.Add('logplayerdisconnect', '[TEST] Send a dummy playerDisconnect log to Discord', {}, false, function(src)
    local date, time = GetDateTime()
    SendDiscordEmbed('playerDisconnect', {
        title  = '🔴  Player Disconnected',
        color  = Config.Colors.playerDisconnect,
        fields = {
            { name = 'Player Name',  value = 'TestPlayer',           inline = true  },
            { name = 'Character ID', value = 'TEST001',              inline = true  },
            { name = 'License',      value = 'license:abc123def456', inline = false },
            { name = 'Reason',       value = 'Disconnected.',        inline = false },
            { name = 'Date',         value = date,                    inline = true  },
            { name = 'Time',         value = time,                    inline = true  },
        },
    })
    TriggerClientEvent('QBCore:Notify', src, '[customlog] playerDisconnect test fired.', 'success')
end, 'god')

QBCore.Commands.Add('logplayernew', '[TEST] Send a dummy playerNew log to Discord', {}, false, function(src)
    local date, time = GetDateTime()
    SendDiscordEmbed('playerNew', {
        title  = '🆕  New Citizen Arrived',
        color  = Config.Colors.playerNew,
        fields = {
            { name = 'Player Name',  value = 'NewTestPlayer',        inline = true  },
            { name = 'Character ID', value = 'TEST002',              inline = true  },
            { name = 'License',      value = 'license:xyz789ghi012', inline = false },
            { name = 'IP Address',   value = '203.0.113.2',          inline = true  },
            { name = 'Date',         value = date,                    inline = true  },
            { name = 'Time',         value = time,                    inline = true  },
        },
    })
    ChatAnnounce('New citizen has arrived. Welcome NewTestPlayer!', Config.ChatColors.playerNew)
    TriggerClientEvent('QBCore:Notify', src, '[customlog] playerNew test fired.', 'success')
end, 'god')

QBCore.Commands.Add('logplayerdied', '[TEST] Send a dummy playerDied log to Discord', {}, false, function(src)
    local date, time = GetDateTime()
    SendDiscordEmbed('playerDied', {
        title  = '💀  Player Died',
        color  = Config.Colors.playerDied,
        fields = {
            { name = 'Player Name',    value = 'TestPlayer',                  inline = true  },
            { name = 'Character ID',   value = 'TEST001',                     inline = true  },
            { name = 'Cause / Reason', value = 'Killed by player: AdminTest', inline = false },
            { name = 'Date',           value = date,                           inline = true  },
            { name = 'Time',           value = time,                           inline = true  },
        },
    })
    TriggerClientEvent('QBCore:Notify', src, '[customlog] playerDied test fired.', 'success')
end, 'god')

QBCore.Commands.Add('logjobchange', '[TEST] Send a dummy jobChange log to Discord', {}, false, function(src)
    local date, time = GetDateTime()
    SendDiscordEmbed('jobChange', {
        title  = '💼  Job Changed',
        color  = Config.Colors.jobChange,
        fields = {
            { name = 'Player Name',       value = 'TestPlayer', inline = true  },
            { name = 'Character ID',      value = 'TEST001',    inline = true  },
            { name = 'New Job',           value = 'Police',     inline = true  },
            { name = 'New Job Rank',      value = 'Cadet',      inline = true  },
            { name = 'Previous Job',      value = 'Unemployed', inline = true  },
            { name = 'Previous Job Rank', value = 'Freelancer', inline = true  },
            { name = 'Date',              value = date,          inline = true  },
            { name = 'Time',              value = time,          inline = true  },
        },
    })
    TriggerClientEvent('QBCore:Notify', src, '[customlog] jobChange test fired.', 'success')
end, 'god')
