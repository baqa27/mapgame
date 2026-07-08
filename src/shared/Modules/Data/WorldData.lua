--!strict

local GameConfig = require(script.Parent.Parent.GameConfig)

local WorldData = {}

WorldData.Map = {
	size = GameConfig.World.MAP_SIZE,
	halfSize = GameConfig.World.MAP_HALF_SIZE,
	baseplateHeight = GameConfig.World.BASEPLATE_HEIGHT,
}

WorldData.Lobby = {
	MapName = "Night Ronda Lobby - Bojongsari",
	Spawn = Vector3.new(0, 4, 910),
	QueuePads = {
		Easy = {
			position = GameConfig.Queue.PAD_POSITIONS.Easy,
			color = Color3.fromRGB(74, 180, 117),
			label = "EASY QUEUE / MODAL EASY",
			description = "Clue jelas, konflik sosial, horror ringan.",
			doorPosition = Vector3.new(-860, 10, -300),
		},
		Medium = {
			position = GameConfig.Queue.PAD_POSITIONS.Medium,
			color = Color3.fromRGB(219, 166, 69),
			label = "MEDIUM QUEUE / MODAL MEDIUM",
			description = "Clue ambigu, false clue, jalur manusia atau pesugihan.",
			doorPosition = Vector3.new(0, 10, -860),
		},
		Hard = {
			position = GameConfig.Queue.PAD_POSITIONS.Hard,
			color = Color3.fromRGB(184, 57, 72),
			label = "HARD QUEUE / MODAL HARD",
			description = "Multi-layer mystery, entity aktif, trust sangat sensitif.",
			doorPosition = Vector3.new(860, 10, -300),
		},
	},
	BuilderMarkers = {
		{ id = "baseplate", label = "BASEPLATE 2048x2048x16 STUD / DARK GREY GRID", position = Vector3.new(0, 0.2, 0), size = Vector3.new(2048, 0.2, 2048), color = Color3.fromRGB(58, 67, 72) },
		{ id = "spawn", label = "SPAWN LOCATION / SAFE ZONE", position = Vector3.new(0, 0.45, 910), size = Vector3.new(180, 0.25, 120), color = Color3.fromRGB(70, 112, 126) },
		{ id = "safe_hangout", label = "AREA SAFE ZONE & HANG-OUT / RENTAN JIMPITAN", position = Vector3.new(0, 0.45, 210), size = Vector3.new(760, 0.25, 520), color = Color3.fromRGB(92, 78, 52) },
		{ id = "mode_board", label = "PILIHAN MODE KE DESA BOJONGSARI / NIGHT RONDA", position = Vector3.new(0, 0.5, -360), size = Vector3.new(680, 0.25, 210), color = Color3.fromRGB(55, 63, 66) },
		{ id = "easy_match", label = "KOTAK MATCH EASY / SLOT P1-P4 / SESSION A-B", position = Vector3.new(-760, 0.55, -80), size = Vector3.new(290, 0.25, 180), color = Color3.fromRGB(44, 78, 58) },
		{ id = "hard_match", label = "KOTAK MATCH HARD / SLOT P1-P4 / SESSION A-B", position = Vector3.new(760, 0.55, -80), size = Vector3.new(290, 0.25, 180), color = Color3.fromRGB(83, 45, 49) },
		{ id = "shop", label = "SHOP PERLENGKAPAN RONDA / SENTER, KENTONGAN, ITEMS", position = Vector3.new(-610, 0.55, 270), size = Vector3.new(300, 0.25, 220), color = Color3.fromRGB(88, 66, 44) },
		{ id = "leaderboard", label = "LEADERBOARD DONASI JIMPITAN", position = Vector3.new(620, 0.55, 270), size = Vector3.new(280, 0.25, 210), color = Color3.fromRGB(50, 67, 62) },
		{ id = "banyan", label = "BANYAN TREE / LANDMARK LOBBY", position = Vector3.new(-560, 0.55, -520), size = Vector3.new(260, 0.25, 220), color = Color3.fromRGB(38, 76, 52) },
		{ id = "bamboo_zone", label = "ZONA BAMBU DEKORATIF", position = Vector3.new(620, 0.55, -620), size = Vector3.new(350, 0.25, 300), color = Color3.fromRGB(38, 78, 48) },
		{ id = "forest_boundary", label = "HUTAN DESA / SAFE BOUNDARY", position = Vector3.new(0, 0.55, 0), size = Vector3.new(1980, 0.25, 1980), color = Color3.fromRGB(31, 58, 43), outlineOnly = true },
	},
	Structures = {
		{ id = "pos_lobby", label = "POS RONDA LOBBY / PUSAT INFO", position = Vector3.new(0, 8, 210), size = Vector3.new(260, 16, 150), color = Color3.fromRGB(80, 56, 37), material = Enum.Material.WoodPlanks },
		{ id = "notice_board", label = "PAPAN PENGUMUMAN & MISI RONDA ARC 1-2", position = Vector3.new(0, 26, 10), size = Vector3.new(360, 70, 8), color = Color3.fromRGB(38, 32, 28), material = Enum.Material.Wood },
		{ id = "shop_hut", label = "BLOCKOUT SHOP / GANTI DENGAN MODEL FINAL", position = Vector3.new(-610, 8, 270), size = Vector3.new(180, 16, 130), color = Color3.fromRGB(73, 52, 36), material = Enum.Material.WoodPlanks },
		{ id = "leaderboard_board", label = "PAPAN LEADERBOARD DONASI", position = Vector3.new(620, 24, 270), size = Vector3.new(170, 82, 8), color = Color3.fromRGB(32, 39, 39), material = Enum.Material.SmoothPlastic },
	},
}

