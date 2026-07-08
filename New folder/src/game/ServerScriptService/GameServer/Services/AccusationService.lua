-- ServerScriptService/GameServer/Services/AccusationService.lua
-- Resolves accusations into endings, per DESIGN_BRIEF.md's Ending Rules and
-- game_naratif.md's Easy/Medium/Hard branches. The actual "who's guilty" answer comes
-- from CaseGenerationService's randomly generated per-player case -- never a static
-- lookup. Hard mode requires BOTH a human and a pesugihan culprit to be caught; a
-- suspect flagged "human_and_pesugihan" (today: only possible outcome, see
-- CaseGenerationService's content note) satisfies both with a single accusation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local InvestigationData = require(Modules.Data.InvestigationData)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local AccusationService = {}

local caughtByPlayer = {} -- [player] = { human = bool, pesugihan = bool }
local Services

function AccusationService.Init(services)
	Services = services

	RemoteRegistry.Get("Accusation/Submit").OnServerEvent:Connect(function(player, payload)
		if typeof(payload) ~= "table" then
			return
		end
		AccusationService.Submit(player, payload.suspectId)
	end)
end

function AccusationService.InitPlayer(player, _difficulty)
	caughtByPlayer[player] = { human = false, pesugihan = false }
end

function AccusationService.RemovePlayer(player)
	caughtByPlayer[player] = nil
end

-- Called by InteractionService when the `accusation_board` ProximityPrompt is triggered.
-- Sends the suspect roster + profile blurb (safe -- profile text is flavor, not a
-- guilt/innocence tell) -- never the actual solution.
function AccusationService.OpenBoard(player)
	local suspects = {}
	for suspectId, suspect in pairs(InvestigationData.Suspects) do
		table.insert(suspects, {
			id = suspectId,
			name = suspect.displayName,
			profile = suspect.profile,
		})
	end
	table.sort(suspects, function(a, b)
		return a.name < b.name
	end)
	RemoteRegistry.Get("Accusation/Open"):FireClient(player, { suspects = suspects })
end

local function markCaught(caught, culpritType)
	if culpritType == "human" then
		caught.human = true
	elseif culpritType == "pesugihan" then
		caught.pesugihan = true
	elseif culpritType == "human_and_pesugihan" then
		caught.human = true
		caught.pesugihan = true
	end
end

function AccusationService.Submit(player, suspectId)
	local difficulty = player:GetAttribute("Difficulty") or "Easy"

	if Services.InvestigationService.GetClueCount(player) < GameConfig.Investigation.MinCluesForAccusation then
		RemoteRegistry.Get("Accusation/Result"):FireClient(player, {
			outcome = "not_enough_clues",
			endingId = nil,
		})
		return
	end

	local culpritType = Services.CaseGenerationService.GetCulpritType(player, suspectId)

	if difficulty == "Easy" then
		if culpritType == "human" or culpritType == "human_and_pesugihan" then
			Services.SaveService.RecordEnding(player, GameConfig.Ending.Easy)
			Services.SaveService.UnlockDifficulty(player, "Medium")
			Services.ObjectiveService.ReportProgress(player, GameConfig.Objectives.Types.DETERMINE_SUSPECT, 1)
			RemoteRegistry.Get("Accusation/Result"):FireClient(player, {
				outcome = "correct",
				endingId = GameConfig.Ending.Easy,
			})
		else
			Services.TrustService.Adjust(player, GameConfig.Trust.Delta.WrongAccusationOfNPC, difficulty)
			RemoteRegistry.Get("Accusation/Result"):FireClient(player, { outcome = "wrong", endingId = nil })
		end
		return
	end

	if difficulty == "Medium" then
		if culpritType == "human" or culpritType == "human_and_pesugihan" then
			Services.SaveService.RecordEnding(player, GameConfig.Ending.MediumHuman)
			Services.ObjectiveService.ReportProgress(player, GameConfig.Objectives.Types.DETERMINE_SUSPECT, 1)
			RemoteRegistry.Get("Accusation/Result"):FireClient(player, {
				outcome = "correct",
				endingId = GameConfig.Ending.MediumHuman,
			})
		elseif culpritType == "pesugihan" then
			Services.SaveService.RecordEnding(player, GameConfig.Ending.MediumPesugihan)
			Services.ObjectiveService.ReportProgress(player, GameConfig.Objectives.Types.DETERMINE_SUSPECT, 1)
			RemoteRegistry.Get("Accusation/Result"):FireClient(player, {
				outcome = "correct",
				endingId = GameConfig.Ending.MediumPesugihan,
			})
		else
			Services.TrustService.Adjust(player, GameConfig.Trust.Delta.WrongAccusationOfNPC, difficulty)
			RemoteRegistry.Get("Accusation/Result"):FireClient(player, { outcome = "wrong", endingId = nil })
		end
		return
	end

	-- Hard mode: both culprit types must be found (a single "human_and_pesugihan"
	-- accusation satisfies both at once).
	local caught = caughtByPlayer[player]
	if culpritType == nil then
		Services.TrustService.Adjust(player, GameConfig.Trust.Delta.WrongAccusationOfNPC, difficulty)
		RemoteRegistry.Get("Accusation/Result"):FireClient(player, { outcome = "wrong", endingId = nil })
		return
	end
	markCaught(caught, culpritType)

	if caught.human and caught.pesugihan then
		Services.SaveService.RecordEnding(player, GameConfig.Ending.HardFull)
		Services.SaveService.SetFreeModeUnlocked(player, true)
		Services.ObjectiveService.ReportProgress(player, GameConfig.Objectives.Types.DETERMINE_SUSPECT, 1)
		RemoteRegistry.Get("Accusation/Result"):FireClient(player, {
			outcome = "correct_full",
			endingId = GameConfig.Ending.HardFull,
		})
	else
		RemoteRegistry.Get("Accusation/Result"):FireClient(player, {
			outcome = "correct_partial",
			endingId = nil,
		})
	end
end

return AccusationService
