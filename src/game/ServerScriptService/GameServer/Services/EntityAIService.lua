-- ServerScriptService/GameServer/Services/EntityAIService.lua
-- Non-combat observing-entity presence. Fires rarer "sighted" hints than HorrorService's
-- flicker events. NEVER becomes a chase/combat mechanic and never sends exact position
-- data that would trivialize investigation -- payload is hintOnly + an optional flavor
-- name pulled from NarrativeData.EntityNames (setan gundul / methek, per the team's
-- accepted narrative revision).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local NarrativeData = require(Modules.NarrativeData)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local EntityAIService = {}

local activeLoops = {}

local function frequencyKeyFor(player)
	local difficulty = player:GetAttribute("Difficulty") or "Easy"
	local tier = GameConfig.Difficulty[difficulty]
	return (tier and tier.HorrorFrequency) or "low"
end

local function entityNameFor(player)
	local difficulty = player:GetAttribute("Difficulty") or "Easy"
	local names = NarrativeData.EntityNames[difficulty]
	if not names or #names == 0 then
		return nil
	end
	return names[math.random(1, #names)]
end

function EntityAIService.Init(_services) end

function EntityAIService.InitPlayer(player)
	activeLoops[player] = true
	task.spawn(function()
		while activeLoops[player] do
			local range = GameConfig.HorrorIntervalSeconds[frequencyKeyFor(player)]
			-- Entity sightings are intentionally rarer than horror flicker events.
			task.wait(range.min + range.max)
			if not activeLoops[player] then
				return
			end
			RemoteRegistry.Get("Entity/Sighted"):FireClient(player, {
				hintOnly = true,
				entityHint = entityNameFor(player),
			})
		end
	end)
end

function EntityAIService.RemovePlayer(player)
	activeLoops[player] = nil
end

return EntityAIService
