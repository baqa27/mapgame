-- ReplicatedStorage/Modules/NarrativeData.lua
-- Endings, hints, and entity flavor names -- the parts of the narrative that aren't
-- per-NPC dialogue trees or per-suspect/clue investigation content.
--
-- NOTE: NPC dialogue trees now live in Data/DialogueData.lua and suspect/clue/puzzle
-- content lives in Data/InvestigationData.lua (both far more complete than this file's
-- old placeholder NPCs/Suspects tables, which have been removed -- don't recreate them
-- here, extend the Data/ files instead).
--
-- Client is allowed to require this module directly (it's shared, not server-only) to
-- resolve Ending/Hint display text locally -- Services only ever send ids over Remotes,
-- never hardcoded text.

local NarrativeData = {}

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
