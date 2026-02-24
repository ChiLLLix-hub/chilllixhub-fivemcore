Config = {}

Config.ServerName = 'ChilLLix Hub'  -- Displayed in Discord embed footers
Config.BotName    = 'ChilLLix Logs' -- Discord bot username shown in webhook messages
Config.BotAvatar  = ''              -- Optional: direct image URL for the bot avatar

-- ─────────────────────────────────────────────────────────────────
--  DISCORD WEBHOOKS
--  Add as many named webhooks as you need.
--  Multiple log types can share the same webhook.
-- ─────────────────────────────────────────────────────────────────
Config.Webhooks = {
    -- Player connection / disconnection / new-citizen events
    playerActivity = '',

    -- Player death events
    playerDeath    = '',

    -- Job-change events
    jobActivity    = '',
}

-- ─────────────────────────────────────────────────────────────────
--  LOG → WEBHOOK MAPPING
--  Each log type must point to one key from Config.Webhooks above.
--  You can point several log types to the same webhook.
-- ─────────────────────────────────────────────────────────────────
Config.LogWebhooks = {
    playerConnect    = 'playerActivity',
    playerDisconnect = 'playerActivity',
    playerNew        = 'playerActivity',
    playerDied       = 'playerDeath',
    jobChange        = 'jobActivity',
}

-- ─────────────────────────────────────────────────────────────────
--  EMBED COLOURS  (decimal – https://www.spycolor.com/)
-- ─────────────────────────────────────────────────────────────────
Config.Colors = {
    playerConnect    = 5763719,   -- green
    playerDisconnect = 15548997,  -- red
    playerNew        = 16776960,  -- gold / yellow
    playerDied       = 10038562,  -- dark red
    jobChange        = 3447003,   -- blue
}

-- ─────────────────────────────────────────────────────────────────
--  OKOKCHAT CHAT COLOURS  { R, G, B }
-- ─────────────────────────────────────────────────────────────────
Config.ChatColors = {
    playerConnect = { 0, 255, 127 },   -- spring green
    playerNew     = { 255, 215, 0  },  -- gold
}
