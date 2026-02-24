-- ─────────────────────────────────────────────────────────────────
--  chilllixhub-customlog  ·  client/main.lua
--  Detects player death and forwards the event to the server so the
--  server-side logger can record cause / reason.
--
--  FIX: Replaced QBCore:Player:SetPlayerData + isdead metadata approach
--  with a native IsPedDeadOrDying polling thread.  This works regardless
--  of whether another resource (e.g. qb-ambulancejob) is setting the
--  isdead metadata, and also works when this resource starts mid-session.
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

-- ── Death detection via native ped state ─────────────────────────
--
-- Uses LocalPlayer.state.isLoggedIn (set by qb-core) as the gate so
-- we never fire before the player has a character loaded.  This state
-- bag value persists even when the resource is restarted mid-session.
-- A 1-second poll is cheap and catches every death reliably.

CreateThread(function()
    while true do
        Wait(500)

        if LocalPlayer.state.isLoggedIn then
            local ped     = PlayerPedId()
            local nowDead = IsPedDeadOrDying(ped, true)

            if nowDead and not wasDead then
                TriggerServerEvent('chilllixhub-customlog:server:playerDied', GetDeathCause())
            end

            wasDead = nowDead
        end
    end
end)

-- Reset dead flag when player unloads their character (logout / char select).
-- RegisterNetEvent required because QBCore:Client:OnPlayerUnload is a net event.
RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    wasDead = false
end)
