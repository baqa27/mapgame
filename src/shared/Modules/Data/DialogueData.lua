--!strict

local DialogueData = {}

DialogueData.Dialogues = {
	pak_rt = {
		start = "start",
		nodes = {
			start = {
				line = "Kamu sudah siap ronda? Ingat, catat dulu sebelum menyimpulkan.",
				choices = {
					{
						id = "accept_briefing",
						text = "Saya siap, Pak.",
						nextNode = "briefing",
						objectiveProgress = "brief_pak_rt",
						trustAction = "COMPLETED_TASK",
					},
					{
						id = "ask_missing",
						text = "Sudah berapa kali uang hilang?",
						nextNode = "missing_context",
						requiredTrust = "neutral",
					},
				},
			},
			briefing = {
				line = "Mulai dari rumah Bu Siti. Kalau ada tabung kosong, jangan ributkan dulu.",
				choices = {
					{ id = "close", text = "Saya berangkat.", close = true },
				},
			},
			missing_context = {
				line = "Tiga malam. Mungkin empat. Buku catatan juga tidak sepenuhnya rapi.",
				choices = {
					{ id = "ledger", text = "Saya akan cek buku catatan.", grantClue = "ledger_erased", close = true },
				},
			},
		},
	},
	bu_siti = {
		start = "start",
		nodes = {
			start = {
				line = "Saya sudah isi tabung itu, Nak. Koinnya tidak mungkin hilang sendiri.",
				choices = {
					{ id = "calm", text = "Saya cek pelan-pelan, Bu.", trustAction = "HELPED_WARGA", grantClue = "empty_can_siti", close = true },
					{ id = "pressure", text = "Ibu yakin tidak lupa?", trustAction = "WRONG_DIALOGUE", close = true },
				},
			},
		},
	},
	mas_agus = {
		start = "start",
		nodes = {
			start = {
				line = "Kalau cuma karena saya baru pulang dari kota, semua orang jadi curiga?",
				choices = {
					{ id = "apologize", text = "Saya cari fakta, bukan gosip.", trustAction = "CORRECT_DIALOGUE", close = true },
					{ id = "accuse_soft", text = "Ada yang melihat bayangan di rumahmu.", nextNode = "shadow" },
				},
			},
			shadow = {
				line = "Bayangan? Lampu depan saya mati dari sore. Cek saja kalau tidak percaya.",
				choices = {
					{ id = "inspect_shadow", text = "Saya akan cek arah lampunya.", objectiveProgress = "solve_shadow_medium", close = true },
				},
			},
		},
	},
	pak_joko = {
		start = "start",
		nodes = {
			start = {
				line = "Saya cuma pulang dari warung. Jangan samakan hutang dengan mencuri.",
				choices = {
					{ id = "ask_debt", text = "Kenapa catatan hutangmu tanggalnya sama?", requiredClue = "debt_note", nextNode = "debt" },
					{ id = "observe", text = "Saya hanya mencocokkan keterangan.", close = true },
				},
			},
			debt = {
				line = "Semua orang punya masalah. Tapi tidak semua orang diberi jalan keluar.",
				choices = {
					{ id = "ritual_hint", text = "Jalan keluar seperti apa?", grantClue = "contradicting_alibi", trustAction = "CORRECT_DIALOGUE", close = true },
				},
			},
		},
	},
	bu_ani = {
		start = "start",
		nodes = {
			start = {
				line = "Saya tidak mau menuduh, tapi malam-malam itu Pak Joko sering lewat gang kosong.",
				choices = {
					{ id = "ask_time", text = "Jam berapa Ibu melihatnya?", grantClue = "contradicting_alibi", close = true },
					{ id = "spread", text = "Beri tahu warga lain agar waspada.", trustAction = "TRIGGERED_PANIC", close = true },
				},
			},
		},
	},
	mbah_darmo = {
		start = "start",
		nodes = {
			start = {
				line = "Tidak semua yang kecil itu tidak berharga. Koin bisa jadi tanda.",
				requiredTrust = "trusted",
				choices = {
					{ id = "ask_symbol", text = "Tanda seperti apa, Mbah?", grantClue = "ritual_token", close = true },
				},
			},
			locked = {
				line = "Kalau warga belum percaya padamu, ucapanku hanya akan jadi fitnah baru.",
				choices = {
					{ id = "close", text = "Saya akan kembali nanti.", close = true },
				},
			},
		},
	},
}

function DialogueData.GetDialogue(npcId: string)
	return DialogueData.Dialogues[npcId]
end

return DialogueData
