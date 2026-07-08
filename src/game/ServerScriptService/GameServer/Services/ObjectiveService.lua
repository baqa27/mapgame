-- ServerScriptService/GameServer/Services/ObjectiveService.lua
-- Tracks the per-difficulty objective CHAIN from ObjectiveData.lua (brief -> collect
-- jimpitan -> find clues -> talk to witnesses -> accuse), one step active at a time.
-- Jimpitan collection stays two-phase: pick up (carried) THEN deposit at any checkpoint
-- (counts toward whichever step is active, plus a lifetime total) -- matches GAME
-- LAVEL.md's Easy Mode "Main Action": collect jimpitan, THEN store it at Pos Ronda.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local ObjectiveData = require(Modules.Data.ObjectiveData)
local WorldData = require(Modules.Data.WorldData)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local ObjectiveService = {}

local stateByPlayer = {} -- [player] = { chain, stepIndex, stepProgress, carried, totalDeposited }
local Services

function ObjectiveService.Init(services)
	Services = services
end

function ObjectiveService.InitPlayer(player, difficulty)
	stateByPlayer[player] = {
		chain = ObjectiveData.GetChain(difficulty),
		stepIndex = 1,
		stepProgress = 0,
		carried = 0,
		totalDeposited = 0,
	}
	ObjectiveService.Broadcast(player)
end

function ObjectiveService.RemovePlayer(player)
	stateByPlayer[player] = nil
end

local function currentStep(state)
	return state.chain[state.stepIndex]
end

function ObjectiveService.Broadcast(player)
	local state = stateByPlayer[player]
	if not state then
		return
	end
	local step = currentStep(state)
	RemoteRegistry.Get("Objective/StateChanged"):FireClient(player, {
		title = step and step.title or "Ronda selesai",
		description = step and step.description or "Semua tahap malam ini sudah kamu selesaikan.",
		progress = step and state.stepProgress or 0,
		target = step and step.target or 0,
		stepIndex = state.stepIndex,
		stepCount = #state.chain,
		carried = state.carried,
		chainComplete = step == nil,
	})
end

-- Advances the CURRENT step only if `stepIdOrType` matches its `id` or its `type`.
-- Callers can report either an exact step id (DialogueData's `objectiveProgress` field)
-- or a generic type (GameConfig.Objectives.Types.*, used by jimpitan/clue/puzzle/talk
-- flows that aren't tied to one specific step id).
function ObjectiveService.ReportProgress(player, stepIdOrType, amount)
	local state = stateByPlayer[player]
	if not state then
		return
	end
	local step = currentStep(state)
	if not step then
		return -- chain already complete
	end
	if step.id ~= stepIdOrType and step.type ~= stepIdOrType then
		return -- not relevant to the currently active step
	end

	state.stepProgress = math.min(step.target, state.stepProgress + (amount or 1))

	if state.stepProgress >= step.target then
		if step.checkpoint and Services and Services.CheckpointService then
			local position = WorldData.Village.Checkpoints[step.checkpoint]
			Services.CheckpointService.Reach(player, step.checkpoint, position and CFrame.new(position) or nil)
		end
		state.stepIndex = state.stepIndex + 1
		state.stepProgress = 0
	end

	ObjectiveService.Broadcast(player)
end

-- Called by JimpitanSpawnerService when a player picks up a jimpitan can. NOT counted
-- toward the objective yet -- see DepositCarriedJimpitan.
function ObjectiveService.AddCarriedJimpitan(player, amount)
	local state = stateByPlayer[player]
	if not state then
		return
	end
	state.carried = state.carried + (amount or 1)
	ObjectiveService.Broadcast(player)
end

-- Called by CheckpointService whenever the player reaches ANY checkpoint -- converts
-- carried jimpitan into real progress (both a lifetime total, and the active step's
-- progress if it happens to be a COLLECT_JIMPITAN step).
function ObjectiveService.DepositCarriedJimpitan(player)
	local state = stateByPlayer[player]
	if not state or state.carried <= 0 then
		return
	end
	local amount = state.carried
	state.carried = 0
	state.totalDeposited = state.totalDeposited + amount
	ObjectiveService.ReportProgress(player, GameConfig.Objectives.Types.COLLECT_JIMPITAN, amount)
end

function ObjectiveService.IsChainComplete(player)
	local state = stateByPlayer[player]
	return state ~= nil and currentStep(state) == nil
end

function ObjectiveService.IsQuotaMet(player)
	local state = stateByPlayer[player]
	if not state then
		return false
	end
	local difficulty = player:GetAttribute("Difficulty") or "Easy"
	local config = GameConfig.Difficulty[difficulty]
	local quota = config and config.JimpitanQuota or 8
	return state.totalDeposited >= quota
end

return ObjectiveService
