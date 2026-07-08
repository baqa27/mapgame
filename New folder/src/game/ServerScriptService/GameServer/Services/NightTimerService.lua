-- ServerScriptService/GameServer/Services/NightTimerService.lua
-- Counts down the per-level "waktu ronda" from game_mechanics.md rule #1. On expiry, if
-- the player hasn't met the objective quota yet, that's a mission failure per rule #2 --
-- NOT a hard game over, just a return to the last checkpoint (mirrors what happens when
-- trust collapses into "feared", see TrustService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local NightTimerService = {}

local activeTimers = {}
local Services

function NightTimerService.Init(services)
	Services = services
end

function NightTimerService.InitPlayer(player, difficulty)
	local duration = GameConfig.Night.DurationSeconds[difficulty] or GameConfig.Night.DurationSeconds.Easy
	local deadline = os.clock() + duration
	local token = {} -- unique token so a stale loop from a previous life can't fire late
	activeTimers[player] = token

	task.spawn(function()
		while activeTimers[player] == token do
			local remaining = math.max(0, math.floor(deadline - os.clock()))
			RemoteRegistry.Get("Night/TimeUpdated"):FireClient(player, { secondsRemaining = remaining })

			if remaining <= 0 then
				local questCompleted = Services.ObjectiveService.IsQuotaMet(player)
				RemoteRegistry.Get("Night/TimeUp"):FireClient(player, { questCompleted = questCompleted })
				if not questCompleted then
					Services.CheckpointService.ReturnToLastCheckpoint(player, "time_up")
				end
				activeTimers[player] = nil
				return
			end

			task.wait(GameConfig.Night.BroadcastIntervalSeconds)
		end
	end)
end

function NightTimerService.RemovePlayer(player)
	activeTimers[player] = nil
end

return NightTimerService
