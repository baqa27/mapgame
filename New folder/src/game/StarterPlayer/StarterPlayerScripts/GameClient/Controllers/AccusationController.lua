-- StarterPlayerScripts/GameClient/Controllers/AccusationController.lua
-- Suspect picker + confirm step. Shows each suspect's profile blurb (from
-- InvestigationData via the Accusation/Open payload) so the board reads like an actual
-- case file, not just a list of names. The Confirm button stays disabled until a suspect
-- is selected, so there's no accidental one-click accusation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)
local UIKit = require(script.Parent.Parent.UI.UIKit)

local AccusationController = {}
local player = Players.LocalPlayer

function AccusationController.Start()
	local gui = UIKit.NewScreenGui("AccusationGui")
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local root = UIKit.NewFrame({
		Name = "Root",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.46, 0.6),
	})

	UIKit.NewLabel({
		Name = "Title",
		Parent = root,
		Text = "Siapa pelakunya?",
		Font = UIKit.Font.Heading,
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(1, -20, 0, 30),
	})

	local list = Instance.new("ScrollingFrame")
	list.Name = "ChoiceList"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.new(0, 10, 0, 50)
	list.Size = UDim2.new(1, -20, 1, -110)
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 6
	list.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = list

	local feedback = UIKit.NewLabel({
		Name = "Feedback",
		Parent = root,
		Position = UDim2.new(0, 10, 1, -70),
		Size = UDim2.new(1, -20, 0, 24),
		TextColor3 = UIKit.Palette.TextMuted,
	})

	local confirmButton = UIKit.NewButton({
		Name = "CloseButton", -- role: confirm/close action
		Parent = root,
		Text = "Konfirmasi Tuduhan",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -20, 0, 36),
		BackgroundColor3 = UIKit.Palette.MoonlightBlue,
	})
	confirmButton.Active = false
	confirmButton.AutoButtonColor = false

	local selectedId = nil
	local selectedCard = nil

	local function refreshConfirmState()
		confirmButton.Active = selectedId ~= nil
		confirmButton.AutoButtonColor = selectedId ~= nil
		confirmButton.BackgroundColor3 = selectedId and UIKit.Palette.FearedRed or UIKit.Palette.MoonlightBlue
	end

	confirmButton.MouseButton1Click:Connect(function()
		if not selectedId then
			return
		end
		RemoteRegistry.Get("Accusation/Submit"):FireServer({ suspectId = selectedId })
	end)

	RemoteRegistry.Get("Accusation/Open").OnClientEvent:Connect(function(data)
		gui.Enabled = true
		selectedId = nil
		selectedCard = nil
		feedback.Text = ""
		refreshConfirmState()

		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		for _, suspect in ipairs(data.suspects) do
			local card = UIKit.NewFrame({
				Name = "Card_" .. suspect.id,
				Parent = list,
				Size = UDim2.new(1, 0, 0, 62),
				BackgroundColor3 = UIKit.Palette.PanelBlueLight,
			})

			UIKit.NewLabel({
				Name = "Name",
				Parent = card,
				Position = UDim2.new(0, 10, 0, 4),
				Size = UDim2.new(1, -20, 0, 22),
				Text = suspect.name,
				Font = UIKit.Font.Heading,
			})
			UIKit.NewLabel({
				Name = "Profile",
				Parent = card,
				Position = UDim2.new(0, 10, 0, 26),
				Size = UDim2.new(1, -20, 0, 32),
				Text = suspect.profile or "",
				TextColor3 = UIKit.Palette.TextMuted,
				TextWrapped = true,
				MaxTextSize = 14,
			})

			local clickCatcher = Instance.new("TextButton")
			clickCatcher.BackgroundTransparency = 1
			clickCatcher.Text = ""
			clickCatcher.Size = UDim2.fromScale(1, 1)
			clickCatcher.Parent = card

			clickCatcher.MouseButton1Click:Connect(function()
				selectedId = suspect.id
				if selectedCard then
					selectedCard.BackgroundColor3 = UIKit.Palette.PanelBlueLight
				end
				card.BackgroundColor3 = UIKit.Palette.LanternOrange
				selectedCard = card
				refreshConfirmState()
			end)
		end
	end)

	RemoteRegistry.Get("Accusation/Result").OnClientEvent:Connect(function(data)
		if data.outcome == "not_enough_clues" then
			feedback.Text = "Kamu butuh lebih banyak bukti sebelum menuduh."
			feedback.TextColor3 = UIKit.Palette.TextMuted
		elseif data.outcome == "wrong" then
			feedback.Text = "Sepertinya bukan dia..."
			feedback.TextColor3 = UIKit.Palette.FearedRed
			gui.Enabled = false
		else
			UIKit.PlaySound(GameConfig.Audio.Kentongan, 0.7)
			gui.Enabled = false
		end
	end)
end

return AccusationController
