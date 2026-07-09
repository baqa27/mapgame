--!strict
-- Server-side lighting flicker effect for candles, torches, and lanterns.
-- Parts with attribute `CanFlicker = true` will have their PointLight flickered
-- based on difficulty's horror intensity.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules:WaitForChild("GameConfig"))

local AudioLightingService = {}
AudioLightingService.__index = AudioLightingService

function AudioLightingService.Init(_services)
	-- This service uses a different pattern (OOP), kept for backward compat.
	-- Called from Bootstrap Init order but does nothing until :Start() is called.
end

function AudioLightingService.new()
	return setmetatable({
		_running = false,
	}, AudioLightingService)
end

function AudioLightingService:Start(difficulty: string)
	if self._running then
		return
	end
	self._running = true

	local difficultyConfig = GameConfig.GetDifficultyConfig and GameConfig.GetDifficultyConfig(difficulty)
		or GameConfig.Difficulty[difficulty]
	local horrorIntensity = (difficultyConfig and difficultyConfig.horrorIntensity) or 0.5

	Lighting.FogEnd = math.max(70, Lighting.FogEnd - horrorIntensity * 20)

	task.spawn(function()
		while self._running do
			for _, instance in ipairs(Workspace:GetDescendants()) do
				if instance:IsA("PointLight") and instance.Parent and instance.Parent:GetAttribute("CanFlicker") then
					local base = 0.8 + math.random() * 0.8
					instance.Brightness = base
					if math.random() < 0.12 + horrorIntensity * 0.08 then
						instance.Brightness = 0.05
						task.wait(0.08)
						instance.Brightness = base
					end
				end
			end
			task.wait(1.5)
		end
	end)
end

function AudioLightingService:Stop()
	self._running = false
end

return AudioLightingService
