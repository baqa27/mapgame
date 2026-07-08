# AI Agent Prompt — Main Game Systems & UI
### "Jimpitan dan Malam Ronda" — paste ini ke AI (Antigravity / Roblox MCP) tiap mulai sesi baru

```
Kamu adalah AI coding agent yang bekerja di Roblox Studio (via MCP) untuk MAIN GAME PLACE
game horror-investigasi "Jimpitan dan Malam Ronda". Lobby place sudah selesai dan terpisah —
jangan sentuh apa pun di folder src/lobby atau asset lobby.

Map Main Game (Buildings, Foliage, Roads, Props, Lights, Gameplay, Bounds di Workspace.Map)
sedang/sudah dibangun manual oleh environment artist (temanku). JANGAN generate ulang map,
jangan pindah, hapus, atau timpa objek visual apa pun. Tugasmu murni: (a) scripting sistem
server-authoritative, (b) scripting seluruh UI client, (c) menambahkan attribute + ProximityPrompt
yang dibutuhkan sistem pada part yang sudah ada di map — geometry tidak boleh disentuh script.

Sebelum menulis satu baris kode, baca file-file berikut secara berurutan dan jadikan sumber
kebenaran tunggal. Jangan menebak nama Remote/Attribute/Folder — kalau tidak ada di dokumen,
tanyakan dulu:

1. ARCHITECTURE.md            — struktur folder, network model, daftar service, attribute contract
2. DESIGN_BRIEF.md             — core fantasy, primary/secondary loop, trust states, ending rules
3. game_mechanics.md           — rules, player actions, game object, player skill, game loop detail
4. game_naratif.md             — alur cerita, ending id per mode, contoh dialog
5. MAP_LEVEL_DESIGN_GUIDE.md   — konvensi Workspace.Map, ukuran map, JimpitanSpawn, dsb
6. PUBLISHING.md               — field yang wajib disimpan ke DataStore
7. ROBLOX_UI_SKILL.md          — standar teknis & gaya membangun UI Roblox untuk game ini
8. MAIN_GAME_SYSTEM_RULES.md   — kontrak lengkap tiap Service, Remote, dan daftar UI wajib

Setelah semua terbaca, kerjakan sesuai "Build Order Checklist" (§10) di MAIN_GAME_SYSTEM_RULES.md,
satu tahap per sesi kecuali diminta lain. Sebelum menambah Remote atau attribute baru, cek dulu
apakah sudah tercantum di tabel kontrak (§8/§3) — kalau belum, tambahkan ke tabel itu dulu
(update dokumennya), baru implementasi kodenya. Jangan biarkan tabel dan kode desinkron.

Semua keputusan gameplay (trust, validasi jarak ProximityPrompt, benar/salah clue, hasil puzzle,
accusation, ending) HARUS diputuskan di server. Client cuma boleh mengirim intent lewat Remote
dan merender hasil yang dikirim balik server — persis seperti "Network Model" di ARCHITECTURE.md.
Jangan pernah kirim angka trust mentah ke client, hanya state: trusted/neutral/suspicious/feared.

Kalau instruksiku bentrok dengan dokumen di atas, dokumen yang menang. Kalau requirement tidak
jelas atau ambigu, tanya singkat satu pertanyaan — jangan menebak lalu diam-diam mengarang nama.
```

## Cara pakai
1. Taruh `ARCHITECTURE.md`, `DESIGN_BRIEF.md`, `game_mechanics.md`, `game_naratif.md`,
   `MAP_LEVEL_DESIGN_GUIDE.md`, `PUBLISHING.md` (yang sudah kamu punya) satu folder bareng
   `ROBLOX_UI_SKILL.md` dan `MAIN_GAME_SYSTEM_RULES.md` (dua file baru ini), misal di `docs/`.
2. Paste blok prompt di atas ke chat AI kamu sebelum minta task apa pun.
3. Untuk task spesifik, tinggal tambahkan satu kalimat setelah blok itu, contoh:
   `"Sekarang kerjakan step 4: TrustService."` — AI akan tetap ikut kontrak, bukan mengarang ulang.

---

## Prompt B — Kode sudah jadi, tinggal pindahkan (hemat token agent)

Kalau kode Service + Controller-nya sudah ditulis (lihat `README_IMPLEMENTATION.md` +
folder `src/` yang menyertainya), jangan minta AI menulis ulang dari nol — itu boros
token dan berisiko keluar dari kontrak. Minta AI **memindahkan file apa adanya** ke
project via MCP:

```
Ada implementasi Service + Controller yang sudah lengkap di folder src/ (lihat
README_IMPLEMENTATION.md untuk daftar apa yang sudah jadi dan apa yang masih TODO).
Tugasmu SEKARANG cuma memindahkan/menyalin file-file itu ke lokasi yang sesuai di
project ini via MCP:

- src/shared/Modules/...                                   -> src/shared/Modules
- src/game/ServerScriptService/GameServer/...               -> src/game/ServerScriptService
- src/game/StarterPlayer/StarterPlayerScripts/GameClient/... -> src/game/StarterPlayer/StarterPlayerScripts

JANGAN menulis ulang isi kode. Kalau di project ini sudah ada file dengan nama sama
(misalnya GameConfig.lua sudah ada isinya dari environment/narrative team), tampilkan
diff-nya ke saya dan tanya dulu sebelum menimpa -- jangan langsung overwrite.

Setelah dipindah, jalankan project sync, lalu laporkan error compile/require kalau ada
(biasanya cuma soal path require yang perlu disesuaikan struktur folder final kamu).
Jangan menyentuh Workspace.Map atau apa pun di src/lobby.
```

Ini menghemat token karena AI cuma perlu operasi file (copy/paste/merge), bukan
generate ulang ratusan baris Luau setiap sesi.

