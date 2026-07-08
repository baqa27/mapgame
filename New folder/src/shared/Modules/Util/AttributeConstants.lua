-- ReplicatedStorage/Modules/Util/AttributeConstants.lua
-- Matches the interactable attribute contract in ARCHITECTURE.md and
-- MAIN_GAME_SYSTEM_RULES.md §3. Use these constants instead of raw strings anywhere an
-- attribute name or InteractionType value is read or written.

local AttributeConstants = {}

AttributeConstants.InteractionType = {
	Jimpitan = "jimpitan_can",
	Clue = "clue",
	NPC = "npc",
	Puzzle = "puzzle",
	Checkpoint = "checkpoint",
	AccusationBoard = "accusation_board",
}

AttributeConstants.Attributes = {
	InteractionType = "InteractionType",
	JimpitanId = "JimpitanId",
	ClueId = "ClueId",
	ClueText = "ClueText", -- optional flavor text shown when a clue is picked up
	FalseClue = "FalseClue", -- optional bool, Medium/Hard only
	NPCId = "NPCId",
	PuzzleId = "PuzzleId",
	CheckpointId = "CheckpointId",
	PromptText = "PromptText", -- optional ProximityPrompt.ActionText override
	DifficultyOnly = "DifficultyOnly", -- optional: "Easy" | "Medium" | "Hard"
	RequiresClueId = "RequiresClueId", -- optional: soft-lock until this clue is collected
}

return AttributeConstants
