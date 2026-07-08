-- ServerScriptService/GameServer/Services/WorldObjectSpawnerService.lua
-- Auto-spawns clue markers, puzzle stations, NPC stands, checkpoint pads, and the
-- accusation board, all from WorldData.Village's real coordinates -- the environment
-- team's map only needs house/terrain geometry; this Service fills in the gameplay
-- layer. Idempotent (see MarkerBuilder) so hand-placed/hand-edited objects are never
-- overwritten on a later server start.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local WorldData = require(Modules.Data.WorldData)
local DialogueData = require(Modules.Data.DialogueData)
local InvestigationData = require(Modules.Data.InvestigationData)
local AttributeConstants = require(Modules.Util.AttributeConstants)
local MarkerBuilder = require(Modules.Util.MarkerBuilder)

local WorldObjectSpawnerService = {}

local FLAT = CFrame.Angles(0, 0, math.rad(90)) -- cylinders lie on their side by default

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
	local gameplay = map:FindFirstChild("Gameplay")
	if not gameplay then
		gameplay = Instance.new("Folder")
		gameplay.Name = "Gameplay"
		gameplay.Parent = map
	end
	return gameplay
end

local function getOrCreateSubfolder(gameplay, name)
	local folder = gameplay:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = gameplay
	end
	return folder
end

local function spawnClues(gameplay)
	local folder = getOrCreateSubfolder(gameplay, "Clues")
	for _, clue in ipairs(WorldData.Village.Clues) do
		local data = InvestigationData.GetClue(clue.id)
		MarkerBuilder.EnsureMarker(folder, clue.id, {
			Position = clue.position,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1, 1, 1),
			Color = Color3.fromRGB(140, 200, 235),
			Material = Enum.Material.Neon,
			Icon = "\240\159\148\141",
			ActionText = "Periksa",
			ObjectText = data and data.displayName or "Petunjuk",
			MaxActivationDistance = 8,
			GroundExclude = gameplay,
			Attributes = {
				[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.Clue,
				[AttributeConstants.Attributes.ClueId] = clue.id,
			},
		})
	end
end

local function spawnPuzzles(gameplay)
	local folder = getOrCreateSubfolder(gameplay, "Puzzles")
	for _, puzzle in ipairs(WorldData.Village.Puzzles) do
		local data = InvestigationData.Puzzles[puzzle.id]
		local attrs = {
			[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.Puzzle,
			[AttributeConstants.Attributes.PuzzleId] = puzzle.id,
		}
		if data and data.requiredDifficulty then
			attrs[AttributeConstants.Attributes.DifficultyOnly] = data.requiredDifficulty
		end
		MarkerBuilder.EnsureMarker(folder, puzzle.id, {
			Position = puzzle.position,
			Shape = Enum.PartType.Block,
			Size = Vector3.new(1.6, 1.6, 1.6),
			Color = Color3.fromRGB(170, 120, 220),
			Material = Enum.Material.Neon,
			Icon = "\240\159\167\169",
			ActionText = "Pecahkan",
			ObjectText = data and data.displayName or "Teka-teki",
			MaxActivationDistance = 9,
			GroundExclude = gameplay,
			Attributes = attrs,
		})
	end
end

local function spawnNPCs(gameplay)
	local folder = getOrCreateSubfolder(gameplay, "NPCs")
	for _, npc in ipairs(WorldData.Village.NPCs) do
		local dialogue = DialogueData.GetDialogue(npc.id)
		MarkerBuilder.EnsureMarker(folder, npc.id, {
			Position = npc.position,
			Shape = Enum.PartType.Block,
			Size = Vector3.new(2, 5.5, 0.4),
			Color = Color3.fromRGB(90, 130, 110),
			Material = Enum.Material.ForceField,
			NameLabel = dialogue and dialogue.displayName or npc.label,
			ActionText = "Bicara",
			ObjectText = dialogue and dialogue.displayName or "Warga",
			MaxActivationDistance = 9,
			Bob = false,
			GroundExclude = gameplay,
			Attributes = {
				[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.NPC,
				[AttributeConstants.Attributes.NPCId] = npc.id,
			},
		})
	end
end

local function spawnCheckpoints(gameplay)
	local folder = getOrCreateSubfolder(gameplay, "Checkpoints")
	for id, position in pairs(WorldData.Village.Checkpoints) do
		MarkerBuilder.EnsureMarker(folder, id, {
			Position = position,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 6, 6),
			Color = Color3.fromRGB(232, 168, 85),
			Material = Enum.Material.Neon,
			Icon = "\240\159\143\174",
			ActionText = "Lapor",
			ObjectText = "Checkpoint",
			MaxActivationDistance = 12,
			Bob = false,
			ExtraRotation = FLAT,
			GroundExclude = gameplay,
			GroundClearance = 0.15, -- half the disc's true thickness once rotated flat
			Attributes = {
				[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.Checkpoint,
				[AttributeConstants.Attributes.CheckpointId] = id,
			},
		})
	end
end

local function spawnAccusationBoard(gameplay)
	local folder = getOrCreateSubfolder(gameplay, "Interactables")
	local position = WorldData.Village.Checkpoints.ending_choice
	if not position then
		return
	end
	MarkerBuilder.EnsureMarker(folder, "accusation_board", {
		Position = position + Vector3.new(6, 1, 0),
		Shape = Enum.PartType.Block,
		Size = Vector3.new(3, 3.5, 1),
		Color = Color3.fromRGB(150, 40, 40),
		Material = Enum.Material.Neon,
		Icon = "\226\154\150",
		ActionText = "Buka",
		ObjectText = "Papan Tuduhan",
		MaxActivationDistance = 10,
		Bob = false,
		GroundExclude = gameplay,
		Attributes = {
			[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.AccusationBoard,
		},
	})
end

function WorldObjectSpawnerService.Init(_services)
	task.spawn(function()
		local gameplay = getGameplayFolder()
		if not gameplay then
			warn("[WorldObjectSpawnerService] Active map gameplay folder not found -- no world objects spawned.")
			return
		end
		spawnClues(gameplay)
		spawnPuzzles(gameplay)
		spawnNPCs(gameplay)
		spawnCheckpoints(gameplay)
		spawnAccusationBoard(gameplay)
	end)
end

return WorldObjectSpawnerService