WorldData.Village = {
	MapName = "Night Ronda Bojongsari",
	Spawn = Vector3.new(-51, 13, -600),
	MainGate = Vector3.new(0, 0, 820),
	Checkpoints = {
		intro_complete = Vector3.new(-51, 13, -638),
		jimpitan_collected = Vector3.new(-51, 13, -638),
		first_clue_found = Vector3.new(-757, 30, -226),
		key_clue_found = Vector3.new(554, 34, -233),
		suspect_identified = Vector3.new(669, 15, 573),
		pre_climax = Vector3.new(-51, 13, -638),
		ending_choice = Vector3.new(-31, 13, -638),
	},
	Houses = {
		{ id = "house_01_bu_siti", owner = "bu_siti", label = "RUMAH WARGA 01 / BU SITI / KORBAN", position = Vector3.new(-757, 30, -226), rotation = 18 },
		{ id = "house_02_mas_agus", owner = "mas_agus", label = "RUMAH WARGA 02 / MAS AGUS / FALSE SUSPECT", position = Vector3.new(-614, 25, -421), rotation = 35 },
		{ id = "house_03_warga", owner = "none", label = "RUMAH WARGA 03 / JIMPITAN ROUTE", position = Vector3.new(-78, 28, -534), rotation = 8 },
		{ id = "house_04_bu_ani", owner = "bu_ani", label = "RUMAH WARGA 04 / BU ANI / SAKSI GOSIP", position = Vector3.new(158, 38, -2), rotation = -8 },
		{ id = "house_05_pak_joko", owner = "pak_joko", label = "RUMAH WARGA 05 / PAK JOKO / SUSPECT", position = Vector3.new(554, 34, -233), rotation = -30 },
		{ id = "house_06_warga", owner = "none", label = "RUMAH WARGA 06 / ROUTE TIMUR", position = Vector3.new(669, 15, 188), rotation = -82 },
		{ id = "house_07_mbah_darmo", owner = "mbah_darmo", label = "RUMAH WARGA 07 / MBAH DARMO / SAKSI MISTIS", position = Vector3.new(669, 15, 573), rotation = -138 },
		{ id = "house_08_pak_rt", owner = "pak_rt", label = "RUMAH PAK RT / MENTOR & REPORTING", position = Vector3.new(-533, 29, 585), rotation = 145 },
	},
	NPCs = {
		{ id = "pak_rt", label = "NPC PAK RT / BRIEFING", position = Vector3.new(-510, 29, 585) },
		{ id = "bu_siti", label = "NPC BU SITI / KORBAN", position = Vector3.new(-740, 30, -210) },
		{ id = "mas_agus", label = "NPC MAS AGUS / FALSE SUSPECT", position = Vector3.new(-600, 25, -410) },
		{ id = "pak_joko", label = "NPC PAK JOKO / SUSPECT UTAMA", position = Vector3.new(540, 34, -220) },
		{ id = "bu_ani", label = "NPC BU ANI / SAKSI GOSIP", position = Vector3.new(170, 38, -10) },
		{ id = "mbah_darmo", label = "NPC MBAH DARMO / OCCULT WITNESS", position = Vector3.new(650, 15, 560) },
	},
	Areas = {
		pos_ronda = Vector3.new(-51, 13, -638),
		central_forest = Vector3.new(0, 0, -40),
		sumur = Vector3.new(0, 27, 435),
		ritual = Vector3.new(40, 0, -60),
		loop_road = Vector3.new(0, 0, -35),
		bamboo = Vector3.new(690, 0, -720),
		rumah_kosong = Vector3.new(669, 15, 188),
		banyan = Vector3.new(570, 15, 720),
		main_gate = Vector3.new(0, 0, 820),
		forest_boundary = Vector3.new(0, 0, 0),
	},
	BuilderMarkers = {
		{ id = "baseplate", label = "BASEPLATE 2048x2048x16 STUD / NIGHT GRASS GRID", position = Vector3.new(0, 0.2, 0), size = Vector3.new(2048, 0.2, 2048), color = Color3.fromRGB(45, 58, 48) },
		{ id = "main_gate", label = "GERBANG MASUK DESA / MAIN GATES", position = Vector3.new(0, 0.55, 820), size = Vector3.new(230, 0.25, 140), color = Color3.fromRGB(92, 80, 54) },
		{ id = "pos_ronda", label = "POS RONDA & CHECKPOINT / ARC 1", position = Vector3.new(-51, 13, -638), size = Vector3.new(270, 0.25, 170), color = Color3.fromRGB(101, 73, 45) },
		{ id = "rumah_pak_rt", label = "RUMAH PAK RT / MENTOR REPORTING", position = Vector3.new(-533, 29, 585), size = Vector3.new(220, 0.25, 170), color = Color3.fromRGB(80, 61, 43) },
		{ id = "jalan_lingkar", label = "JALAN LINGKAR DESA / RUTE PATROLI", position = Vector3.new(0, 0.55, -35), size = Vector3.new(1420, 0.25, 1420), color = Color3.fromRGB(90, 72, 50), outlineOnly = true },
		{ id = "hutan_tengah", label = "HUTAN TENGAH / CENTRAL FOREST", position = Vector3.new(0, 0.55, -40), size = Vector3.new(780, 0.25, 760), color = Color3.fromRGB(28, 70, 45) },
		{ id = "sumur", label = "SUMUR / RITUAL PESUGIHAN & FALSE CLUE LOC", position = Vector3.new(0, 27, 435), size = Vector3.new(120, 0.25, 120), color = Color3.fromRGB(51, 54, 54) },
		{ id = "bamboo_grove", label = "ZONA BAMBU / BAMBOO GROVE", position = Vector3.new(690, 0.55, -720), size = Vector3.new(360, 0.25, 270), color = Color3.fromRGB(37, 82, 48) },
		{ id = "rumah_kosong", label = "RUMAH KOSONG / LOKASI MISTERI / FALSE CLUE LOC", position = Vector3.new(669, 15, 188), size = Vector3.new(230, 0.25, 170), color = Color3.fromRGB(58, 58, 52) },
		{ id = "banyan_tree", label = "POHON BERINGIN BESAR / BANYAN TREE", position = Vector3.new(570, 15, 720), size = Vector3.new(230, 0.25, 200), color = Color3.fromRGB(32, 75, 49) },
		{ id = "hutan_batas", label = "HUTAN DESA / MAP BOUNDARY", position = Vector3.new(0, 0.55, 0), size = Vector3.new(1980, 0.25, 1980), color = Color3.fromRGB(31, 63, 45), outlineOnly = true },
	},
	Clues = {
		{ id = "empty_can_siti", position = Vector3.new(-770, 30, -230) },
		{ id = "ledger_erased", position = Vector3.new(-60, 13, -630) },
		{ id = "muddy_sandals", position = Vector3.new(570, 34, -240) },
		{ id = "false_shadow_agus", position = Vector3.new(-630, 25, -430) },
		{ id = "coin_circle", position = Vector3.new(680, 15, 170) },
		{ id = "wet_footprints", position = Vector3.new(180, 38, 10) },
		{ id = "debt_note", position = Vector3.new(580, 34, -220) },
		{ id = "ritual_receipt", position = Vector3.new(20, 27, 410) },
		{ id = "contradicting_alibi", position = Vector3.new(140, 38, -20) },
		{ id = "ritual_token", position = Vector3.new(650, 15, 590) },
	},
	Puzzles = {
		{ id = "kentongan_pattern", position = Vector3.new(-45, 13, -630) },
		{ id = "window_shadow", position = Vector3.new(-610, 25, -415) },
		{ id = "ritual_symbols", position = Vector3.new(0, 27, 435) },
	},
}

return WorldData
