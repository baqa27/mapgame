-- ServerScriptService/GameServer/Services/InteractionService.lua
-- Single entry point for every ProximityPrompt in Workspace.Map.Gameplay. Roblox's
-- ProximityPrompt already only fires .Triggered server-side after validating distance
-- (MaxActivationDistance) -- this Service just reads attributes and routes to the
-- matching Service. No Controller/Remote ever bypasses this path.
--
-- Must be Init()'d LAST in Bootstrap (after every other Service), since it calls into
-- all of them.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local AttributeConstants = require(Modules.Util.AttributeConstants)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local InteractionService = {}

local Services

local function getGameplayFolder()
	local map = Workspace:FindFirstChild("Map") or Workspace:WaitForChild("Map", 30)
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
		Services.ObjectiveService.AddCarriedJimpitan(player, 1)
		-- One-time pickup; MapManager.luau (environment team's script, see
		-- MAP_LEVEL_DESIGN_GUIDE.md) owns respawn behavior for JimpitanSpawns -- we only
		-- consume the interaction here, we never touch the spawn part itself.
	elseif interactionType == Types.Clue then
		Services.InvestigationService.CollectClue(
			player,
			part:GetAttribute(Attrs.ClueId),
			part:GetAttribute(Attrs.ClueText),
			part:GetAttribute(Attrs.FalseClue) == true
		)
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
