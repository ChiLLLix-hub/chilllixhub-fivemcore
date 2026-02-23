Config = {}
Config.Interior = vector3(-763.35, 331.32, 199.49)            -- Interior to load where characters are previewed
Config.DefaultSpawn = vector3(-1037.65, -2738.19, 20.17)             -- Default spawn coords if you have start apartments disabled
Config.PedCoords = vector4(-848.58, -67.17, 37.84, 200.56)--vector4(-763.35, 331.32, 199.49, 182.87)   -- Create preview ped at these coordinates
Config.HiddenCoords = vector4(-858.96, -55.22, 37.93, 292.78) -- Hides your actual ped while you are in selection
Config.CamCoords = vector4(-847.89, -68.85, 37.8, 28.58)--vector4(-763.1219, 326.8112, 200, 357.0954)        -- Camera coordinates for character preview screen
Config.EnableDeleteButton = true                                      -- Define if the player can delete the character or not
Config.customNationality = false                                      -- Defines if Nationality input is custom of blocked to the list of Countries
Config.SkipSelection = false                                          -- Skip the spawn selection and spawns the player at the last location

-- IPL Loading (for custom interiors like Vanilla Unicorn, etc.)
-- Set to nil or empty table {} if you don't need IPLs loaded
-- Example for Vanilla Unicorn: {"TrevorsTrailerTidy", "v_strip3"}
Config.RequiredIPLs = {}                                              -- List of IPL names to load for custom interiors

-- Walk animation settings
Config.WalkInCoords = vector4(-843.55, -63.39, 37.84, 117.81)--vector4(-761.81, 326.72, 199.49, 2.0)  -- Initial spawn position (outside camera) - Character walks FROM here TO Config.PedCoords
Config.WalkOutCoords = vector4(-853.54, -70.26, 37.84, 107.44)--vector4(-763.2816, 325.0418, 199.4865, 177.7942) -- Exit position (outside camera) - Character runs/walks TO here before deletion
Config.WalkSpeed = 3.0                                                   -- Walk speed (1.0 = normal walking)
Config.WalkDuration = 2600                                               -- Duration for walk-in animation in ms
Config.RunSpeed = 3.0                                                    -- Run speed when switching characters (3.0 = fast run)
Config.RunDuration = 2000                                                -- Duration for run-out animation in ms

-- Emote settings
Config.EnableEmotes = true                                              -- Enable random emotes after character walks in
Config.EmoteDelay = 500                                                 -- Delay in ms before playing emote after walk-in
Config.AvailableEmotes = {                                             -- List of emotes to randomly play
    { dict = "amb@world_human_musician@guitar@male@idle_a", anim = "idle_b", name = "guitaridle3" },
    --{ dict = "anim@mp_player_intupperfinger", anim = "idle_a", name = "finger" }, --guard --jog --uWu --thumbsup -- slow clap 3 --shakeoff --karate2
    --{ dict = "anim@mp_player_intupperthumbs_up", anim = "idle_a", name = "thumbsup" },
    --{ dict = "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", anim = "hi_dance_facedj_13_v2_male^1", name = "dance" },
    { dict = "anim@mp_player_intupperslow_clap", anim = "idle_a", name = "slowclap3" },
    { dict = "uwu@egirl", anim = "base", name = "uWu" },
    { dict = "anim@mp_player_intuppersalute", anim = "idle_a", name = "salute" },
    { dict = "amb@world_human_jog_standing@male@idle_a", anim = "idle_a", name = "jog2" },
}

-- Visual Post-Processing Effect
Config.EnablePostProcess = false                                         -- Enable purple post-processing effect during character selection
Config.PostProcessStrength = 0.01                                        -- Strength of the purple effect (0.0 to 1.0)
-- The "ChopVision" screen effect provides a visible purple tint overlay
-- Combined with "purple" timecycle modifier for enhanced effect

Config.DefaultNumberOfCharacters = 3                                  -- Define maximum amount of default characters (maximum 5 characters defined by default)
Config.PlayersNumberOfCharacters = {                                  -- Define maximum amount of player characters by rockstar license (you can find this license in your server's database in the player table)
    { license = 'license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', numberOfChars = 2 },
}
