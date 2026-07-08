-- StarterPlayerScripts/GameClient/Controllers/EndingController.lua
-- Full-screen ending display. The server only ever sends an `endingId`; this Controller
-- resolves the Title/Text by requiring the shared NarrativeData module directly (it's
-- replicated, read-only reference data -- not a gameplay decision) rather than the
-- server pushing full text over the Remote every time.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local NarrativeData = require(Modules.NarrativeData)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)
local UIKit = require(script.Parent.Parent.UI.UIKit)

local EndingController = {}
local player = Players.LocalPlayer

function EndingController.Start()
	local gui = UIKit.NewScreenGui("EndingGui")
	gui.Enabled = false
	gui.DisplayOrder = 50
	gui.Parent = player:WaitForChild("PlayerGui")

	local root = UIKit.NewFrame({
		Name = "Root",
		Parent = gui,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0,
		BackgroundColor3 = UIKit.Palette.MoonlightBlue,
		CornerRadius = UDim.new(0, 0),
	})

	local title = UIKit.NewLabel({
		Name = "Title",
		Parent = root,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromScale(0.6, 0.08),
		Font = UIKit.Font.Heading,
	})

	local body = UIKit.NewLabel({
		Name = "Body",
		Parent = root,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.5, 0.2),
		Font = UIKit.Font.Narrative,
		TextColor3 = UIKit.Palette.TextMuted,
		TextWrapped = true,
	})

	local closeButton = UIKit.NewButton({
		Name = "CloseButton",
		Parent = root,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.68),
		Size = UDim2.fromScale(0.2, 0.06),
		Text = "Lanjutkan",
	})
	closeButton.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)

	RemoteRegistry.Get("Accusation/Result").OnClientEvent:Connect(function(data)
		if not data.endingId then
			return
		end
		local ending = NarrativeData.Endings[data.endingId]
		if not ending then
			warn("[EndingController] Unknown endingId:", data.endingId)
			return
		end
		title.Text = ending.Title
		body.Text = ending.Text
		gui.Enabled = true
	end)
end

return EndingController
