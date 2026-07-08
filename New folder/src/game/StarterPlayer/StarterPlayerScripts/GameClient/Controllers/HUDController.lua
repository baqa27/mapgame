-- StarterPlayerScripts/GameClient/Controllers/HUDController.lua
-- Always-visible HUD: Free-Fire-style circular minimap (top-left, local windowed view,
-- rotating player arrow, jimpitan/checkpoint/NPC/puzzle blips), objective step tracker
-- just under it, night countdown clock top-center, trust indicator top-right.
--
-- Clue locations are deliberately NOT shown on the minimap -- revealing them would
-- trivialize the investigation loop (DESIGN_BRIEF.md's horror rules want "was the clue
-- real?" to stay uncertain, which requires the player to actually go looking).
--
-- Static markers (checkpoints/NPCs/puzzles) come straight from the shared WorldData
-- module -- that's just world geometry, not a game secret, so no Remote is needed for
-- them. Jimpitan spawns change at runtime (collected/respawned) so those come from the
-- `Jimpitan/Spawns` Remote, broadcast by JimpitanSpawnerService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local WorldData = require(Modules.Data.WorldData)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local UIKit = require(script.Parent.Parent.UI.UIKit)

local HUDController = {}
local player = Players.LocalPlayer

local TRUST_DISPLAY = {
	trusted = { text = "Dipercaya", color = Color3.fromRGB(120, 200, 140) },
	neutral = { text = "Netral", color = nil },
	suspicious = { text = "Dicurigai", color = Color3.fromRGB(210, 150, 60) },
	feared = { text = "Ditakuti", color = nil },
}

local MARKER_STYLE = {
	jimpitan = { icon = "\240\159\170\153", color = Color3.fromRGB(232, 190, 90), size = 14 },
	checkpoint = { icon = "\240\159\143\174", color = Color3.fromRGB(120, 170, 220), size = 12 },
	npc = { icon = "\226\151\143", color = Color3.fromRGB(140, 210, 150), size = 10 },
	puzzle = { icon = "\226\151\134", color = Color3.fromRGB(190, 140, 230), size = 10 },
}

local function formatClock(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

function HUDController.Start()
	TRUST_DISPLAY.neutral.color = UIKit.Palette.LanternOrange
	TRUST_DISPLAY.feared.color = UIKit.Palette.FearedRed

	local gui = UIKit.NewScreenGui("HUDGui")
	gui.Parent = player:WaitForChild("PlayerGui")

	----------------------------------------------------------------------------------
	-- Minimap (top-left, circular, FF-style)
	----------------------------------------------------------------------------------
	local minimapSize = UDim2.fromScale(0.18, 0.32)
	local minimapOuter = UIKit.NewCircle({
		Name = "Minimap",
		Parent = gui,
		Position = UDim2.fromScale(0.02, 0.03),
		Size = minimapSize,
		BackgroundColor3 = UIKit.Palette.PanelBlue,
		BackgroundTransparency = 0.05,
		ChromeOptions = { StrokeThickness = 2, StrokeTransparency = 0.1, Gradient = false },
	})
	minimapOuter.ClipsDescendants = true

	local compassLabel = UIKit.NewLabel({
		Name = "Compass",
		Parent = minimapOuter,
		Position = UDim2.fromScale(0.5, 0.04),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		Text = "U",
		Font = UIKit.Font.Heading,
		TextColor3 = UIKit.Palette.TextMuted,
		ZIndex = 5,
	})

	local playerArrow = UIKit.NewLabel({
		Name = "PlayerArrow",
		Parent = minimapOuter,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(20, 20),
		Text = "\226\150\178",
		TextColor3 = UIKit.Palette.LanternOrange,
		Font = UIKit.Font.Heading,
		Shadow = true,
		ZIndex = 6,
	})

	-- Static markers (checkpoints, NPCs, puzzles) built once from WorldData.
	local staticMarkers = {}
	local function addStaticMarker(kind, worldPosition)
		local style = MARKER_STYLE[kind]
		local dot = UIKit.NewLabel({
			Name = kind .. "Marker",
			Parent = minimapOuter,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(style.size, style.size),
			Text = style.icon,
			TextColor3 = style.color,
			Visible = false,
			ZIndex = 3,
		})
		table.insert(staticMarkers, { kind = kind, position = worldPosition, gui = dot })
	end

	for _, checkpointPosition in pairs(WorldData.Village.Checkpoints) do
		addStaticMarker("checkpoint", checkpointPosition)
	end
	for _, npc in ipairs(WorldData.Village.NPCs) do
		addStaticMarker("npc", npc.position)
	end
	for _, puzzle in ipairs(WorldData.Village.Puzzles) do
		addStaticMarker("puzzle", puzzle.position)
	end

	-- Dynamic jimpitan markers, rebuilt whenever Jimpitan/Spawns fires.
	local jimpitanMarkers = {}
	local function rebuildJimpitanMarkers(spawns)
		for _, marker in ipairs(jimpitanMarkers) do
			marker.gui:Destroy()
		end
		jimpitanMarkers = {}
		local style = MARKER_STYLE.jimpitan
		for _, spawn in ipairs(spawns) do
			local dot = UIKit.NewLabel({
				Name = "JimpitanMarker",
				Parent = minimapOuter,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(style.size, style.size),
				Text = style.icon,
				TextColor3 = style.color,
				Visible = false,
				ZIndex = 4,
			})
			table.insert(jimpitanMarkers, { position = Vector3.new(spawn.x, spawn.y, spawn.z), gui = dot })
		end
	end

	RemoteRegistry.Get("Jimpitan/Spawns").OnClientEvent:Connect(function(data)
		rebuildJimpitanMarkers(data.spawns or {})
	end)

	-- North-up minimap: only the player arrow rotates to show facing. dx maps to
	-- east/west (left/right), dz maps to north/south (up/down) with -Z treated as
	-- "north" (up on screen) -- flip this mapping here if the built map's compass
	-- convention ends up being different once the environment team finalizes it.
	local radius = GameConfig.Minimap.WorldRadiusStuds
	local function updateMarker(entry)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root then
			entry.gui.Visible = false
			return
		end
		local dx = entry.position.X - root.Position.X
		local dz = entry.position.Z - root.Position.Z
		local dist = math.sqrt(dx * dx + dz * dz)
		if dist > radius then
			entry.gui.Visible = false
			return
		end
		entry.gui.Visible = true
		entry.gui.Position = UDim2.fromScale(0.5 + (dx / radius) * 0.5, 0.5 + (dz / radius) * 0.5)
	end

	RunService.Heartbeat:Connect(function()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local look = root.CFrame.LookVector
			local yawDegrees = math.deg(math.atan2(look.X, -look.Z))
			playerArrow.Rotation = yawDegrees
		end
		for _, entry in ipairs(staticMarkers) do
			updateMarker(entry)
		end
		for _, entry in ipairs(jimpitanMarkers) do
			updateMarker(entry)
		end
	end)

	----------------------------------------------------------------------------------
	-- Objective tracker (just under the minimap)
	----------------------------------------------------------------------------------
	local objectiveFrame = UIKit.NewFrame({
		Name = "Objective",
		Parent = gui,
		Position = UDim2.fromScale(0.02, 0.365),
		Size = UDim2.fromScale(0.24, 0.09),
	})
	local objectiveTitle = UIKit.NewLabel({
		Name = "Title",
		Parent = objectiveFrame,
		Position = UDim2.new(0, 8, 0, 4),
		Size = UDim2.new(1, -16, 0.5, 0),
		Font = UIKit.Font.Heading,
		Text = "Memuat tugas...",
	})
	local objectiveProgress = UIKit.NewLabel({
		Name = "Progress",
		Parent = objectiveFrame,
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(1, -16, 0.3, 0),
		TextColor3 = UIKit.Palette.TextMuted,
		MaxTextSize = 16,
	})
	local carriedLabel = UIKit.NewLabel({
		Name = "Carried",
		Parent = objectiveFrame,
		Position = UDim2.new(0, 8, 0.8, 0),
		Size = UDim2.new(1, -16, 0.2, 0),
		Text = "",
		TextColor3 = UIKit.Palette.LanternOrange,
		MaxTextSize = 14,
	})

	----------------------------------------------------------------------------------
	-- Night clock (top-center)
	----------------------------------------------------------------------------------
	local clockFrame = UIKit.NewFrame({
		Name = "NightClock",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.03),
		Size = UDim2.fromScale(0.12, 0.06),
	})
	local clockLabel = UIKit.NewLabel({
		Name = "Label",
		Parent = clockFrame,
		Text = "--:--",
		Font = UIKit.Font.Heading,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	----------------------------------------------------------------------------------
	-- Trust indicator (top-right)
	----------------------------------------------------------------------------------
	local trustFrame = UIKit.NewFrame({
		Name = "Trust",
		Parent = gui,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.98, 0.03),
		Size = UDim2.fromScale(0.2, 0.07),
	})
	local trustLabel = UIKit.NewLabel({
		Name = "Label",
		Parent = trustFrame,
		Text = TRUST_DISPLAY.neutral.text,
		TextColor3 = TRUST_DISPLAY.neutral.color,
		Font = UIKit.Font.Heading,
	})

	----------------------------------------------------------------------------------
	-- Remote wiring
	----------------------------------------------------------------------------------
	RemoteRegistry.Get("Objective/StateChanged").OnClientEvent:Connect(function(data)
		if data.chainComplete then
			objectiveTitle.Text = data.title
			objectiveProgress.Text = data.description
		else
			objectiveTitle.Text = string.format("%s (Tahap %d/%d)", data.title, data.stepIndex, data.stepCount)
			objectiveProgress.Text = string.format("%s -- %d/%d", data.description, data.progress, data.target)
		end
		carriedLabel.Text = (data.carried or 0) > 0 and string.format("Dibawa: %d (belum disetor)", data.carried) or ""
	end)

	RemoteRegistry.Get("Trust/StateChanged").OnClientEvent:Connect(function(data)
		local display = TRUST_DISPLAY[data.state] or TRUST_DISPLAY.neutral
		trustLabel.Text = display.text
		trustLabel.TextColor3 = display.color
	end)

	RemoteRegistry.Get("Night/TimeUpdated").OnClientEvent:Connect(function(data)
		clockLabel.Text = formatClock(data.secondsRemaining)
		clockLabel.TextColor3 = data.secondsRemaining <= 60 and UIKit.Palette.FearedRed or UIKit.Palette.TextLight
	end)
end

return HUDController
