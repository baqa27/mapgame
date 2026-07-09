--!strict
-- Client-side minimap: top-right square panel showing player dot position
-- relative to the full village map. Static blips for houses, Pos Ronda, and
-- ritual area. Updated at ~8 fps to save render budget.
--
-- NOTE: HUDController also renders a circular minimap (Free-Fire style) using
-- UIKit. This MinimapController is the simpler square fallback that was built
-- first in Studio. If HUDController.Start() is running, this controller is
-- NOT started (see Bootstrap.client.lua). Only one minimap renders at a time.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local WorldData = require(Modules:WaitForChild("Data"):WaitForChild("WorldData"))

local MinimapController = {}

local playerDot: Frame
local mapFrame: Frame
local lastUpdate = 0
local mapSize = 190
local worldSize = WorldData.Map.size
local worldHalf = WorldData.Map.halfSize

local function corner(parent: GuiObject, radius: number?)
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, radius or 8)
	uiCorner.Parent = parent
end

local function marker(parent: Instance, name: string, position: Vector3, color: Color3, size: number)
	local dot = Instance.new("Frame")
	dot.Name = name
	dot.Size = UDim2.fromOffset(size, size)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.BackgroundColor3 = color
	dot.Position = UDim2.fromOffset(((position.X + worldHalf) / worldSize) * mapSize, ((position.Z + worldHalf) / worldSize) * mapSize)
	dot.Parent = parent
	corner(dot, size)
end

local function buildUi()
	local old = playerGui:FindFirstChild("JimpitanMinimap")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "JimpitanMinimap"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	mapFrame = Instance.new("Frame")
	mapFrame.AnchorPoint = Vector2.new(1, 0)
	mapFrame.Position = UDim2.new(1, -24, 0, 24)
	mapFrame.Size = UDim2.fromOffset(mapSize, mapSize)
	mapFrame.BackgroundColor3 = Color3.fromRGB(9, 13, 15)
	mapFrame.BackgroundTransparency = 0.12
	mapFrame.ClipsDescendants = true
	mapFrame.Parent = gui
	corner(mapFrame, 8)

	for _, house in ipairs(WorldData.Village.Houses) do
		marker(mapFrame, house.id, house.position, Color3.fromRGB(151, 125, 88), 6)
	end
	marker(mapFrame, "PosRonda", WorldData.Village.Areas.pos_ronda, Color3.fromRGB(236, 214, 155), 8)
	marker(mapFrame, "Ritual", WorldData.Village.Areas.ritual, Color3.fromRGB(141, 65, 82), 7)

	playerDot = Instance.new("Frame")
	playerDot.Name = "PlayerDot"
	playerDot.Size = UDim2.fromOffset(8, 8)
	playerDot.AnchorPoint = Vector2.new(0.5, 0.5)
	playerDot.BackgroundColor3 = Color3.fromRGB(215, 238, 229)
	playerDot.Parent = mapFrame
	corner(playerDot, 8)
end

local function updateDot()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	local x = math.clamp(((root.Position.X + worldHalf) / worldSize) * mapSize, 8, mapSize - 8)
	local y = math.clamp(((root.Position.Z + worldHalf) / worldSize) * mapSize, 8, mapSize - 8)
	playerDot.Position = UDim2.fromOffset(x, y)
end

function MinimapController.Start()
	buildUi()
	RunService.RenderStepped:Connect(function()
		if os.clock() - lastUpdate < 0.12 then
			return
		end
		lastUpdate = os.clock()
		updateDot()
	end)
end

return MinimapController
