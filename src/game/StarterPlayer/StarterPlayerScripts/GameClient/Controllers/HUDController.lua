-- StarterPlayerScripts/GameClient/Controllers/HUDController.lua
-- Always-visible HUD: objective tracker (carried + deposited jimpitan), trust indicator,
-- night countdown clock, and a simple XZ-projection minimap blip. The minimap background
-- is a plain panel for now -- swap in a real top-down map ImageLabel once the
-- environment team exports one (see README_IMPLEMENTATION.md). Coordinate math assumes
-- Workspace.Map is centered on world origin (0,0,0), per MAP_LEVEL_DESIGN_GUIDE.md's
-- 2048x2048 baseplate -- adjust the offset here if WorldData places it elsewhere.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local UIKit = require(script.Parent.Parent.UI.UIKit)

local HUDController = {}
local player = Players.LocalPlayer

local TRUST_DISPLAY = {
	trusted = { text = "\240\159\143\174 Dipercaya", color = Color3.fromRGB(120, 200, 140) },
	neutral = { text = "\240\159\143\174 Netral", color = nil },
	suspicious = { text = "\240\159\143\174 Dicurigai", color = Color3.fromRGB(210, 150, 60) },
	feared = { text = "\240\159\143\174 Ditakuti", color = nil },
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

	-- Objective tracker (top-left)
	local objectiveFrame = UIKit.NewFrame({
		Name = "Objective",
		Parent = gui,
		Position = UDim2.fromScale(0.02, 0.03),
		Size = UDim2.fromScale(0.3, 0.09),
	})
	local objectiveLabel = UIKit.NewLabel({
		Name = "Label",
		Parent = objectiveFrame,
		Position = UDim2.new(0, 8, 0, 2),
		Size = UDim2.new(1, -16, 0.55, 0),
		Text = "Kumpulkan jimpitan (0/0)",
	})
	local carriedLabel = UIKit.NewLabel({
		Name = "Carried",
		Parent = objectiveFrame,
		Position = UDim2.new(0, 8, 0.55, 0),
		Size = UDim2.new(1, -16, 0.4, 0),
		Text = "",
		TextColor3 = UIKit.Palette.TextMuted,
		MaxTextSize = 16,
	})

	-- Night clock (top-center) -- counts down "waktu ronda" (game_mechanics.md rule #1)
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

	-- Trust indicator (top-right)
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

	-- Minimap (bottom-right)
	local minimapFrame = UIKit.NewFrame({
		Name = "Minimap",
		Parent = gui,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.98, 0.97),
		Size = UDim2.fromScale(0.16, 0.28),
		BackgroundTransparency = 0.3,
	})

	local blip = Instance.new("Frame")
	blip.Name = "PlayerBlip"
	blip.AnchorPoint = Vector2.new(0.5, 0.5)
	blip.Size = UDim2.fromOffset(8, 8)
	blip.BackgroundColor3 = UIKit.Palette.LanternOrange
	blip.BorderSizePixel = 0
	blip.Parent = minimapFrame
	local blipCorner = Instance.new("UICorner")
	blipCorner.CornerRadius = UDim.new(1, 0)
	blipCorner.Parent = blip

	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local half = GameConfig.World.MAP_HALF_SIZE
		local nx = math.clamp((root.Position.X + half) / (half * 2), 0, 1)
		local nz = math.clamp((root.Position.Z + half) / (half * 2), 0, 1)
		blip.Position = UDim2.fromScale(nx, nz)
	end)

	RemoteRegistry.Get("Objective/StateChanged").OnClientEvent:Connect(function(data)
		objectiveLabel.Text = string.format("%s (%d/%d)", data.label, data.progress, data.target)
		carriedLabel.Text = (data.carried or 0) > 0
			and string.format("Dibawa: %d (belum disetor)", data.carried)
			or ""
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
