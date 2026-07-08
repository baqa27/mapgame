-- ServerScriptService/GameServer/Services/PuzzleService.lua
-- Sequence-recall puzzles ("repeat the pattern"), driven by InvestigationData.Puzzles
-- (each has a `sequence` of small integers, e.g. kentongan_pattern = {2,1,3}). The demo
-- sequence IS sent to the client for playback (needed so the client can show/animate it)
-- -- submission is still validated server-side, so this only exposes "the answer to this
-- one puzzle, once opened," not any core game secret (accusation solutions stay
-- server-only). Tighten this later with server-timed in-world audio/light cues instead
-- of a raw payload if you want zero exposure.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local InvestigationData = require(Modules.Data.InvestigationData)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local PuzzleService = {}

local activePuzzleByPlayer = {}
local Services

function PuzzleService.Init(services)
	Services = services

	RemoteRegistry.Get("Puzzle/Submit").OnServerEvent:Connect(function(player, payload)
		if typeof(payload) ~= "table" or typeof(payload.answer) ~= "table" then
			return
		end
		PuzzleService.Submit(player, payload.puzzleId, payload.answer)
	end)
end

-- Called by InteractionService when a `puzzle` ProximityPrompt is triggered.
function PuzzleService.Open(player, puzzleId)
	local puzzle = InvestigationData.Puzzles[puzzleId]
	if not puzzle then
		warn("[PuzzleService] Unknown PuzzleId:", puzzleId)
		return
	end

	activePuzzleByPlayer[player] = puzzleId

	local symbolCount = 0
	for _, value in ipairs(puzzle.sequence) do
		symbolCount = math.max(symbolCount, value)
	end

	RemoteRegistry.Get("Puzzle/Data"):FireClient(player, {
		puzzleId = puzzleId,
		displayName = puzzle.displayName,
		description = puzzle.description,
		symbolCount = symbolCount,
		sequence = puzzle.sequence, -- client uses this only to animate the demo playback
	})
end

local function sequencesMatch(a, b)
	if typeof(a) ~= "table" or #a ~= #b then
		return false
	end
	for i, value in ipairs(b) do
		if a[i] ~= value then
			return false
		end
	end
	return true
end

function PuzzleService.Submit(player, puzzleId, answer)
	if activePuzzleByPlayer[player] ~= puzzleId then
		return -- no active puzzle matching this id; ignore forged/stale submit
	end
	local puzzle = InvestigationData.Puzzles[puzzleId]
	if not puzzle then
		return
	end

	local success = sequencesMatch(answer, puzzle.sequence)
	activePuzzleByPlayer[player] = nil

	if success then
		if puzzle.rewardClue then
			local clue = InvestigationData.GetClue(puzzle.rewardClue)
			Services.InvestigationService.CollectClue(
				player,
				puzzle.rewardClue,
				clue and clue.description,
				clue and clue.isFalse == true
			)
		end
		Services.ObjectiveService.ReportProgress(player, GameConfig.Objectives.Types.SOLVE_PUZZLE, 1)
	else
		Services.CheckpointService.ReportInvestigationFailure(player)
	end

	RemoteRegistry.Get("Puzzle/Result"):FireClient(player, {
		success = success,
		rewardClueId = success and puzzle.rewardClue or nil,
	})
end

return PuzzleService
