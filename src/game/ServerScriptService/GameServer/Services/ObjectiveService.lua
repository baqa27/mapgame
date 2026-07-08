-- ServerScriptService/GameServer/Services/ObjectiveService.lua
-- Tracks the global cooperative objective chain per difficulty. Jimpitan collection is
-- two-phase, matching GAME_LAVEL.md's "Main Action": pick up jimpitan around the village
-- (carried, not yet counted) THEN deposit it at a checkpoint/Pos Ronda (progress) --
-- this is deliberately where the "money disappears" mystery lives narratively.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local ObjectiveService = {}

local progressByPlayer = {}

function ObjectiveService.Init(_services) end

function ObjectiveService.InitPlayer(player, difficulty)
	local tier = GameConfig.Difficulty[difficulty] or GameConfig.Difficulty.Easy
	progressByPlayer[player] = {
		progress = 0,
		target = tier.JimpitanQuota,
		carried = 0,
		label = "Kumpulkan jimpitan",
	}
	ObjectiveService.Broadcast(player)
end

function ObjectiveService.RemovePlayer(player)
	progressByPlayer[player] = nil
end

function ObjectiveService.Broadcast(player)
	local data = progressByPlayer[player]
	if not data then
		return
	end
	RemoteRegistry.Get("Objective/StateChanged"):FireClient(player, {
		label = data.label,
		progress = data.progress,
		target = data.target,
		carried = data.carried,
	})
end

-- Called by InteractionService when a `jimpitan_can` ProximityPrompt is triggered. Does
-- NOT count toward the objective yet -- see DepositCarriedJimpitan.
function ObjectiveService.AddCarriedJimpitan(player, amount)
	local data = progressByPlayer[player]
	if not data then
		return
	end
	data.carried = data.carried + (amount or 1)
	ObjectiveService.Broadcast(player)
end

-- Called by CheckpointService whenever the player reaches ANY checkpoint (Pos Ronda or
-- otherwise) -- converts carried jimpitan into real objective progress.
function ObjectiveService.DepositCarriedJimpitan(player)
	local data = progressByPlayer[player]
	if not data or data.carried <= 0 then
		return
	end
	local amount = data.carried
	data.carried = 0
	data.progress = math.min(data.target, data.progress + amount)
	ObjectiveService.Broadcast(player)
end

function ObjectiveService.SetLabel(player, label)
	local data = progressByPlayer[player]
	if not data then
		return
	end
	data.label = label
	ObjectiveService.Broadcast(player)
end

function ObjectiveService.IsQuotaMet(player)
	local data = progressByPlayer[player]
	return data ~= nil and data.progress >= data.target
end

return ObjectiveService
