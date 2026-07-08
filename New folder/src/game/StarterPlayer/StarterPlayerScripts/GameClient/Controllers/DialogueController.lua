-- StarterPlayerScripts/GameClient/Controllers/DialogueController.lua
-- Renders whatever node DialogueService sends. Locked choices are rendered using the
-- `locked`/`lockedReason` fields the server already computed -- this Controller never
-- infers lock state itself (ROBLOX_UI_SKILL.md §6).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteRegistry = require(Modules.Net.RemoteRegistry)
local UIKit = require(script.Parent.Parent.UI.UIKit)

local DialogueController = {}
local player = Players.LocalPlayer

function DialogueController.Start()
	local gui = UIKit.NewScreenGui("DialogueGui")
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local root = UIKit.NewFrame({
		Name = "Root",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.95),
		Size = UDim2.fromScale(0.6, 0.32),
	})

	local npcName = UIKit.NewLabel({
		Name = "Title",
		Parent = root,
		Font = UIKit.Font.Heading,
		Position = UDim2.new(0, 10, 0, 5),
		Size = UDim2.new(1, -20, 0, 28),
	})

	local bodyText = UIKit.NewLabel({
		Name = "Body",
		Parent = root,
		Font = UIKit.Font.Narrative,
		Position = UDim2.new(0, 10, 0, 38),
		Size = UDim2.new(1, -20, 0, 60),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	})

	local choicesHolder = Instance.new("Frame")
	choicesHolder.Name = "ChoiceList"
	choicesHolder.BackgroundTransparency = 1
	choicesHolder.Position = UDim2.new(0, 10, 0, 102)
	choicesHolder.Size = UDim2.new(1, -20, 1, -112)
	choicesHolder.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = choicesHolder

	local currentNodeId = nil

	local function render(data)
		gui.Enabled = true
		currentNodeId = data.nodeId
		npcName.Text = data.npcName
		bodyText.Text = data.text

		for _, child in ipairs(choicesHolder:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		for _, choice in ipairs(data.choices) do
			local button = UIKit.NewButton({
				Name = "Choice_" .. choice.id,
				Parent = choicesHolder,
				Text = choice.locked and (choice.text .. "  🔒") or choice.text,
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = choice.locked and UIKit.Palette.MoonlightBlue or UIKit.Palette.PanelBlue,
				TextColor3 = choice.locked and UIKit.Palette.TextMuted or UIKit.Palette.TextLight,
			})
			button.AutoButtonColor = not choice.locked
			button.Active = not choice.locked

			button.MouseButton1Click:Connect(function()
				if choice.locked then
					return
				end
				RemoteRegistry.Get("Dialogue/Choose"):FireServer({
					nodeId = currentNodeId,
					choiceId = choice.id,
				})
			end)
		end

		if #data.choices == 0 then
			task.delay(2.5, function()
				if currentNodeId == data.nodeId then
					gui.Enabled = false
				end
			end)
		end
	end

	RemoteRegistry.Get("Dialogue/Node").OnClientEvent:Connect(render)
end

return DialogueController
