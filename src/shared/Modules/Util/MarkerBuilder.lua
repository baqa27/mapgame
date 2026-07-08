-- ReplicatedStorage/Modules/Util/MarkerBuilder.lua
-- Shared helper for spawning glowing world-space interactable markers, used by
-- JimpitanSpawnerService and WorldObjectSpawnerService so every auto-generated
-- interactable looks/feels consistent until final art replaces it.
--
-- Idempotent by design: EnsureMarker never touches a part that already exists under
-- `parent` with that name -- so map authors can permanently hand-replace any
-- auto-generated marker (swap it for real art, move it, whatever) and this will never
-- overwrite their work on a later server start.
--
-- Ground-snapping: WorldData's Y coordinates were written without ever seeing the
-- environment team's actual built geometry, so they're best-effort guesses. To avoid
-- markers floating in mid-air or clipping into floors/walls, every NEWLY created marker
-- (never re-snapped later -- idempotence rule above still applies) raycasts straight
-- down from well above its configured position and, if it hits real world geometry,
-- rests on that surface instead of trusting the raw Y. Pass SnapToGround = false in
-- props to opt a marker out (e.g. something intentionally floating/elevated).

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MarkerBuilder = {}

local bobbingParts = {} -- { { part, baseY, phase } }
local heartbeatConnection

local function ensureHeartbeat()
	if heartbeatConnection then
		return
	end
	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		for _, entry in ipairs(bobbingParts) do
			local part = entry.part
			if part and part.Parent then
				local pos = part.Position
				local bob = math.sin(t * 1.6 + entry.phase) * 0.35
				part.CFrame = CFrame.new(pos.X, entry.baseY + bob, pos.Z) * entry.rotation * CFrame.Angles(0, t * 0.6 + entry.phase, 0)
			end
		end
	end)
end

