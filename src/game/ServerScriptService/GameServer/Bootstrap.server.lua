-- ServerScriptService/GameServer/Bootstrap.server.lua
-- Entry point for the Main Game place. Creates Remotes, wires every Service through a
-- shared registry table (avoids require() cycles between Services), then handles
-- per-player init/teardown. Follow MAIN_GAME_SYSTEM_RULES.md §10 for how to extend this.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteRegistry = require(Modules.Net.RemoteRegistry)

RemoteRegistry.Init()

local ServiceScripts = script.Parent.Services

local SaveService = require(ServiceScripts.SaveService)
local TrustService = require(ServiceScripts.TrustService)
local ObjectiveService = require(ServiceScripts.ObjectiveService)
local InvestigationService = require(ServiceScripts.InvestigationService)
local DialogueService = require(ServiceScripts.DialogueService)
local PuzzleService = require(ServiceScripts.PuzzleService)
local HorrorService = require(ServiceScripts.HorrorService)
local EntityAIService = require(ServiceScripts.EntityAIService)
local CheckpointService = require(ServiceScripts.CheckpointService)
local CaseGenerationService = require(ServiceScripts.CaseGenerationService)
local AccusationService = require(ServiceScripts.AccusationService)
local NightTimerService = require(ServiceScripts.NightTimerService)
local JimpitanSpawnerService = require(ServiceScripts.JimpitanSpawnerService)
local WorldObjectSpawnerService = require(ServiceScripts.WorldObjectSpawnerService)
local InteractionService = require(ServiceScripts.InteractionService)
local AudioLightingService = require(ServiceScripts.AudioLightingService)
local NPCService = require(ServiceScripts.NPCService)

-- Shared registry passed into every Service.Init() so Services can call each other
-- (e.g. PuzzleService -> InvestigationService) without requiring each other directly.
local ServiceRegistry = {
	SaveService = SaveService,
	TrustService = TrustService,
	ObjectiveService = ObjectiveService,
	InvestigationService = InvestigationService,
	DialogueService = DialogueService,
	PuzzleService = PuzzleService,
	HorrorService = HorrorService,
	EntityAIService = EntityAIService,
	CheckpointService = CheckpointService,
	CaseGenerationService = CaseGenerationService,
	AccusationService = AccusationService,
	NightTimerService = NightTimerService,
	JimpitanSpawnerService = JimpitanSpawnerService,
	WorldObjectSpawnerService = WorldObjectSpawnerService,
	InteractionService = InteractionService,
	AudioLightingService = AudioLightingService,
	NPCService = NPCService,
}

local INIT_ORDER = {
	"SaveService",
	"TrustService",
	"ObjectiveService",
	"InvestigationService",
	"DialogueService",
	"PuzzleService",
	"HorrorService",
	"EntityAIService",
	"CheckpointService",
	"CaseGenerationService",
	"AccusationService",
	"NightTimerService",
	"JimpitanSpawnerService",    -- spawns world content
	"WorldObjectSpawnerService", -- spawns world content
	"InteractionService",        -- last: wires ProximityPrompts to every Service above
	"AudioLightingService",      -- cosmetic: torch/lantern flicker
	"NPCService",                -- cosmetic: NPC idle sway
}

for _, name in ipairs(INIT_ORDER) do
	ServiceRegistry[name].Init(ServiceRegistry)
end

local function resolveDifficulty(player)
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData
	if teleportData and teleportData.difficulty then
		return teleportData.difficulty
	end
	return "Easy" -- Studio / no-teleport-data fallback
end

local function onPlayerAdded(player)
	local difficulty = resolveDifficulty(player)
	player:SetAttribute("Difficulty", difficulty)

	SaveService.LoadProfile(player)
	local profile = SaveService.GetProfile(player)

	TrustService.InitPlayer(player, profile and profile.trustReputation)
	ObjectiveService.InitPlayer(player, difficulty)
	InvestigationService.InitPlayer(player)
	CheckpointService.InitPlayer(player, difficulty)
	CaseGenerationService.GenerateCase(player, difficulty)
	AccusationService.InitPlayer(player, difficulty)
	HorrorService.InitPlayer(player)
	EntityAIService.InitPlayer(player)
	NightTimerService.InitPlayer(player, difficulty)

	-- Start cosmetic services per-session
	-- AudioLightingService and NPCService use OOP pattern: .new():Start()
	-- They are global (not per-player), so only start once on first player join.
	-- Subsequent joins skip because _running guard in :Start() prevents double-start.
	local audioInstance = AudioLightingService.new()
	audioInstance:Start(difficulty)

	local npcInstance = NPCService.new()
	npcInstance:Start()

	-- World content spawns asynchronously (waits for Workspace.Map); give it a moment
	-- before snapshotting, otherwise a player who joins instantly could get an empty list.
	task.defer(function()
		JimpitanSpawnerService.SendSnapshot(player)
	end)
end

local function onPlayerRemoving(player)
	SaveService.SaveProfile(player)
	TrustService.RemovePlayer(player)
	ObjectiveService.RemovePlayer(player)
	InvestigationService.RemovePlayer(player)
	CheckpointService.RemovePlayer(player)
	CaseGenerationService.RemovePlayer(player)
	AccusationService.RemovePlayer(player)
	HorrorService.RemovePlayer(player)
	EntityAIService.RemovePlayer(player)
	NightTimerService.RemovePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print("[GameServer] Bootstrap complete.")
