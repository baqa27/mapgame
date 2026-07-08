-- ReplicatedStorage/Modules/NarrativeData.lua
-- Data-driven narrative content. Client is allowed to require this module directly
-- (it's shared, not server-only) to resolve Ending/Hint display text locally --
-- Services only ever send ids over Remotes, never hardcoded text.
--
-- TODO(narrative): this currently implements ONE full NPC (Pak RT, easy-mode intro
-- branch) as a working example of the Requires/TrustDelta/locked pattern. Extend NPCs /
-- Nodes with the rest of game_naratif.md's Medium/Hard conversations following the same
-- shape -- DialogueService does not need any code changes to support more content.

local GameConfig = require(script.Parent.GameConfig)

local NarrativeData = {}

NarrativeData.NPCs = {
	pak_rt = {
		DisplayName = "Pak RT",
		StartNode = "intro",
		Nodes = {
			intro = {
				Text = "Malam ini kamu mulai ronda. Jangan lupa ambil jimpitan di setiap rumah. "
					.. "Kalau ada kejanggalan, segera lapor.",
				Choices = {
					{ Id = "siap", Text = "Siap, Pak.", Next = "briefing" },
				},
			},
			briefing = {
				Text = "Bagaimana ronda kemarin?",
				Choices = {
					{ Id = "aman", Text = "Aman, Pak.", Next = "continue_night" },
					{
						Id = "report_missing",
						Text = "Pak, uang di pos ronda hilang.",
						Next = "missing_money",
						Requires = { ClueId = "missing_money_clue" },
						-- Honesty about the missing money is rewarded, per
						-- game_mechanics.md's Player Actions table ("Dialogue Choice ...
						-- mempengaruhi tingkat kepercayaan warga"). This is the working
						-- example of the TrustDelta hook -- add it to any other choice
						-- the narrative team wants to move trust.
						TrustDelta = GameConfig.Trust.Delta.HelpfulChoice,
					},
				},
			},
			continue_night = {
				Text = "Bagus. Lanjutkan malam ini.",
				Choices = {},
			},
			missing_money = {
				Text = "Hilang? Coba kamu selidiki dulu sebelum kita simpulkan macam-macam.",
				Choices = {
					{
						Id = "ask_suspect",
						Text = "Pak, menurut Bapak siapa yang mencurigakan?",
						Next = "hint_suspect",
						Requires = { Trust = "neutral" },
					},
				},
			},
			hint_suspect = {
				Text = "Saya tidak mau menuduh sembarangan. Cari bukti dulu, baru bicara ke saya lagi.",
				Choices = {},
			},
		},
	},
}

-- Suspect list shown on the Accusation Board. `eligibleRoles` is what this suspect COULD
-- be cast as if the random case generator picks them -- it is NOT the actual answer.
-- The real per-playthrough solution is decided by CaseGenerationService, not here (see
-- that Service for why: the same static suspect->culprit mapping every game would make
-- every playthrough identical, which the team explicitly did not want).
-- TODO(narrative): replace with the final suspect roster + NPCIds once environment art
-- assigns real names to houses 01-08. Keep at least 2-3 eligible suspects per role so
-- randomization has something to pick from.
NarrativeData.Suspects = {
	{ id = "warga_2", name = "Warga Rumah 02", eligibleRoles = {} }, -- permanent decoy, never guilty
	{ id = "warga_4", name = "Warga Rumah 04", eligibleRoles = { "human" } },
	{ id = "warga_5", name = "Warga Rumah 05", eligibleRoles = { "human" } },
	{ id = "orang_luar", name = "Orang Tak Dikenal", eligibleRoles = { "human" } },
	{ id = "warga_7", name = "Warga Rumah 07 (dekat Sumur)", eligibleRoles = { "pesugihan" } },
	{ id = "warga_8", name = "Warga Rumah 08 (dekat Sumur)", eligibleRoles = { "pesugihan" } },
}

NarrativeData.Endings = {
	EasySolved = {
		Title = "Desa Kembali Aman",
		Text = "Kamu berhasil menemukan pelaku pencurian dari kalangan warga. Pak RT berterima "
			.. "kasih, dan desa kembali tenang -- untuk sementara.",
	},
	MediumHuman = {
		Title = "Pelakunya Orang Luar",
		Text = "Kamu mengungkap bahwa pencurian dilakukan oleh orang luar desa. Warga lega, tapi "
			.. "sebagian bertanya-tanya apakah benar-benar sudah berakhir.",
	},
	MediumPesugihan = {
		Title = "Praktik Pesugihan Terungkap",
		Text = "Kamu menemukan bahwa hilangnya uang berkaitan dengan praktik pesugihan salah satu "
			.. "warga. Desa terguncang oleh kebenaran ini.",
	},
	HardFull = {
		Title = "Kebenaran Penuh",
		Text = "Kamu berhasil mengungkap pencuri manusia sekaligus dalang praktik pesugihan. Semua "
			.. "misteri terpecahkan. Desa Bojongsari benar-benar aman.",
	},
	HardPartial = {
		Title = "Kebenaran yang Belum Utuh",
		Text = "Kamu hanya menemukan satu dari dua pelaku. Sebagian misteri desa Bojongsari masih "
			.. "tersimpan dalam gelap.",
	},
}

NarrativeData.Hints = {
	default = "Coba periksa ulang rumah warga yang belum kamu kunjungi malam ini.",
}

-- Flavor names for EntityAIService sightings, matching the team's accepted narrative
-- revision (see game_naratif.md's "Masukan dari kelompok Desi Fitria" section): mystical
-- entities are "setan gundul" and "methek", not a generic tuyul. Easy mode intentionally
-- has no named entity (light disturbances only, per DESIGN_BRIEF.md's difficulty design).
NarrativeData.EntityNames = {
	Medium = { "setan gundul" },
	Hard = { "setan gundul", "methek" },
}

return NarrativeData
