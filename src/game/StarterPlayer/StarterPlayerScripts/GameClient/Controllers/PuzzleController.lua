-- StarterPlayerScripts/GameClient/Controllers/PuzzleController.lua
-- Generic overlay for PuzzleService's multiple-choice "observation" puzzle type.
-- Adding a new PuzzleId on the server needs zero changes here -- this Controller only
-- ever renders whatever `question`/`options` Puzzle/Data sends.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteRegistry = require(Modules.Net.RemoteRegistry)
local UIKit = require(script.Parent.Parent.UI.UIKit)

local PuzzleController = {}
local player = Players.LocalPlayer

function PuzzleController.Start()
	local gui = UIKit.NewScreenGui("PuzzleGui")
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local root = UIKit.NewFrame({
		Name = "Root",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.45, 0.45),
	})

	local question = UIKit.NewLabel({
		Name = "Title",
		Parent = root,
		Font = UIKit.Font.Heading,
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(1, -20, 0, 60),
		TextWrapped = true,
	})

	local optionsHolder = Instance.new("Frame")
	optionsHolder.Name = "ChoiceList"
	optionsHolder.BackgroundTransparency = 1
	optionsHolder.Position = UDim2.new(0, 10, 0, 80)
	optionsHolder.Size = UDim2.new(1, -20, 1, -140)
	optionsHolder.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = optionsHolder

	local feedback = UIKit.NewLabel({
		Name = "Feedback",
		Parent = root,
		Position = UDim2.new(0, 10, 1, -50),
		Size = UDim2.new(1, -20, 0, 40),
		TextColor3 = UIKit.Palette.LanternOrange,
	})

	local hintBadge = UIKit.NewLabel({
		Name = "HintBadge",
		Parent = root,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(28, 28),
		Text = "💡",
		Visible = false,
	})

	local currentPuzzleId = nil

	RemoteRegistry.Get("Puzzle/Data").OnClientEvent:Connect(function(data)
		gui.Enabled = true
		currentPuzzleId = data.puzzleId
		question.Text = data.question
		feedback.Text = ""

		for _, child in ipairs(optionsHolder:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		for _, option in ipairs(data.options) do
			local button = UIKit.NewButton({
				Name = "Option_" .. option.id,
				Parent = optionsHolder,
				Text = option.text,
				Size = UDim2.new(1, 0, 0, 34),
			})
			button.MouseButton1Click:Connect(function()
				RemoteRegistry.Get("Puzzle/Submit"):FireServer({
					puzzleId = currentPuzzleId,
					answer = option.id,
				})
			end)
		end
	end)

	RemoteRegistry.Get("Puzzle/Result").OnClientEvent:Connect(function(data)
		if data.success then
			feedback.Text = "Benar! Petunjuk baru ditambahkan ke jurnal."
			feedback.TextColor3 = Color3.fromRGB(120, 200, 140)
		else
			feedback.Text = "Sepertinya bukan itu. Coba amati lagi lain kali."
			feedback.TextColor3 = UIKit.Palette.FearedRed
		end
		task.delay(1.5, function()
			gui.Enabled = false
		end)
	end)

	RemoteRegistry.Get("Checkpoint/HintUnlocked").OnClientEvent:Connect(function()
		hintBadge.Visible = true
	end)
end

return PuzzleController
