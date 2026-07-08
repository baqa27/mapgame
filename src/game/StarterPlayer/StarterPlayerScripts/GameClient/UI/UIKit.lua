-- StarterPlayerScripts/GameClient/UI/UIKit.lua
-- Shared instance-builder + style helpers, implementing ROBLOX_UI_SKILL.md §1-4.
-- Every Controller should build its ScreenGui through these helpers rather than
-- hand-rolling Instance.new calls, so palette/typography/motion stay consistent.

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local UIKit = {}

-- §3 Visual style guide -------------------------------------------------------------
UIKit.Palette = {
	LanternOrange = Color3.fromRGB(232, 168, 85),
	MoonlightBlue = Color3.fromRGB(28, 34, 46),
	PanelBlue = Color3.fromRGB(20, 24, 33),
	FearedRed = Color3.fromRGB(150, 40, 40),
	TextLight = Color3.fromRGB(235, 230, 220),
	TextMuted = Color3.fromRGB(160, 160, 165),
}

-- TODO(art): swap Narrative for a licensed rustic/hand-written font asset once one is
-- picked; Enum.Font.Cartoon is a placeholder that is at least NOT a generic UI sans.
UIKit.Font = {
	Narrative = Enum.Font.Cartoon,
	Body = Enum.Font.Gotham,
	Heading = Enum.Font.GothamBold,
}

function UIKit.NewScreenGui(name)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.Enabled = true
	return gui
end

function UIKit.NewFrame(props)
	local frame = Instance.new("Frame")
	frame.Name = props.Name or "Frame"
	frame.BackgroundColor3 = props.BackgroundColor3 or UIKit.Palette.PanelBlue
	frame.BackgroundTransparency = props.BackgroundTransparency or 0.15
	frame.BorderSizePixel = 0
	frame.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	frame.Position = props.Position or UDim2.fromScale(0, 0)
	frame.Size = props.Size or UDim2.fromScale(0.2, 0.1)
	frame.Visible = props.Visible ~= false
	frame.Parent = props.Parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = props.CornerRadius or UDim.new(0, 8)
	corner.Parent = frame

	return frame
end

function UIKit.NewLabel(props)
	local label = Instance.new("TextLabel")
	label.Name = props.Name or "Label"
	label.BackgroundTransparency = 1
	label.Font = props.Font or UIKit.Font.Body
	label.TextColor3 = props.TextColor3 or UIKit.Palette.TextLight
	label.TextScaled = true
	label.TextWrapped = props.TextWrapped or false
	label.Text = props.Text or ""
	label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
	label.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	label.Position = props.Position or UDim2.fromScale(0, 0)
	label.Size = props.Size or UDim2.fromScale(1, 1)
	label.Visible = props.Visible ~= false
	label.Parent = props.Parent

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = props.MaxTextSize or 24
	constraint.MinTextSize = props.MinTextSize or 10
	constraint.Parent = label

	return label
end

function UIKit.NewButton(props)
	local button = Instance.new("TextButton")
	button.Name = props.Name or "Button"
	button.BackgroundColor3 = props.BackgroundColor3 or UIKit.Palette.PanelBlue
	button.AutoButtonColor = true
	button.BorderSizePixel = 0
	button.Font = props.Font or UIKit.Font.Body
	button.TextColor3 = props.TextColor3 or UIKit.Palette.TextLight
	button.TextScaled = true
	button.Text = props.Text or ""
	button.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	button.Position = props.Position or UDim2.fromScale(0, 0)
	button.Size = props.Size or UDim2.fromScale(1, 0.2)
	button.Parent = props.Parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = 22
	constraint.MinTextSize = 10
	constraint.Parent = button

	return button
end

-- §4 Motion & feedback ----------------------------------------------------------------
-- Standard show/hide tween: Quad/Out, 0.2-0.35s, per ROBLOX_UI_SKILL.md.

function UIKit.FadeIn(guiObject, targetTransparency, duration)
	guiObject.Visible = true
	local tween = TweenService:Create(
		guiObject,
		TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = targetTransparency or 0.15 }
	)
	tween:Play()
	return tween
end

function UIKit.FadeOutAndHide(guiObject, duration)
	local tween = TweenService:Create(
		guiObject,
		TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		guiObject.Visible = false
	end)
	return tween
end

-- Kentongan / whisper / clue-found sound cues -----------------------------------------
-- No-ops on the rbxassetid://0 placeholders in GameConfig.Audio, so every Controller
-- can call this unconditionally -- it starts working the instant real asset ids land.
function UIKit.PlaySound(soundId, volume)
	if not soundId or soundId == "rbxassetid://0" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.6
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

return UIKit
