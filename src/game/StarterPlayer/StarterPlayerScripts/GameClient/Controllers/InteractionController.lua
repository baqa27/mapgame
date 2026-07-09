--!strict
-- Shows a floating hint label ("E - Ambil") whenever the local player's camera
-- is close to a ProximityPrompt, using ProximityPromptService events.
-- Keeps the hint centered low-screen so it never overlaps the minimap or HUD.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local InteractionController = {}

local hintLabel: TextLabel

local function buildUi()
	local old = playerGui:FindFirstChild("JimpitanInteraction")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "JimpitanInteraction"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	hintLabel = Instance.new("TextLabel")
	hintLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	hintLabel.Position = UDim2.fromScale(0.5, 0.62)
	hintLabel.Size = UDim2.fromOffset(360, 32)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Font = Enum.Font.GothamBold
	hintLabel.TextColor3 = Color3.fromRGB(238, 230, 196)
	hintLabel.TextStrokeTransparency = 0.35
	hintLabel.TextSize = 15
	hintLabel.TextTransparency = 1
	hintLabel.Parent = gui
end

function InteractionController.Start()
	buildUi()

	ProximityPromptService.PromptShown:Connect(function(prompt)
		hintLabel.Text = ("E - %s"):format(prompt.ActionText)
		hintLabel.TextTransparency = 0
	end)

	ProximityPromptService.PromptHidden:Connect(function()
		hintLabel.TextTransparency = 1
	end)
end

return InteractionController
