-- ServerScriptService/GameServer/Services/JimpitanSpawnerService.lua
-- Auto-spawns one glowing, animated jimpitan pickup near each house in
-- WorldData.Village.Houses -- this is what makes "which jimpitan do I take" obvious
-- without the environment team hand-placing anything. Idempotent (MarkerBuilder skips
-- creation if a same-named part already exists), so hand-placed/hand-edited jimpitan
-- cans are never overwritten on a later server start.
--
-- Owns the full pickup lifecycle: collect -> hide -> respawn after a cooldown -- and
-- broadcasts the active spawn list to every client so the minimap can show them
-- (Free-Fire-style loot blips), since jimpitan spawns are shared/global, not per-player.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local WorldData = require(Modules.Data.WorldData)
local AttributeConstants = require(Modules.Util.AttributeConstants)
local MarkerBuilder = require(Modules.Util.MarkerBuilder)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local JimpitanSpawnerService = {}

local spawnPartsById = {} -- [jimpitanId] = part
local collectedSet = {} -- [part] = true while on cooldown
local Services

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- cylinders lie on their side by default

local function getOrCreateFolder()
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
	local folder = gameplay:FindFirstChild("JimpitanSpawns")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "JimpitanSpawns"
		folder.Parent = gameplay
	end
	return folder
end

local function spawnAll()
	local folder = getOrCreateFolder()
	if not folder then
		warn("[JimpitanSpawnerService] Active map gameplay folder not found -- no jimpitan spawned.")
		return
	end

	local offset = GameConfig.JimpitanSpawn.OffsetStuds
	for _, house in ipairs(WorldData.Village.Houses) do
		local id = house.id .. "_jimpitan"
		local position = house.position + offset
		local part = MarkerBuilder.EnsureMarker(folder, id, {
			Position = position,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.3, 1.1, 1.1),
			Color = Color3.fromRGB(214, 168, 74),
			Material = Enum.Material.Metal,
			Icon = "\240\159\170\153",
			ActionText = "Ambil",
			ObjectText = "Jimpitan",
			MaxActivationDistance = 8,
			ExtraRotation = UPRIGHT,
			Attributes = {
				[AttributeConstants.Attributes.InteractionType] = AttributeConstants.InteractionType.Jimpitan,
				[AttributeConstants.Attributes.JimpitanId] = id,
			},
		})
		spawnPartsById[id] = part
	end
end

function JimpitanSpawnerService.Init(services)
	Services = services
	task.spawn(spawnAll)
end

function JimpitanSpawnerService.GetActiveSpawns()
	local list = {}
	for id, part in pairs(spawnPartsById) do
		if part.Parent and not collectedSet[part] then
			local pos = part.Position
			table.insert(list, { id = id, x = pos.X, y = pos.Y, z = pos.Z })
		end
	end
	return list
end

function JimpitanSpawnerService.BroadcastSpawns()
	RemoteRegistry.Get("Jimpitan/Spawns"):FireAllClients({ spawns = JimpitanSpawnerService.GetActiveSpawns() })
end

-- Called once when a player joins, so they see currently-active spawns immediately
-- instead of waiting for the next collect/respawn event to trigger a broadcast.
function JimpitanSpawnerService.SendSnapshot(player)
	RemoteRegistry.Get("Jimpitan/Spawns"):FireClient(player, { spawns = JimpitanSpawnerService.GetActiveSpawns() })
end

-- Called by InteractionService when a `jimpitan_can` ProximityPrompt is triggered.
function JimpitanSpawnerService.Collect(player, part)
	if collectedSet[part] then
		return
	end
	collectedSet[part] = true

	Services.ObjectiveService.AddCarriedJimpitan(player, 1)

	part.Transparency = 1
	local icon = part:FindFirstChild("Icon")
	if icon then
		icon.Enabled = false
	end
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end

	JimpitanSpawnerService.BroadcastSpawns()

	task.delay(GameConfig.JimpitanSpawn.RespawnDelaySeconds, function()
		if not part or not part.Parent then
			return
		end
		part.Transparency = 0
		if icon then
			icon.Enabled = true
		end
		if prompt then
			prompt.Enabled = true
		end
		collectedSet[part] = nil
		JimpitanSpawnerService.BroadcastSpawns()
	end)
end

return JimpitanSpawnerService
