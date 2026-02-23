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
--  Chat announcements use okokChat client events.
-- ─────────────────────────────────────────────────────────────────

local QBCore = exports['qb-core']:GetCoreObject()

-- Cache of each player's last-known job, used to detect job changes
-- and to include the previous job in the log entry.
local prevJobs = {}

-- Temporary cache of player data for the disconnect log.
-- QBCore clears QBCore.Players[src] at the END of its own playerDropped
-- handler (which runs before ours because qb-core starts first).
-- We capture the data we need inside QBCore:Server:PlayerDropped, which
-- fires BEFORE the player entry is removed from QBCore.Players.
local pendingDisconnects = {}

-- Tracks which source IDs are loading a brand-new character so that
-- QBCore:Server:PlayerLoaded can send the correct log and chat message.
-- We hook qb-multicharacter:server:createCharacter with RegisterNetEvent
-- (required so that `source` is the real player server ID, not 0).
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

--- Broadcast a server announcement in okokChat.
--- Falls back silently if okokChat is not running.
--- @param message  string   Full message text
--- @param color    table    { R, G, B }
local function ChatAnnounce(message, color)
    if GetResourceState('okokChat') ~= 'started' then return end
    TriggerClientEvent('okokChat:client:addMessage', -1, {
        color     = color,
        multiline = true,
        args      = { 'Server', message },
    })
end

-- ── 1 & 3. playerConnect / playerNew ─────────────────────────────
--
--  Problem with the previous approach:
--    AddEventHandler on a net event registered by ANOTHER resource
--    causes `source` to be 0 instead of the real player server ID.
--    QBCore.Functions.GetPlayer(0) always returns nil, so the poll
--    loop timed out silently and no log was ever sent.
--
--  Fix:
--    * Use QBCore:Server:PlayerLoaded (a plain server→server TriggerEvent,
--      no net-event issues) — it passes the fully-loaded Player object
--      directly, no polling needed.
--    * Flag new characters via RegisterNetEvent on createCharacter
--      (so `source` IS the real player server ID in our resource).

-- Mark which source IDs are loading a brand-new character.
-- RegisterNetEvent is required so that `source` is the real player
-- server ID and not 0 when the handler fires in our resource.
RegisterNetEvent('qb-multicharacter:server:createCharacter', function()
    pendingNewChars[source] = true
end)

-- Fires after QBCore finishes loading the player (new OR returning).
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src       = Player.PlayerData.source
    local isNew     = pendingNewChars[src]
    pendingNewChars[src] = nil  -- clean up flag

    local date, time = GetDateTime()
    local name      = Player.PlayerData.name or 'Unknown'
    local citizenid = Player.PlayerData.citizenid
    local license   = Player.PlayerData.license
    local ip        = GetPlayerEndpoint(src) or 'Unknown'

    if isNew then
        -- ── 3. playerNew
        SendDiscordEmbed('playerNew', {
            title  = '🆕  New Citizen Arrived',
            color  = Config.Colors.playerNew,
            fields = {
                { name = 'Player Name',  value = name,       inline = true  },
                { name = 'Character ID', value = citizenid,  inline = true  },
                { name = 'License',      value = license,    inline = false },
                { name = 'IP Address',   value = ip,         inline = true  },
                { name = 'Date',         value = date,       inline = true  },
                { name = 'Time',         value = time,       inline = true  },
            },
        })
        ChatAnnounce('New citizen has arrived. Welcome ' .. name .. '!', Config.ChatColors.playerNew)
    else
        -- ── 1. playerConnect (returning character)
        SendDiscordEmbed('playerConnect', {
            title  = '🟢  Player Connected',
            color  = Config.Colors.playerConnect,
            fields = {
                { name = 'Player Name',  value = name,       inline = true  },
                { name = 'Character ID', value = citizenid,  inline = true  },
                { name = 'License',      value = license,    inline = false },
                { name = 'IP Address',   value = ip,         inline = true  },
                { name = 'Date',         value = date,       inline = true  },
                { name = 'Time',         value = time,       inline = true  },
            },
        })
        ChatAnnounce('Welcome back ' .. name .. '!', Config.ChatColors.playerConnect)
    end

    -- Seed the job cache so the first job-change event has a previous job to compare against.
    local job = Player.PlayerData.job
    prevJobs[src] = {
        name  = job.name,
        label = job.label,
        grade = { level = job.grade.level, name = job.grade.name },
    }
end)

-- ── 2. playerDisconnect ──────────────────────────────────────────
--
--  QBCore fires QBCore:Server:PlayerDropped INSIDE its own playerDropped
--  handler (before it nils out QBCore.Players[src]).  We save what we
--  need there, then read it in the native playerDropped handler where
--  the disconnect `reason` string is available.

AddEventHandler('QBCore:Server:PlayerDropped', function(Player)
    local src = Player.PlayerData.source
    pendingDisconnects[src] = {
        name      = Player.PlayerData.name,
        citizenid = Player.PlayerData.citizenid,
        license   = Player.PlayerData.license,
    }
    prevJobs[src] = nil
end)

AddEventHandler('playerDropped', function(reason)
    local src  = source
    local data = pendingDisconnects[src]
    if not data then return end          -- player had no character loaded
    pendingDisconnects[src] = nil

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
--  Triggered from client/main.lua when the QBCore `isdead` metadata
--  transitions to true.  External resources (e.g. qb-ambulancejob)
--  can also call:
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
--  and on-duty toggles.  We compare the new job name + grade level
--  against the cached previous value and only log real job changes.
--  The job cache is now seeded inside QBCore:Server:PlayerLoaded above.

AddEventHandler('QBCore:Server:OnJobUpdate', function(src, newJob)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local lastJob = prevJobs[src]

    -- If we have no cached data yet, just store and move on
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

    -- Real job change – log it
    local date, time = GetDateTime()
    local name      = GetPlayerName(src) or 'Unknown'
    local citizenid = Player.PlayerData.citizenid

    SendDiscordEmbed('jobChange', {
        title  = '💼  Job Changed',
        color  = Config.Colors.jobChange,
        fields = {
            { name = 'Player Name',       value = name,                                          inline = true  },
            { name = 'Character ID',      value = citizenid,                                     inline = true  },
            { name = 'New Job',           value = newJob.label  or newJob.name,                  inline = true  },
            { name = 'New Job Rank',      value = newJob.grade  and newJob.grade.name  or 'Unknown', inline = true  },
            { name = 'Previous Job',      value = lastJob.label or lastJob.name,                 inline = true  },
            { name = 'Previous Job Rank', value = lastJob.grade and lastJob.grade.name or 'Unknown', inline = true  },
            { name = 'Date',              value = date,                                          inline = true  },
            { name = 'Time',              value = time,                                          inline = true  },
        },
    })

    -- Update cache
    prevJobs[src] = {
        name  = newJob.name,
        label = newJob.label,
        grade = { level = newJob.grade.level, name = newJob.grade.name },
    }
end)

-- Clean up on player unload
AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    prevJobs[src] = nil
    pendingNewChars[src] = nil
end)
