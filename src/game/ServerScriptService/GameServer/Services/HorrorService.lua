-- ServerScriptService/GameServer/Services/HorrorService.lua
-- Schedules subtle psychological events per difficulty intensity. STRICTLY cosmetic --
-- never mutates trust/objective/clue state. Client only receives an eventType + empty
-- params table and decides how to render it (see HorrorController.lua).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local HorrorService = {}

local EVENT_TYPES = { "whisper", "shadow_flicker", "light_flicker" }
local activeLoops = {}

local function frequencyKeyFor(player)
	local difficulty = player:GetAttribute("Difficulty") or "Easy"
	local tier = GameConfig.Difficulty[difficulty]
	return (tier and tier.HorrorFrequency) or "low"
end

function HorrorService.Init(_services) end

function HorrorService.InitPlayer(player)
	activeLoops[player] = true
	task.spawn(function()
		while activeLoops[player] do
			local range = GameConfig.HorrorIntervalSeconds[frequencyKeyFor(player)]
			task.wait(range.min + math.random() * (range.max - range.min))
			if not activeLoops[player] then
				return
			end
			RemoteRegistry.Get("Horror/Event"):FireClient(player, {
				eventType = EVENT_TYPES[math.random(1, #EVENT_TYPES)],
				params = {},
			})
		end
	end)
end

function HorrorService.RemovePlayer(player)
	activeLoops[player] = nil
end

return HorrorService
