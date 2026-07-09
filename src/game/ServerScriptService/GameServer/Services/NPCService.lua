--!strict
-- Subtle idle animation for NPC standee parts in Workspace.Map.Gameplay.NPCs.
-- Randomly nudges each NPC model's yaw slightly every few seconds to give
-- a sense of presence without full character rigs.

local Workspace = game:GetService("Workspace")

local NPCService = {}
NPCService.__index = NPCService

function NPCService.Init(_services)
	-- OOP pattern: Init does nothing. Start() is called per-session if needed.
end

function NPCService.new()
	return setmetatable({
		_running = false,
	}, NPCService)
end

function NPCService:Start()
	if self._running then
		return
	end
	self._running = true

	task.spawn(function()
		while self._running do
			local mapsFolder = Workspace:FindFirstChild("Maps")
			local map = mapsFolder and (mapsFolder:FindFirstChild("MainGameMap") or mapsFolder:FindFirstChild("LobbyMap"))
				or Workspace:FindFirstChild("Map")
			local gameplay = map and map:FindFirstChild("Gameplay")
			local npcs = gameplay and gameplay:FindFirstChild("NPCs")
			if npcs then
				for _, model in ipairs(npcs:GetChildren()) do
					if model:IsA("Model") and model.PrimaryPart then
						local yaw = math.rad(math.random(-8, 8))
						model:PivotTo(model.PrimaryPart.CFrame * CFrame.Angles(0, yaw, 0))
					end
				end
			end
			task.wait(6)
		end
	end)
end

function NPCService:Stop()
	self._running = false
end

return NPCService
