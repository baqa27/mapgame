-- ServerScriptService/GameServer/Services/SaveService.lua
-- DataStore profile per PUBLISHING.md §6, extended per MAIN_GAME_SYSTEM_RULES.md §6 with
-- ending ids + freeModeUnlocked (read cross-place by the Lobby to gate Free Mode).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)

local SaveService = {}

local store = DataStoreService:GetDataStore(GameConfig.SaveService.DataStoreName)
local profiles = {}

local DEFAULT_PROFILE = {
	checkpoint = "",
	unlockedDifficulty = "Easy",
	endingsSeen = {},
	trustReputation = GameConfig.Trust.Default,
	totalGames = 0,
	freeModeUnlocked = false,
}

local DIFFICULTY_ORDER = { Easy = 1, Medium = 2, Hard = 3 }

local function deepCopy(value)
	if typeof(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end

function SaveService.Init(_services) end

function SaveService.LoadProfile(player)
	local success, data = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		profiles[player] = data
	else
		if not success then
			warn("[SaveService] GetAsync failed for", player.Name, data)
		end
		profiles[player] = deepCopy(DEFAULT_PROFILE)
	end
	profiles[player].totalGames = (profiles[player].totalGames or 0) + 1
end

function SaveService.GetProfile(player)
	return profiles[player]
end

function SaveService.SaveProfile(player)
	local data = profiles[player]
	if not data then
		return
	end
	local success, err = pcall(function()
		store:SetAsync("Player_" .. player.UserId, data)
	end)
	if not success then
		warn("[SaveService] SetAsync failed for", player.Name, err)
	end
end

function SaveService.SetCheckpoint(player, checkpointId)
	local data = profiles[player]
	if data then
		data.checkpoint = checkpointId
	end
end

function SaveService.UnlockDifficulty(player, difficulty)
	local data = profiles[player]
	if not data then
		return
	end
	if (DIFFICULTY_ORDER[difficulty] or 0) > (DIFFICULTY_ORDER[data.unlockedDifficulty] or 0) then
		data.unlockedDifficulty = difficulty
	end
end

function SaveService.RecordEnding(player, endingId)
	local data = profiles[player]
	if not data then
		return
	end
	if not table.find(data.endingsSeen, endingId) then
		table.insert(data.endingsSeen, endingId)
	end
end

function SaveService.SetFreeModeUnlocked(player, value)
	local data = profiles[player]
	if data then
		data.freeModeUnlocked = value
	end
end

function SaveService.SetTrustReputation(player, value)
	local data = profiles[player]
	if data then
		data.trustReputation = value
	end
end

-- Safety net: if Bootstrap's own PlayerRemoving handler doesn't get a chance to run
-- (e.g. server crash/kick edge cases), still attempt one best-effort save.
Players.PlayerRemoving:Connect(function(player)
	task.defer(function()
		if profiles[player] then
			SaveService.SaveProfile(player)
		end
	end)
end)

return SaveService
