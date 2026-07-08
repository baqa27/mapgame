-- tools/spawn_markers_studio.lua
--
-- ** SUPERSEDED as of the ground-snap fix in MarkerBuilder.lua (see commit "Fix marker
-- billboard overlap and item ground-snapping"). ** The runtime spawners
-- (JimpitanSpawnerService / WorldObjectSpawnerService, via MarkerBuilder.EnsureMarker)
-- now raycast every NEWLY created marker onto real ground/floor geometry automatically,
-- every server start -- no manual command-bar step needed anymore. This was very likely
-- the cause of "item placement ngawur" (floating/sunken items): if this script was never
-- run, the runtime spawners used raw guessed WorldData Y coordinates with zero ground
-- snapping.
--
-- Kept here only in case you need a one-off bulk re-align of markers that were already
-- created before the fix (EnsureMarker's idempotence means it will NOT re-snap parts
-- that already exist). If you hit that case: delete the stale marker parts under
-- Workspace.Map.Gameplay (or Workspace.Maps.*.Gameplay) in Studio's Explorer, then just
-- re-run the game (or re-run tools/sync_to_studio.lua then Play) -- the spawners will
-- recreate them correctly-snapped. You shouldn't need this script going forward.
--
-- Run this in Roblox Studio Edit Mode via Command Bar or MCP execute_luau.
-- Spawns and aligns all gameplay markers under Workspace.Maps.MainGameMap or LobbyMap.
-- Uses raycasting to align markers to the ground/terrain so they are never sunken.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:FindFirstChild("Modules")
if not Modules then
	error("Modules folder not found in ReplicatedStorage. Make sure project is synced.")
end

local WorldData = require(Modules.Data.WorldData)
local GameConfig = require(Modules.GameConfig)
local AttributeConstants = require(Modules.Util.AttributeConstants)

local function getActiveMap(mapName)
	local mapsFolder = Workspace:FindFirstChild("Maps")
	if not mapsFolder then
		error("Maps folder not found in Workspace")
	end
	local map = mapsFolder:FindFirstChild(mapName)
	if not map then
		error(mapName .. " not found in Workspace.Maps")
	end
	return map
end

local function getGroundHeight(position)
	local rayOrigin = position + Vector3.new(0, 150, 0)
	local rayDirection = Vector3.new(0, -300, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	-- We want to hit the terrain or built buildings/roads, but exclude existing gameplay folders/markers
	local excludeList = {}
	local mapsFolder = Workspace:FindFirstChild("Maps")
	if mapsFolder then
		for _, child in ipairs(mapsFolder:GetChildren()) do
			local gameplay = child:FindFirstChild("Gameplay")
			if gameplay then
				table.insert(excludeList, gameplay)
			end
		end
	end
	local oldMap = Workspace:FindFirstChild("Map")
	if oldMap then
		table.insert(excludeList, oldMap)
	end
	raycastParams.FilterDescendantsInstances = excludeList
	
	local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position
	end
	return position -- fallback
end

local function ensureFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local function label(parent, text, color)
	-- Remove old labels if any
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == "StudioLabel" then
			child:Destroy()
		end
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "StudioLabel"
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 150
	gui.Parent = parent

	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 0.25
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = text
	textLabel.TextColor3 = color or Color3.fromRGB(235, 230, 220)
	textLabel.TextScaled = true
	textLabel.TextWrapped = true
	textLabel.Parent = frame
end

local function createMarkerPart(folder, name, position, shape, size, color, attributes)
	-- Raycast to align to ground
	local groundPos = getGroundHeight(position)
	-- Adjust Y based on shape height
	local finalPos = groundPos + Vector3.new(0, size.Y / 2, 0)

	local part = folder:FindFirstChild(name)
	if not part then
		part = Instance.new("Part")
		part.Name = name
		part.Parent = folder
	end

	part.Anchored = true
	part.CanCollide = false
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = 0.4
	part.Position = finalPos

	-- Set attributes
	for k, v in pairs(attributes or {}) do
		part:SetAttribute(k, v)
	end

	return part
end

local function spawnMainGameMarkers()
	local map = getActiveMap("MainGameMap")
	local gameplay = ensureFolder(map, "Gameplay")
	
	local checkpointsFolder = ensureFolder(gameplay, "Checkpoints")
	local cluesFolder = ensureFolder(gameplay, "Clues")
	local npcsFolder = ensureFolder(gameplay, "NPCs")
	local puzzlesFolder = ensureFolder(gameplay, "Puzzles")
	local jimpitanFolder = ensureFolder(gameplay, "JimpitanSpawns")
	local interactablesFolder = ensureFolder(gameplay, "Interactables")

	print("Spawning Checkpoints...")
	for id, pos in pairs(WorldData.Village.Checkpoints) do
		local part = createMarkerPart(checkpointsFolder, id, pos, Enum.PartType.Cylinder, Vector3.new(0.3, 6, 6), Color3.fromRGB(232, 168, 85), {
			[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.Checkpoint,
			[AttributeConstants.Attributes.CheckpointId] = id
		})
		part.Orientation = Vector3.new(0, 0, 90) -- lay flat on ground
		label(part, "CHECKPOINT\n" .. id, Color3.fromRGB(232, 168, 85))
	end

	print("Spawning NPCs...")
	for _, npc in ipairs(WorldData.Village.NPCs) do
		local part = createMarkerPart(npcsFolder, npc.id, npc.position, Enum.PartType.Block, Vector3.new(2, 5.5, 0.4), Color3.fromRGB(90, 130, 110), {
			[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.NPC,
			[AttributeConstants.Attributes.NPCId] = npc.id
		})
		label(part, "NPC\n" .. npc.id, Color3.fromRGB(90, 130, 110))
	end

	print("Spawning Clues...")
	for _, clue in ipairs(WorldData.Village.Clues) do
		local part = createMarkerPart(cluesFolder, clue.id, clue.position, Enum.PartType.Ball, Vector3.new(1, 1, 1), Color3.fromRGB(140, 200, 235), {
			[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.Clue,
			[AttributeConstants.Attributes.ClueId] = clue.id
		})
		label(part, "CLUE\n" .. clue.id, Color3.fromRGB(140, 200, 235))
	end

	print("Spawning Puzzles...")
	for _, puzzle in ipairs(WorldData.Village.Puzzles) do
		local part = createMarkerPart(puzzlesFolder, puzzle.id, puzzle.position, Enum.PartType.Block, Vector3.new(1.6, 1.6, 1.6), Color3.fromRGB(170, 120, 220), {
			[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.Puzzle,
			[AttributeConstants.Attributes.PuzzleId] = puzzle.id
		})
		label(part, "PUZZLE\n" .. puzzle.id, Color3.fromRGB(170, 120, 220))
	end

	print("Spawning Jimpitan Spawns...")
	local offset = GameConfig.JimpitanSpawn.OffsetStuds
	for _, house in ipairs(WorldData.Village.Houses) do
		local id = house.id .. "_jimpitan"
		local position = house.position + offset
		local part = createMarkerPart(jimpitanFolder, id, position, Enum.PartType.Cylinder, Vector3.new(1.3, 1.1, 1.1), Color3.fromRGB(214, 168, 74), {
			[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.Jimpitan,
			[AttributeConstants.Attributes.JimpitanId] = id
		})
		part.Orientation = Vector3.new(0, 0, 90) -- upright cylinder
		label(part, "JIMPITAN\n" .. house.id, Color3.fromRGB(214, 168, 74))
	end

	print("Spawning Accusation Board...")
	local boardPos = WorldData.Village.Checkpoints.ending_choice
	if boardPos then
		local part = createMarkerPart(interactablesFolder, "accusation_board", boardPos + Vector3.new(6, 1, 0), Enum.PartType.Block, Vector3.new(3, 3.5, 1), Color3.fromRGB(150, 40, 40), {
			[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.AccusationBoard
		})
		label(part, "PAPAN BUKTI\naccusation_board", Color3.fromRGB(150, 40, 40))
	end

	-- Spawn main spawn location as well
	local spawnLoc = gameplay:FindFirstChild("VillageSpawn") or Instance.new("SpawnLocation")
	spawnLoc.Name = "VillageSpawn"
	spawnLoc.Size = Vector3.new(12, 1, 12)
	spawnLoc.Position = getGroundHeight(WorldData.Village.Spawn) + Vector3.new(0, 0.5, 0)
	spawnLoc.Transparency = 0.5
	spawnLoc.Anchored = true
	spawnLoc.CanCollide = false
	spawnLoc.Neutral = true
	spawnLoc.Parent = gameplay
	label(spawnLoc, "SPAWN LOCATION", Color3.fromRGB(205, 239, 244))

	print("MainGameMap markers spawned successfully!")
end

local function spawnLobbyMarkers()
	local map = getActiveMap("LobbyMap")
	local gameplay = ensureFolder(map, "Gameplay")
	
	local queueFolder = ensureFolder(gameplay, "QueuePads")
	local structuresFolder = ensureFolder(gameplay, "Structures")

	print("Spawning Lobby Queue Pads...")
	for difficulty, pad in pairs(WorldData.Lobby.QueuePads) do
		local part = createMarkerPart(queueFolder, "QueuePad_" .. difficulty, pad.position, Enum.PartType.Cylinder, Vector3.new(0.5, 10, 10), pad.color, {
			QueueDifficulty = difficulty
		})
		part.Orientation = Vector3.new(0, 0, 90) -- flat disc
		label(part, pad.label, pad.color)
	end

	print("Spawning Notice Board...")
	local notice = WorldData.Lobby.Structures[2] -- notice_board
	if notice then
		local part = createMarkerPart(structuresFolder, notice.id, notice.position, Enum.PartType.Block, notice.size, notice.color, {
			StructureId = notice.id
		})
		label(part, notice.label, notice.color)
	end

	-- Spawn lobby main spawn location
	local spawnLoc = gameplay:FindFirstChild("LobbySpawn") or Instance.new("SpawnLocation")
	spawnLoc.Name = "LobbySpawn"
	spawnLoc.Size = Vector3.new(12, 1, 12)
	spawnLoc.Position = getGroundHeight(WorldData.Lobby.Spawn) + Vector3.new(0, 0.5, 0)
	spawnLoc.Transparency = 0.5
	spawnLoc.Anchored = true
	spawnLoc.CanCollide = false
	spawnLoc.Neutral = true
	spawnLoc.Parent = gameplay
	label(spawnLoc, "LOBBY SPAWN", Color3.fromRGB(205, 239, 244))

	print("LobbyMap markers spawned successfully!")
end

return function(target)
	if target == "MainGameMap" then
		spawnMainGameMarkers()
	elseif target == "LobbyMap" then
		spawnLobbyMarkers()
	else
		spawnMainGameMarkers()
		spawnLobbyMarkers()
	end
	return "Execution finished!"
end
