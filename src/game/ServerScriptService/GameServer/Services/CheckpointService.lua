-- ServerScriptService/GameServer/Services/CheckpointService.lua
-- Records the last reached checkpoint (via SaveService, plus its physical CFrame for
-- teleport-back) and unlocks an optional hint after repeated investigation failures
-- (game_mechanics.md rule #9). ReturnToLastCheckpoint() implements the "failure return"
-- half of ARCHITECTURE.md's CheckpointService description -- triggered by TrustService
-- (trust collapses to "feared") and NightTimerService (time's up, quota not met), per
-- game_mechanics.md rule #2.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local NarrativeData = require(Modules.NarrativeData)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local CheckpointService = {}

local failuresByPlayer = {}
local hintGivenByPlayer = {}
local lastCFrameByPlayer = {}
local Services

function CheckpointService.Init(services)
	Services = services
end

function CheckpointService.InitPlayer(player, _difficulty)
	failuresByPlayer[player] = 0
	hintGivenByPlayer[player] = false
	lastCFrameByPlayer[player] = nil
end

function CheckpointService.RemovePlayer(player)
	failuresByPlayer[player] = nil
	hintGivenByPlayer[player] = nil
	lastCFrameByPlayer[player] = nil
end

-- Called by InteractionService when a `checkpoint` ProximityPrompt is triggered.
-- `cframe` is the checkpoint part's own CFrame, read live from the map at trigger time --
-- this Service never hardcodes or caches map positions.
function CheckpointService.Reach(player, checkpointId, cframe)
	Services.SaveService.SetCheckpoint(player, checkpointId)
	if cframe then
		lastCFrameByPlayer[player] = cframe
	end
	Services.ObjectiveService.DepositCarriedJimpitan(player)
	RemoteRegistry.Get("Checkpoint/Saved"):FireClient(player, { checkpointId = checkpointId })
end

-- Teleports the player back to the last reached checkpoint. No-ops if the player hasn't
-- reached one yet (their spawn point stands in for "checkpoint zero").
function CheckpointService.ReturnToLastCheckpoint(player, reason)
	local cframe = lastCFrameByPlayer[player]
	if not cframe then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = cframe + Vector3.new(0, 5, 0)
	end
	RemoteRegistry.Get("Checkpoint/Returned"):FireClient(player, { reason = reason or "unknown" })
end

function CheckpointService.ReportInvestigationFailure(player)
	local count = (failuresByPlayer[player] or 0) + 1
	failuresByPlayer[player] = count

	if count >= GameConfig.Investigation.HintUnlockAfterFailures and not hintGivenByPlayer[player] then
		hintGivenByPlayer[player] = true
		RemoteRegistry.Get("Checkpoint/HintUnlocked"):FireClient(player, {
			hintText = NarrativeData.Hints.default,
		})
	end
end

return CheckpointService
