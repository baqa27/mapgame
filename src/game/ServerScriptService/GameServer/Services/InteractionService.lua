-- ServerScriptService/GameServer/Services/InteractionService.lua
-- Single entry point for every ProximityPrompt in Workspace.Map.Gameplay. Roblox's
-- ProximityPrompt already only fires .Triggered server-side after validating distance
-- (MaxActivationDistance) -- this Service just reads attributes and routes to the
-- matching Service. No Controller/Remote ever bypasses this path.
--
-- Clue content (text, isFalse, difficulty gating) is looked up from InvestigationData by
-- ClueId -- map parts only need to carry the id, not full flavor text as an attribute.
--
-- Must be Init()'d LAST in Bootstrap (after every other Service, including the world
-- spawners), since it calls into all of them.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local InvestigationData = require(Modules.Data.InvestigationData)
local AttributeConstants = require(Modules.Util.AttributeConstants)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local InteractionService = {}

local Services

local function getGameplayFolder()
	local mapsFolder = Workspace:FindFirstChild("Maps")
	local map
	if mapsFolder then
		map = mapsFolder:FindFirstChild("MainGameMap") or mapsFolder:FindFirstChild("LobbyMap")
	end
	map = map or Workspace:FindFirstChild("Map") or Workspace:WaitForChild("Map", 30)
	if not map then
		return nil
	end
	return map:FindFirstChild("Gameplay") or map:WaitForChild("Gameplay", 30)
end

local function difficultyAllows(part, player)
	local only = part:GetAttribute(AttributeConstants.Attributes.DifficultyOnly)
	if not only then
		return true
	end
	return player:GetAttribute("Difficulty") == only
end

-- Optional soft-lock: an interactable can require a specific clue already be collected
-- before it does anything (e.g. Rumah Kosong's false-clue location, shown padlocked in
-- the reference map). Purely a gate -- InteractionType logic is untouched otherwise.
local function meetsRequirement(part, player, services)
	local requiredClueId = part:GetAttribute(AttributeConstants.Attributes.RequiresClueId)
	if not requiredClueId then
		return true
	end
	return services.InvestigationService.HasClue(player, requiredClueId)
end

local function handleClue(player, part, Attrs)
	local clueId = part:GetAttribute(Attrs.ClueId)
	local clueData = InvestigationData.GetClue(clueId)
	local difficulty = player:GetAttribute("Difficulty") or "Easy"

	if clueData and not InvestigationData.IsClueAllowed(clueId, difficulty) then
		return -- this clue isn't part of the active difficulty's clue set
	end

	local text = clueData and clueData.description or part:GetAttribute(Attrs.ClueText)
	local isFalse = clueData and clueData.isFalse == true or part:GetAttribute(Attrs.FalseClue) == true

	local collected = Services.InvestigationService.CollectClue(player, clueId, text, isFalse)
	if collected then
		Services.ObjectiveService.ReportProgress(player, GameConfig.Objectives.Types.FIND_CLUE, 1)
	end
end

local function onTriggered(part, player)
	if not difficultyAllows(part, player) then
		return
	end
	if not meetsRequirement(part, player, Services) then
		RemoteRegistry.Get("Interaction/Locked"):FireClient(player, {
			reason = part:GetAttribute(AttributeConstants.Attributes.PromptText) or "locked",
		})
		return
	end

	local interactionType = part:GetAttribute(AttributeConstants.Attributes.InteractionType)
	local Types = AttributeConstants.InteractionType
	local Attrs = AttributeConstants.Attributes

	if interactionType == Types.Jimpitan then
		Services.JimpitanSpawnerService.Collect(player, part)
	elseif interactionType == Types.Clue then
		handleClue(player, part, Attrs)
	elseif interactionType == Types.NPC then
		Services.DialogueService.Start(player, part:GetAttribute(Attrs.NPCId))
	elseif interactionType == Types.Puzzle then
		Services.PuzzleService.Open(player, part:GetAttribute(Attrs.PuzzleId))
	elseif interactionType == Types.Checkpoint then
		Services.CheckpointService.Reach(player, part:GetAttribute(Attrs.CheckpointId), part.CFrame)
	elseif interactionType == Types.AccusationBoard then
		Services.AccusationService.OpenBoard(player)
	end
end

local function wire(prompt, part)
	prompt.Triggered:Connect(function(player)
		onTriggered(part, player)
	end)
end

local function tryWireDescendant(descendant)
	if not descendant:IsA("ProximityPrompt") then
		return
	end
	local part = descendant.Parent
	if part and part:GetAttribute(AttributeConstants.Attributes.InteractionType) then
		wire(descendant, part)
	end
end

function InteractionService.Init(services)
	Services = services

	task.spawn(function()
		local gameplayFolder = getGameplayFolder()
		if not gameplayFolder then
			warn("[InteractionService] Workspace.Map.Gameplay not found -- no interactables wired.")
			return
		end

		for _, descendant in ipairs(gameplayFolder:GetDescendants()) do
			tryWireDescendant(descendant)
		end

		gameplayFolder.DescendantAdded:Connect(tryWireDescendant)
	end)
end

return InteractionService
