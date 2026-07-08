-- StarterPlayerScripts/GameClient/Controllers/HorrorController.lua
-- Purely cosmetic reaction to Horror/Event and Entity/Sighted. Never sets Modal = true
-- and never intercepts clicks/ProximityPrompts (ROBLOX_UI_SKILL.md §2). Entity sightings
-- optionally carry a flavor name (setan gundul / methek) from NarrativeData.EntityNames.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)
local UIKit = require(script.Parent.Parent.UI.UIKit)

local HorrorController = {}
local player = Players.LocalPlayer

local WHISPER_LINES = {
	"...ada yang mengawasi...",
	"...jangan percaya semua yang kau lihat...",
	"...belum selesai...",
}

function HorrorController.Start()
	local gui = UIKit.NewScreenGui("HorrorGui")
	gui.DisplayOrder = 100
	gui.Parent = player:WaitForChild("PlayerGui")

	local vignette = Instance.new("Frame")
	vignette.Name = "Root"
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.new(0, 0, 0)
	vignette.BackgroundTransparency = 1
	vignette.BorderSizePixel = 0
	vignette.Active = false -- never intercepts input
	vignette.Parent = gui

	local subtitle = UIKit.NewLabel({
		Name = "Subtitle",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.85),
		Size = UDim2.fromScale(0.5, 0.06),
		Font = UIKit.Font.Narrative,
		TextColor3 = UIKit.Palette.TextMuted,
	})
	subtitle.Text = ""

	local function playVignettePulse()
		local tweenIn = TweenService:Create(
			vignette,
			TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0.75 }
		)
		tweenIn:Play()
		tweenIn.Completed:Connect(function()
			TweenService:Create(
				vignette,
				TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1 }
			):Play()
		end)
	end

	local function showWhisper(line)
		subtitle.Text = line
		TweenService:Create(subtitle, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
		task.delay(3, function()
			TweenService:Create(subtitle, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
		end)
	end

	RemoteRegistry.Get("Horror/Event").OnClientEvent:Connect(function(data)
		if data.eventType == "whisper" then
			showWhisper(WHISPER_LINES[math.random(1, #WHISPER_LINES)])
			UIKit.PlaySound(GameConfig.Audio.HorrorWhisper, 0.4)
		else
			playVignettePulse()
		end
	end)

	RemoteRegistry.Get("Entity/Sighted").OnClientEvent:Connect(function(data)
		playVignettePulse()
		UIKit.PlaySound(GameConfig.Audio.HorrorWhisper, 0.4)
		if data.entityHint then
			showWhisper(string.format("...%s bergerak di kegelapan...", data.entityHint))
		else
			showWhisper("...sesuatu bergerak di kegelapan...")
		end
	end)
end

return HorrorController
