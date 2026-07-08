-- StarterPlayerScripts/GameClient/Bootstrap.client.lua
-- Entry point for the Main Game client. Waits for Remotes to exist, then starts every
-- Controller. Add new Controllers here as they're built (MAIN_GAME_SYSTEM_RULES.md §10).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Modules")
ReplicatedStorage:WaitForChild("Remotes")

local Controllers = script.Parent.Controllers

require(Controllers.HUDController).Start()
require(Controllers.JournalController).Start()
require(Controllers.DialogueController).Start()
require(Controllers.PuzzleController).Start()
require(Controllers.HorrorController).Start()
require(Controllers.CheckpointController).Start()
require(Controllers.AccusationController).Start()
require(Controllers.EndingController).Start()

print("[GameClient] Bootstrap complete.")
