-- ServerScriptService/GameServer/Services/PuzzleService.lua
-- Observation-puzzle framework. Implements ONE full puzzle type end-to-end (a
-- multiple-choice "spot the anomaly" puzzle), per MAIN_GAME_SYSTEM_RULES.md Build Order
-- step 7 -- add more entries to `Puzzles` below as new PuzzleId markers are attached to
-- interactables in Workspace.Map.Gameplay.Puzzles. No client/Controller changes are
-- needed to add a new puzzle of this type.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local PuzzleService = {}

local Puzzles = {
	rumah_02_jejak = {
		Question = "Mana jejak kaki yang tidak cocok dengan pola warga lain di rumah ini?",
		Options = {
			{ id = "a", text = "Jejak sandal, mengarah ke dapur" },
			{ id = "b", text = "Jejak sepatu bot, mengarah ke pagar belakang" },
			{ id = "c", text = "Jejak kaki telanjang, melingkar di teras" },
		},
		AnswerId = "b",
		RewardClueId = "jejak_sepatu_bot",
		RewardClueText = "Jejak sepatu bot menuju pagar belakang -- bukan pola warga biasa.",
	},
}

local activePuzzleByPlayer = {}
local Services

function PuzzleService.Init(services)
	Services = services

	RemoteRegistry.Get("Puzzle/Submit").OnServerEvent:Connect(function(player, payload)
		if typeof(payload) ~= "table" then
			return
		end
		PuzzleService.Submit(player, payload.puzzleId, payload.answer)
	end)
end

-- Called by InteractionService when a `puzzle` ProximityPrompt is triggered.
function PuzzleService.Open(player, puzzleId)
	local puzzle = Puzzles[puzzleId]
	if not puzzle then
		warn("[PuzzleService] Unknown PuzzleId:", puzzleId)
		return
	end
	activePuzzleByPlayer[player] = puzzleId
	RemoteRegistry.Get("Puzzle/Data"):FireClient(player, {
		puzzleId = puzzleId,
		question = puzzle.Question,
		options = puzzle.Options,
	})
end

function PuzzleService.Submit(player, puzzleId, answerId)
	if activePuzzleByPlayer[player] ~= puzzleId then
		return -- no active puzzle matching this id; ignore forged/stale submit
	end
	local puzzle = Puzzles[puzzleId]
	if not puzzle then
		return
	end

	local success = answerId == puzzle.AnswerId
	activePuzzleByPlayer[player] = nil

	if success then
		Services.InvestigationService.CollectClue(player, puzzle.RewardClueId, puzzle.RewardClueText, false)
	else
		Services.CheckpointService.ReportInvestigationFailure(player)
	end

	RemoteRegistry.Get("Puzzle/Result"):FireClient(player, {
		success = success,
		rewardClueId = success and puzzle.RewardClueId or nil,
	})
end

return PuzzleService