-- Casts straight down from 150 studs above `position`, excluding `excludeInstance` (the
-- Gameplay folder every auto-spawned marker lives under, so a marker never "snaps" onto
-- a sibling marker instead of real terrain/building geometry). Returns the hit Y, or nil
-- if nothing was hit within range (e.g. position is way outside the built map).
local function raycastGroundY(position, excludeInstance)
	local origin = Vector3.new(position.X, position.Y + 150, position.Z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excludeInstance and { excludeInstance } or {}
	local result = Workspace:Raycast(origin, Vector3.new(0, -400, 0), params)
	if result then
		return result.Position.Y
	end
	return nil
end

-- props: Position (Vector3, required), Shape, Size, Color, Material, LightColor,
-- LightRange, LightBrightness, Icon (emoji/text for a floating BillboardGui), NameLabel
-- (a name plate instead of/alongside Icon), ActionText, ObjectText, HoldDuration,
-- MaxActivationDistance, Attributes (table of attribute name -> value), Bob (default
-- true; set false for flat/ground markers like checkpoints), ExtraRotation (CFrame
-- rotation applied on top of Position, only at creation time), SnapToGround (default
-- true), GroundExclude (Instance to exclude from the raycast; pass the shared Gameplay
-- folder), GroundClearance (studs above the raycast hit to rest the part's center --
-- defaults to half the part's Y size so it sits ON the surface, not embedded in it).
function MarkerBuilder.EnsureMarker(parent, name, props)
	local part = parent:FindFirstChild(name)
	local createdNew = false
	if not part then
		part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.Shape = props.Shape or Enum.PartType.Block
		part.Size = props.Size or Vector3.new(1.4, 1.4, 1.4)
		part.Color = props.Color or Color3.fromRGB(255, 200, 90)
		part.Material = props.Material or Enum.Material.Neon

		local spawnPosition = props.Position
		if props.SnapToGround ~= false then
			local groundY = raycastGroundY(props.Position, props.GroundExclude)
			if groundY then
				local clearance = props.GroundClearance or (part.Size.Y / 2)
				spawnPosition = Vector3.new(props.Position.X, groundY + clearance, props.Position.Z)
			end
		end

		part.CFrame = CFrame.new(spawnPosition) * (props.ExtraRotation or CFrame.new())
		part.Parent = parent
		createdNew = true
	else
		-- Update properties of existing part to match preset
		part.Color = props.Color or part.Color
		part.Material = props.Material or part.Material
	end

	local light = part:FindFirstChildOfClass("PointLight")
	if not light then
		light = Instance.new("PointLight")
		light.Parent = part
	end
	light.Color = props.LightColor or part.Color
	light.Range = props.LightRange or 10
	light.Brightness = props.LightBrightness or 2

	if props.Icon then
		local billboard = part:FindFirstChild("Icon")
		if not billboard then
			billboard = Instance.new("BillboardGui")
			billboard.Name = "Icon"
			billboard.Size = UDim2.fromOffset(40, 40)
			billboard.StudsOffset = Vector3.new(0, 1.8, 0)
			billboard.AlwaysOnTop = true
			-- Icons sit close to other interactables narratively (a clue near its
			-- witness's house, say), so cap render distance shorter than NameLabel's --
			-- otherwise two nearby markers' fixed-pixel billboards visually collide from
			-- any camera distance beyond close-up (this was the overlap seen in-game).
			billboard.MaxDistance = props.IconMaxDistance or 35
			billboard.Parent = part

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Text = props.Icon
			label.TextScaled = true
			label.Parent = billboard
		else
			billboard.MaxDistance = props.IconMaxDistance or 35
			local label = billboard:FindFirstChildOfClass("TextLabel")
			if label then
				label.Text = props.Icon
			end
		end
	end

	if props.NameLabel then
		local nameBoard = part:FindFirstChild("NameLabel")
		if not nameBoard then
			nameBoard = Instance.new("BillboardGui")
			nameBoard.Name = "NameLabel"
			nameBoard.Size = UDim2.fromOffset(160, 40)
			nameBoard.StudsOffset = Vector3.new(0, 3.2, 0)
			nameBoard.AlwaysOnTop = true
			-- Readable from further out than Icon -- a name plate is the more important
			-- signal at range, icons are a close-up detail (see Icon block above).
			nameBoard.MaxDistance = props.NameMaxDistance or 70
			nameBoard.Parent = part

			local frame = Instance.new("Frame")
			frame.BackgroundTransparency = 0.35
			frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
			frame.BorderSizePixel = 0
			frame.Size = UDim2.fromScale(1, 1)
			frame.Parent = nameBoard

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = frame

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.fromRGB(235, 230, 220)
			label.Font = Enum.Font.GothamBold
			label.Size = UDim2.fromScale(1, 1)
			label.Text = props.NameLabel
			label.TextScaled = true
			label.Parent = frame
		else
			nameBoard.MaxDistance = props.NameMaxDistance or 70
			local frame = nameBoard:FindFirstChildOfClass("Frame")
			local label = frame and frame:FindFirstChildOfClass("TextLabel")
			if label then
				label.Text = props.NameLabel
			end
		end
	end

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = props.ActionText or "Interaksi"
		prompt.ObjectText = props.ObjectText or ""
		prompt.HoldDuration = props.HoldDuration or 0.25
		prompt.MaxActivationDistance = props.MaxActivationDistance or 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
	else
		prompt.ActionText = props.ActionText or prompt.ActionText
		prompt.ObjectText = props.ObjectText or prompt.ObjectText
	end

	for attrName, attrValue in pairs(props.Attributes or {}) do
		part:SetAttribute(attrName, attrValue)
	end

	if props.Bob ~= false then
		-- Check if already registered in bobbingParts
		local alreadyRegistered = false
		for _, entry in ipairs(bobbingParts) do
			if entry.part == part then
				alreadyRegistered = true
				break
			end
		end
		if not alreadyRegistered then
			table.insert(bobbingParts, {
				part = part,
				baseY = part.Position.Y,
				phase = math.random() * 6.28,
				rotation = props.ExtraRotation or CFrame.new(),
			})
			ensureHeartbeat()
		end
	end

	return part, createdNew
end

return MarkerBuilder
