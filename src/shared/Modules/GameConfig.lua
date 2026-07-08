-- ReplicatedStorage/Modules/GameConfig.lua
-- Single source of numeric/config truth for the Main Game place.
-- See docs/MAIN_GAME_SYSTEM_RULES.md §5-7 for the design rationale behind these values.

local GameConfig = {}

GameConfig.World = {
	MAP_SIZE = 2048,
	MAP_HALF_SIZE = 1024,
	BASEPLATE_HEIGHT = 16,
}

GameConfig.Queue = {
	PAD_POSITIONS = {
		Easy = Vector3.new(-170, 2, -60),
		Medium = Vector3.new(0, 2, -170),
		Hard = Vector3.new(170, 2, -60),
	}
}

GameConfig.Difficulty = {
	Easy = {
		TrustPunishmentMultiplier = 1,
		ClueAmbiguity = "clear",
		HorrorFrequency = "low",
		CulpritLayers = 1,
		CheckpointDensity = "normal",
		JimpitanQuota = 8,
	},
	Medium = {
		TrustPunishmentMultiplier = 1.5,
		ClueAmbiguity = "semi",
		HorrorFrequency = "medium",
		CulpritLayers = 1, -- branches to human OR pesugihan, not both
		CheckpointDensity = "normal",
		JimpitanQuota = 10,
	},
	Hard = {
		TrustPunishmentMultiplier = 2,
		ClueAmbiguity = "ambiguous",
		HorrorFrequency = "high",
		CulpritLayers = 2, -- must resolve both human AND pesugihan
		CheckpointDensity = "high",
		JimpitanQuota = 12,
	},
}

-- Min/max seconds between HorrorService/EntityAIService events, keyed by HorrorFrequency.
GameConfig.HorrorIntervalSeconds = {
	low = { min = 90, max = 150 },
	medium = { min = 55, max = 100 },
	high = { min = 30, max = 65 },
}

-- Per-level "waktu ronda" countdown, per game_mechanics.md rule #1. Pacing follows
-- GAME_LAVEL.md: Easy is slow/adaptive, Hard is "cepat, intens, dan konstan".
GameConfig.Night = {
	DurationSeconds = {
		Easy = 600,
		Medium = 480,
		Hard = 360,
	},
	BroadcastIntervalSeconds = 5,
}

GameConfig.Trust = {
	Default = 50,
	Min = 0,
	Max = 100,
	-- Bucketed thresholds -> public state. Never expose the raw numeric value to clients.
	Thresholds = {
		{ state = "feared", max = 20 },
		{ state = "suspicious", max = 45 },
		{ state = "neutral", max = 70 },
		{ state = "trusted", max = 100 },
	},
	-- Base deltas; negative deltas are multiplied by Difficulty.TrustPunishmentMultiplier.
	Delta = {
		CorrectClueShared = 4,
		HelpfulChoice = 3,
		WrongAccusationOfNPC = -15,
		FalseAccusationPublic = -10,
		IgnoredWarga = -2,
	},
}

GameConfig.Investigation = {
	MinCluesForAccusation = 3,
	HintUnlockAfterFailures = 3, -- game_mechanics.md rule #9
}

GameConfig.Ending = {
	Easy = "EasySolved",
	MediumHuman = "MediumHuman",
	MediumPesugihan = "MediumPesugihan",
	HardFull = "HardFull",
	HardPartial = "HardPartial",
}

-- TODO(audio): replace with final asset ids once PUBLISHING.md §7 step 4 is done.
-- Wiring is already live (Kentongan on checkpoint save/return + accusation resolve,
-- HorrorWhisper on horror/entity events, ClueFound on new journal entries) -- these
-- start playing automatically the moment real ids are filled in, no code changes needed.
GameConfig.Audio = {
	Kentongan = "rbxassetid://0",
	HorrorWhisper = "rbxassetid://0",
	ClueFound = "rbxassetid://0",
}

GameConfig.SaveService = {
	DataStoreName = "JimpitanMainProfile_v1",
	AutoSaveIntervalSeconds = 120,
}

return GameConfig
