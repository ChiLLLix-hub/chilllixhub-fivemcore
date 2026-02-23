-- ─────────────────────────────────────────────────────────────────
--  chilllixhub-customlog  ·  client/main.lua
--  Detects player death and forwards the event to the server so the
--  server-side logger can record cause / reason.
-- ─────────────────────────────────────────────────────────────────

local QBCore  = exports['qb-core']:GetCoreObject()
local wasDead = false

-- ── Helpers ──────────────────────────────────────────────────────

local function GetDeathCause()
    local ped   = PlayerPedId()
    local cause = 'Unknown'

    local killerEnt = GetPedSourceOfDeath(ped)
    if killerEnt ~= 0 and DoesEntityExist(killerEnt) then
        if IsPedAPlayer(killerEnt) then
            local killerIdx  = NetworkGetPlayerIndexFromPed(killerEnt)
            local killerName = GetPlayerName(killerIdx) or 'Unknown Player'
            cause = 'Killed by player: ' .. killerName
        else
            cause = 'Killed by NPC / environment'
        end
    end

    return cause
end

-- ── Death detection via QBCore metadata ──────────────────────────

AddEventHandler('QBCore:Player:SetPlayerData', function(PlayerData)
    if not LocalPlayer.state.isLoggedIn then return end
    if not PlayerData.metadata then return end

    local nowDead = PlayerData.metadata['isdead'] or false

    if nowDead and not wasDead then
        TriggerServerEvent('chilllixhub-customlog:server:playerDied', GetDeathCause())
    end

    wasDead = nowDead
end)

-- Reset flag on character unload
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    wasDead = false
end)
