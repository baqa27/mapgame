--!strict

local InvestigationData = {}

InvestigationData.Suspects = {
	mas_agus = {
		displayName = "Mas Agus",
		profile = "Mudah dituduh karena baru pulang dari kota, tetapi banyak bukti hanya prasangka.",
		isHumanCulprit = false,
		isPesugihanActor = false,
	},
	pak_joko = {
		displayName = "Pak Joko",
		profile = "Pedagang kecil yang hutangnya menumpuk dan sering terlihat gelisah.",
		isHumanCulprit = true,
		isPesugihanActor = true,
	},
	mbah_darmo = {
		displayName = "Mbah Darmo",
		profile = "Saksi yang memahami tanda ritual. Terlihat menakutkan, tetapi bukan pelaku.",
		isHumanCulprit = false,
		isPesugihanActor = false,
	},
	bu_ani = {
		displayName = "Bu Ani",
		profile = "Penyebar gosip yang kadang menyamarkan fakta penting.",
		isHumanCulprit = false,
		isPesugihanActor = false,
	},
}

InvestigationData.Clues = {
	empty_can_siti = {
		displayName = "Tabung Bu Siti Kosong",
		location = "Rumah Bu Siti",
		description = "Tabung jimpitan kosong, tetapi ada bekas koin di dasar bambu.",
		difficulty = { Easy = true, Medium = true, Hard = true },
		route = "human",
		weight = 1,
	},
	ledger_erased = {
		displayName = "Buku Jimpitan Dihapus",
		location = "Pos Ronda",
		description = "Catatan setoran kemarin terhapus tidak rapi. Ada nama Pak Joko dekat halaman sobek.",
		difficulty = { Easy = true, Medium = true, Hard = true },
		route = "human",
		weight = 2,
	},
	muddy_sandals = {
		displayName = "Sandal Berlumpur",
		location = "Gang Rumah Pak Joko",
		description = "Lumpur sawah menempel di sandal dekat rumah Pak Joko.",
		difficulty = { Easy = true, Medium = true, Hard = true },
		route = "human",
		weight = 2,
	},
	false_shadow_agus = {
		displayName = "Bayangan di Jendela Agus",
		location = "Rumah Mas Agus",
		description = "Bayangan bergerak di balik jendela, tetapi arahnya tidak sesuai sumber cahaya.",
		difficulty = { Medium = true, Hard = true },
		route = "false",
		isFalse = true,
		weight = -1,
	},
	coin_circle = {
		displayName = "Lingkaran Koin",
		location = "Rumah Kosong",
		description = "Koin jimpitan tersusun melingkar bersama benang merah dan abu kemenyan.",
		difficulty = { Medium = true, Hard = true },
		route = "pesugihan",
		weight = 3,
	},
	wet_footprints = {
		displayName = "Jejak Kaki Basah",
		location = "Gang Gelap",
		description = "Jejak kecil berhenti di dinding. Tidak ada jejak kembali.",
		difficulty = { Medium = true, Hard = true },
		route = "pesugihan",
		weight = 2,
	},
	debt_note = {
		displayName = "Catatan Hutang",
		location = "Warung Pak Joko",
		description = "Catatan hutang besar dengan tanggal yang sama dengan hilangnya setoran.",
		difficulty = { Hard = true },
		route = "human",
		weight = 3,
	},
	ritual_receipt = {
		displayName = "Kertas Mantra",
		location = "Area Ritual",
		description = "Kertas lusuh menyebut setoran kecil sebagai pembuka jalan kekayaan.",
		difficulty = { Hard = true },
		route = "pesugihan",
		weight = 4,
	},
	contradicting_alibi = {
		displayName = "Alibi Bertentangan",
		location = "Dialog Warga",
		description = "Bu Ani dan Pak Joko memberi waktu kejadian yang tidak cocok.",
		difficulty = { Hard = true },
		route = "human",
		weight = 3,
	},
	ritual_token = {
		displayName = "Koin Hangus",
		location = "Rumpun Bambu",
		description = "Koin jimpitan terbakar separuh, seolah dipakai sebagai tanda dalam ritual.",
		difficulty = { Hard = true },
		route = "pesugihan",
		weight = 4,
	},
}

InvestigationData.Puzzles = {
	kentongan_pattern = {
		displayName = "Pola Kentongan",
		description = "Dengarkan pola three pukulan dari pos ronda untuk membuka laci buku jimpitan.",
		requiredDifficulty = "Easy",
		rewardClue = "ledger_erased",
		sequence = { 2, 1, 3 },
	},
	window_shadow = {
		displayName = "Arah Bayangan",
		description = "Bandingkan arah lampu teras dengan bayangan di jendela Mas Agus.",
		requiredDifficulty = "Medium",
		rewardClue = "false_shadow_agus",
		sequence = { 1, 3, 2 },
	},
	ritual_symbols = {
		displayName = "Simbol Ritual",
		description = "Susun simbol koin, abu, dan benang sesuai catatan Mbah Darmo.",
		requiredDifficulty = "Hard",
		rewardClue = "ritual_receipt",
		sequence = { 3, 1, 2, 3 },
	},
}

function InvestigationData.GetClue(clueId: string)
	return InvestigationData.Clues[clueId]
end

function InvestigationData.IsClueAllowed(clueId: string, difficulty: string): boolean
	local clue = InvestigationData.GetClue(clueId)
	return clue ~= nil and clue.difficulty[difficulty] == true
end

function InvestigationData.GetCluesForDifficulty(difficulty: string): {string}
	local clueIds = {}
	for clueId, clue in pairs(InvestigationData.Clues) do
		if clue.difficulty[difficulty] then
			table.insert(clueIds, clueId)
		end
	end
	table.sort(clueIds)
	return clueIds
end

return InvestigationData
