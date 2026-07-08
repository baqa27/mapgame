-- ServerScriptService/GameServer/Services/AccusationService.lua
-- Resolves accusations into endings, per DESIGN_BRIEF.md's Ending Rules and
-- game_naratif.md's Easy/Medium/Hard branches. The actual "who's guilty" answer comes
-- from CaseGenerationService's randomly generated per-player case -- NOT a static
-- lookup -- so replaying the same difficulty can point at a different suspect each time.
-- Hard mode requires BOTH a human and a pesugihan culprit to be caught (across separate
-- accusations) before it counts as fully solved; catching only one records "partial"
-- progress and keeps the game open.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local NarrativeData = require(Modules.NarrativeData)
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
-- Sends the suspect roster + eligibility pool only -- never the actual solution.
function AccusationService.OpenBoard(player)
	RemoteRegistry.Get("Accusation/Open"):FireClient(player, {
		suspects = NarrativeData.Suspects,
	})
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
		if culpritType == "human" then
			Services.SaveService.RecordEnding(player, GameConfig.Ending.Easy)
			Services.SaveService.UnlockDifficulty(player, "Medium")
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
		if culpritType == "human" then
			Services.SaveService.RecordEnding(player, GameConfig.Ending.MediumHuman)
			RemoteRegistry.Get("Accusation/Result"):FireClient(player, {
				outcome = "correct",
				endingId = GameConfig.Ending.MediumHuman,
			})
		elseif culpritType == "pesugihan" then
			Services.SaveService.RecordEnding(player, GameConfig.Ending.MediumPesugihan)
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

	-- Hard mode: both culprit types must be found across separate accusations.
	local caught = caughtByPlayer[player]
	if culpritType == "human" then
		caught.human = true
	elseif culpritType == "pesugihan" then
		caught.pesugihan = true
	else
		Services.TrustService.Adjust(player, GameConfig.Trust.Delta.WrongAccusationOfNPC, difficulty)
		RemoteRegistry.Get("Accusation/Result"):FireClient(player, { outcome = "wrong", endingId = nil })
		return
	end

	if caught.human and caught.pesugihan then
		Services.SaveService.RecordEnding(player, GameConfig.Ending.HardFull)
		Services.SaveService.SetFreeModeUnlocked(player, true)
		RemoteRegistry.Get("Accusation/Result"):FireClient(player, {
			outcome = "correct_full",
			endingId = GameConfig.Ending.HardFull,
		})
	else
		-- Only one culprit found so far -- game stays open, no ending screen yet.
		RemoteRegistry.Get("Accusation/Result"):FireClient(player, {
			outcome = "correct_partial",
			endingId = nil,
		})
	end
end

return AccusationService
