-- StarterPlayerScripts/GameClient/Controllers/AccusationController.lua
-- Suspect picker + confirm step. The Confirm button stays disabled until a suspect is
-- selected, so there's no accidental one-click accusation (per MAIN_GAME_SYSTEM_RULES.md
-- §9 UI inventory notes).

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
		Size = UDim2.fromScale(0.4, 0.55),
	})

	UIKit.NewLabel({
		Name = "Title",
		Parent = root,
		Text = "Siapa pelakunya?",
		Font = UIKit.Font.Heading,
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(1, -20, 0, 30),
	})

	local list = Instance.new("Frame")
	list.Name = "ChoiceList"
	list.BackgroundTransparency = 1
	list.Position = UDim2.new(0, 10, 0, 50)
	list.Size = UDim2.new(1, -20, 1, -110)
	list.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
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
		feedback.Text = ""
		refreshConfirmState()

		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		for _, suspect in ipairs(data.suspects) do
			local button = UIKit.NewButton({
				Name = "Suspect_" .. suspect.id,
				Parent = list,
				Text = suspect.name,
				Size = UDim2.new(1, 0, 0, 34),
			})
			button.MouseButton1Click:Connect(function()
				selectedId = suspect.id
				for _, sibling in ipairs(list:GetChildren()) do
					if sibling:IsA("TextButton") then
						sibling.BackgroundColor3 = UIKit.Palette.PanelBlue
					end
				end
				button.BackgroundColor3 = UIKit.Palette.LanternOrange
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
