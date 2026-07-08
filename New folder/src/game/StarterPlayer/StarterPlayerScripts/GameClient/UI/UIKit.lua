-- StarterPlayerScripts/GameClient/UI/UIKit.lua
-- Shared instance-builder + style helpers, implementing ROBLOX_UI_SKILL.md §1-4.
-- Every Controller builds its ScreenGui through these helpers rather than hand-rolling
-- Instance.new calls, so palette/typography/motion/borders stay consistent everywhere --
-- improving NewFrame/NewButton here improves every screen in the game at once.

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local UIKit = {}

-- §3 Visual style guide -------------------------------------------------------------
UIKit.Palette = {
	LanternOrange = Color3.fromRGB(232, 168, 85),
	MoonlightBlue = Color3.fromRGB(28, 34, 46),
	PanelBlue = Color3.fromRGB(20, 24, 33),
	PanelBlueLight = Color3.fromRGB(32, 38, 50),
	FearedRed = Color3.fromRGB(150, 40, 40),
	TextLight = Color3.fromRGB(235, 230, 220),
	TextMuted = Color3.fromRGB(160, 160, 165),
	BorderGold = Color3.fromRGB(140, 110, 60),
}

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

-- Adds a subtle border + soft top-to-bottom gradient to any GuiObject -- this is what
-- turns a flat rectangle into something that reads as a "panel" instead of a placeholder.
function UIKit.ApplyPanelChrome(guiObject, options)
	options = options or {}

	local stroke = Instance.new("UIStroke")
	stroke.Color = options.StrokeColor or UIKit.Palette.BorderGold
	stroke.Thickness = options.StrokeThickness or 1
	stroke.Transparency = options.StrokeTransparency or 0.35
	stroke.Parent = guiObject

	if options.Gradient ~= false then
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180)),
		})
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.85),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Rotation = 90
		gradient.Parent = guiObject
	end

	return stroke
end

function UIKit.NewFrame(props)
	local frame = Instance.new("Frame")
	frame.Name = props.Name or "Frame"
	frame.BackgroundColor3 = props.BackgroundColor3 or UIKit.Palette.PanelBlue
	frame.BackgroundTransparency = props.BackgroundTransparency or 0.1
	frame.BorderSizePixel = 0
	frame.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	frame.Position = props.Position or UDim2.fromScale(0, 0)
	frame.Size = props.Size or UDim2.fromScale(0.2, 0.1)
	frame.Visible = props.Visible ~= false
	frame.ClipsDescendants = props.ClipsDescendants or false
	frame.Parent = props.Parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = props.CornerRadius or UDim.new(0, 10)
	corner.Parent = frame

	if props.Chrome ~= false then
		UIKit.ApplyPanelChrome(frame, props.ChromeOptions)
	end

	return frame
end

-- A perfectly circular panel (minimap frame, round icon badges, etc).
function UIKit.NewCircle(props)
	props = props or {}
	props.CornerRadius = UDim.new(1, 0)
	return UIKit.NewFrame(props)
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
	label.Rotation = props.Rotation or 0
	label.ZIndex = props.ZIndex or 1
	label.Parent = props.Parent

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = props.MaxTextSize or 24
	constraint.MinTextSize = props.MinTextSize or 10
	constraint.Parent = label

	if props.Shadow then
		label.TextStrokeTransparency = 0.6
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
	end

	return label
end

function UIKit.NewButton(props)
	local button = Instance.new("TextButton")
	button.Name = props.Name or "Button"
	button.BackgroundColor3 = props.BackgroundColor3 or UIKit.Palette.PanelBlueLight
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

	if props.Chrome ~= false then
		UIKit.ApplyPanelChrome(button, { Gradient = false, StrokeTransparency = 0.5 })
	end

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = 22
	constraint.MinTextSize = 10
	constraint.Parent = button

	return button
end

-- §4 Motion & feedback ----------------------------------------------------------------
function UIKit.FadeIn(guiObject, targetTransparency, duration)
	guiObject.Visible = true
	local tween = TweenService:Create(
		guiObject,
		TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = targetTransparency or 0.1 }
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
