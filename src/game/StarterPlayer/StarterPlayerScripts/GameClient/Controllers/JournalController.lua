-- StarterPlayerScripts/GameClient/Controllers/JournalController.lua
-- Clue journal. Toggled with the J key. Clones one template Label per clue entry
-- (ROBLOX_UI_SKILL.md §5 -- never hand-place duplicates).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)
local UIKit = require(script.Parent.Parent.UI.UIKit)

local JournalController = {}
local player = Players.LocalPlayer

function JournalController.Start()
	local gui = UIKit.NewScreenGui("JournalGui")
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local root = UIKit.NewFrame({
		Name = "Root",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.4, 0.6),
		BackgroundTransparency = 0.05,
	})

	UIKit.NewLabel({
		Name = "Title",
		Parent = root,
		Text = "Jurnal Petunjuk",
		Font = UIKit.Font.Heading,
		Position = UDim2.new(0, 10, 0, 5),
		Size = UDim2.new(1, -20, 0, 34),
	})

	local list = Instance.new("ScrollingFrame")
	list.Name = "ChoiceList"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.new(0, 10, 0, 50)
	list.Size = UDim2.new(1, -20, 1, -60)
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 6
	list.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	local template = UIKit.NewLabel({
		Name = "EntryTemplate",
		Parent = nil,
		Size = UDim2.new(1, 0, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	})

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.J then
			gui.Enabled = not gui.Enabled
		end
	end)

	RemoteRegistry.Get("Investigation/ClueAdded").OnClientEvent:Connect(function(data)
		local entry = template:Clone()
		entry.Name = "Entry_" .. data.clueId
		entry.Text = "\226\128\162 " .. data.text
		entry.Parent = list
		UIKit.PlaySound(GameConfig.Audio.ClueFound, 0.5)
	end)
end

return JournalController
