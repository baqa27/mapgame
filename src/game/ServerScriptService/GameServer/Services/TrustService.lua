-- ServerScriptService/GameServer/Services/TrustService.lua
-- Owns internal numeric trust per player. NEVER exposes the raw number to the client --
-- only the bucketed state (trusted/neutral/suspicious/feared), per DESIGN_BRIEF.md.
-- Trust collapsing into "feared" triggers a checkpoint return, implementing
-- game_mechanics.md rule #2 ("kehilangan terlalu banyak kepercayaan warga akan
-- menyebabkan pemain kembali ke checkpoint sebelumnya").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

local TrustService = {}

local trustByPlayer = {}
local stateByPlayer = {}
local Services

local function stateFor(value)
	for _, tier in ipairs(GameConfig.Trust.Thresholds) do
		if value <= tier.max then
			return tier.state
		end
	end
	return GameConfig.Trust.Thresholds[#GameConfig.Trust.Thresholds].state
end

function TrustService.Init(services)
	Services = services
end

function TrustService.InitPlayer(player, initialTrust)
	local value = initialTrust or GameConfig.Trust.Default
	trustByPlayer[player] = value
	stateByPlayer[player] = stateFor(value)
end

function TrustService.RemovePlayer(player)
	trustByPlayer[player] = nil
	stateByPlayer[player] = nil
end

-- Public: bucketed state only. Safe to expose to UI/other Services.
function TrustService.GetState(player)
	return stateByPlayer[player] or stateFor(GameConfig.Trust.Default)
end

-- Internal use only (other Services deciding gameplay outcomes). Never send to client.
function TrustService.GetNumeric(player)
	return trustByPlayer[player] or GameConfig.Trust.Default
end

function TrustService.Adjust(player, delta, difficulty)
	local current = trustByPlayer[player]
	if not current then
		return
	end

	if delta < 0 and difficulty then
		local tier = GameConfig.Difficulty[difficulty]
		if tier then
			delta = delta * tier.TrustPunishmentMultiplier
		end
	end

	local newValue = math.clamp(current + delta, GameConfig.Trust.Min, GameConfig.Trust.Max)
	trustByPlayer[player] = newValue

	if Services and Services.SaveService then
		Services.SaveService.SetTrustReputation(player, newValue)
	end

	local previousState = stateByPlayer[player]
	local newState = stateFor(newValue)
	if newState ~= previousState then
		stateByPlayer[player] = newState
		RemoteRegistry.Get("Trust/StateChanged"):FireClient(player, { state = newState })

		if newState == "feared" and previousState ~= "feared" and Services and Services.CheckpointService then
			Services.CheckpointService.ReturnToLastCheckpoint(player, "trust_collapsed")
		end
	end
end

return TrustService
