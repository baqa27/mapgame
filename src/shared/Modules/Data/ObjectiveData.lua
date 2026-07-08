--!strict

local GameConfig = require(script.Parent.Parent.GameConfig)

local ObjectiveData = {}

ObjectiveData.Chains = {
	Easy = {
		{
			id = "brief_pak_rt",
			type = GameConfig.Objectives.Types.BRIEFING,
			title = "Temui Pak RT",
			description = "Dengarkan briefing di pos ronda.",
			target = 1,
			checkpoint = GameConfig.Checkpoints.INTRO_COMPLETE,
		},
		{
			id = "collect_jimpitan_easy",
			type = GameConfig.Objectives.Types.COLLECT_JIMPITAN,
			title = "Ambil Jimpitan",
			description = "Kumpulkan jimpitan dari rumah warga.",
			target = 5,
			checkpoint = GameConfig.Checkpoints.JIMPITAN_COLLECTED,
		},
		{
			id = "inspect_missing_easy",
			type = GameConfig.Objectives.Types.FIND_CLUE,
			title = "Periksa Tabung Kosong",
			description = "Cari petunjuk pertama dari rumah yang kehilangan uang.",
			target = 2,
			checkpoint = GameConfig.Checkpoints.FIRST_CLUE_FOUND,
		},
		{
			id = "talk_witness_easy",
			type = GameConfig.Objectives.Types.TALK_NPC,
			title = "Bicara dengan Warga",
			description = "Kumpulkan keterangan dari warga yang melihat sesuatu.",
			target = 2,
		},
		{
			id = "accuse_easy",
			type = GameConfig.Objectives.Types.DETERMINE_SUSPECT,
			title = "Tentukan Pelaku",
			description = "Gunakan bukti untuk menentukan pelaku pencurian.",
			target = 1,
			checkpoint = GameConfig.Checkpoints.ENDING_CHOICE,
		},
	},
	Medium = {
		{
			id = "brief_pak_rt",
			type = GameConfig.Objectives.Types.BRIEFING,
			title = "Terima Tugas Ronda",
			description = "Pak RT mengubah aturan setoran malam ini.",
			target = 1,
			checkpoint = GameConfig.Checkpoints.INTRO_COMPLETE,
		},
		{
			id = "collect_jimpitan_medium",
			type = GameConfig.Objectives.Types.COLLECT_JIMPITAN,
			title = "Setor Langsung",
			description = "Kumpulkan jimpitan dan setor dengan hati-hati.",
			target = 7,
			checkpoint = GameConfig.Checkpoints.JIMPITAN_COLLECTED,
		},
		{
			id = "compare_clues_medium",
			type = GameConfig.Objectives.Types.FIND_CLUE,
			title = "Bandingkan Bukti",
			description = "Pisahkan bukti nyata dari bayangan yang menyesatkan.",
			target = 4,
			checkpoint = GameConfig.Checkpoints.KEY_CLUE_FOUND,
		},
		{
			id = "solve_shadow_medium",
			type = GameConfig.Objectives.Types.SOLVE_PUZZLE,
			title = "Uji Arah Bayangan",
			description = "Cari tahu apakah Mas Agus benar-benar terlihat di jendela.",
			target = 1,
		},
		{
			id = "accuse_medium",
			type = GameConfig.Objectives.Types.DETERMINE_SUSPECT,
			title = "Pilih Jalur Kebenaran",
			description = "Tentukan apakah kasus ini manusia biasa atau pesugihan.",
			target = 1,
			checkpoint = GameConfig.Checkpoints.ENDING_CHOICE,
		},
	},
	Hard = {
		{
			id = "brief_pak_rt",
			type = GameConfig.Objectives.Types.BRIEFING,
			title = "Desa Tidak Aman",
			description = "Pak RT meminta bukti, bukan tuduhan.",
			target = 1,
			checkpoint = GameConfig.Checkpoints.INTRO_COMPLETE,
		},
		{
			id = "collect_jimpitan_hard",
			type = GameConfig.Objectives.Types.COLLECT_JIMPITAN,
			title = "Ronda Penuh",
			description = "Kumpulkan semua jimpitan sebelum warga kehilangan sabar.",
			target = 8,
			checkpoint = GameConfig.Checkpoints.JIMPITAN_COLLECTED,
		},
		{
			id = "map_pattern_hard",
			type = GameConfig.Objectives.Types.INVESTIGATE_AREA,
			title = "Petakan Pola Hilang",
			description = "Tandai rumah, gang, dan area ritual yang saling terhubung.",
			target = 3,
		},
		{
			id = "collect_key_clues_hard",
			type = GameConfig.Objectives.Types.FIND_CLUE,
			title = "Kumpulkan Bukti Kunci",
			description = "Buktikan konflik manusia dan ritual pesugihan.",
			target = 7,
			checkpoint = GameConfig.Checkpoints.KEY_CLUE_FOUND,
		},
		{
			id = "solve_ritual_hard",
			type = GameConfig.Objectives.Types.SOLVE_PUZZLE,
			title = "Buka Pola Ritual",
			description = "Susun tanda ritual tanpa memicu kepanikan warga.",
			target = 1,
			checkpoint = GameConfig.Checkpoints.PRE_CLIMAX,
		},
		{
			id = "accuse_hard",
			type = GameConfig.Objectives.Types.DETERMINE_SUSPECT,
			title = "Ungkap Kebenaran Penuh",
			description = "Tentukan pelaku manusia dan keterlibatan ritual.",
			target = 1,
			checkpoint = GameConfig.Checkpoints.ENDING_CHOICE,
		},
	},
}

function ObjectiveData.GetChain(difficulty: string)
	return ObjectiveData.Chains[difficulty] or ObjectiveData.Chains.Easy
end

return ObjectiveData
