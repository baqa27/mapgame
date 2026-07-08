-- StarterPlayerScripts/GameClient/Controllers/PuzzleController.lua
-- Sequence-recall puzzle UI ("repeat the pattern"), matching PuzzleService/
-- InvestigationData.Puzzles. Shows `symbolCount` numbered pads, auto-plays the demo
-- sequence once (each pad flashes in order), then lets the player tap them back in the
-- same order. Adding a new PuzzleId with more/fewer symbols needs zero changes here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteRegistry = require(Modules.Net.RemoteRegistry)
local UIKit = require(script.Parent.Parent.UI.UIKit)

local PuzzleController = {}
local player = Players.LocalPlayer

local PAD_COLORS = {
	Color3.fromRGB(214, 100, 100),
	Color3.fromRGB(100, 180, 214),
	Color3.fromRGB(214, 190, 100),
	Color3.fromRGB(140, 200, 140),
	Color3.fromRGB(190, 140, 220),
}

function PuzzleController.Start()
	local gui = UIKit.NewScreenGui("PuzzleGui")
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local root = UIKit.NewFrame({
		Name = "Root",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.42, 0.48),
	})

	local title = UIKit.NewLabel({
		Name = "Title",
		Parent = root,
		Font = UIKit.Font.Heading,
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(1, -20, 0, 30),
	})

	local description = UIKit.NewLabel({
		Name = "Description",
		Parent = root,
		Position = UDim2.new(0, 10, 0, 42),
		Size = UDim2.new(1, -20, 0, 44),
		TextColor3 = UIKit.Palette.TextMuted,
		TextWrapped = true,
		MaxTextSize = 16,
	})

	local statusLabel = UIKit.NewLabel({
		Name = "Status",
		Parent = root,
		Position = UDim2.new(0, 10, 0, 90),
		Size = UDim2.new(1, -20, 0, 24),
		TextColor3 = UIKit.Palette.LanternOrange,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local padsHolder = Instance.new("Frame")
	padsHolder.Name = "ChoiceList"
	padsHolder.BackgroundTransparency = 1
	padsHolder.Position = UDim2.new(0, 10, 0, 120)
	padsHolder.Size = UDim2.new(1, -20, 1, -190)
	padsHolder.Parent = root

	local padsLayout = Instance.new("UIListLayout")
	padsLayout.FillDirection = Enum.FillDirection.Horizontal
	padsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	padsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	padsLayout.Padding = UDim.new(0, 10)
	padsLayout.Parent = padsHolder

	local feedback = UIKit.NewLabel({
		Name = "Feedback",
		Parent = root,
		Position = UDim2.new(0, 10, 1, -50),
		Size = UDim2.new(1, -20, 0, 40),
		TextColor3 = UIKit.Palette.LanternOrange,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local hintBadge = UIKit.NewLabel({
		Name = "HintBadge",
		Parent = root,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(28, 28),
		Text = "\240\159\146\161",
		Visible = false,
	})

	local currentPuzzleId = nil
	local playerInput = {}
	local acceptingInput = false

	local function flashPad(pad)
		local original = pad.BackgroundColor3
		TweenService:Create(pad, TweenInfo.new(0.15), { BackgroundColor3 = Color3.new(1, 1, 1) }):Play()
		task.delay(0.25, function()
			TweenService:Create(pad, TweenInfo.new(0.15), { BackgroundColor3 = original }):Play()
		end)
	end

	local function submitIfComplete(sequenceLength)
		if #playerInput < sequenceLength then
			return
		end
		acceptingInput = false
		RemoteRegistry.Get("Puzzle/Submit"):FireServer({ puzzleId = currentPuzzleId, answer = playerInput })
	end

	RemoteRegistry.Get("Puzzle/Data").OnClientEvent:Connect(function(data)
		gui.Enabled = true
		currentPuzzleId = data.puzzleId
		playerInput = {}
		acceptingInput = false
		title.Text = data.displayName or "Teka-teki"
		description.Text = data.description or ""
		feedback.Text = ""
		statusLabel.Text = "Perhatikan urutannya..."

		for _, child in ipairs(padsHolder:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local pads = {}
		for i = 1, data.symbolCount do
			local pad = UIKit.NewButton({
				Name = "Pad_" .. i,
				Parent = padsHolder,
				Text = tostring(i),
				Size = UDim2.fromScale(0.22, 0.9),
				BackgroundColor3 = PAD_COLORS[((i - 1) % #PAD_COLORS) + 1],
			})
			pads[i] = pad
			pad.Active = false
			pad.MouseButton1Click:Connect(function()
				if not acceptingInput then
					return
				end
				table.insert(playerInput, i)
				flashPad(pad)
				submitIfComplete(#data.sequence)
			end)
		end

		-- Play the demo sequence, then open input.
		task.spawn(function()
			task.wait(0.4)
			for _, symbol in ipairs(data.sequence) do
				local pad = pads[symbol]
				if pad then
					flashPad(pad)
				end
				task.wait(0.55)
			end
			statusLabel.Text = "Giliranmu -- ulangi urutannya"
			acceptingInput = true
			for _, pad in ipairs(pads) do
				pad.Active = true
			end
		end)
	end)

	RemoteRegistry.Get("Puzzle/Result").OnClientEvent:Connect(function(data)
		if data.success then
			feedback.Text = "Benar! Petunjuk baru ditambahkan ke jurnal."
			feedback.TextColor3 = Color3.fromRGB(120, 200, 140)
		else
			feedback.Text = "Urutannya belum tepat. Coba amati lagi lain kali."
			feedback.TextColor3 = UIKit.Palette.FearedRed
		end
		task.delay(1.6, function()
			gui.Enabled = false
		end)
	end)

	RemoteRegistry.Get("Checkpoint/HintUnlocked").OnClientEvent:Connect(function()
		hintBadge.Visible = true
	end)
end

return PuzzleController
