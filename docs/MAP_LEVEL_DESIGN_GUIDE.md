# Jimpitan dan Malam Ronda - Map & Level Design Guide

Dokumen ini berisi panduan *Level Design* untuk merapikan dan mengembangkan map (baik Lobby maupun Main Game). Map Lobby dirancang **kompak 512×512 studs** agar pemain tidak perlu jalan jauh, sedangkan Main Game tetap luas **2048×2048 studs** untuk eksplorasi desa yang immersif.

---

## 0. MAP WORKSPACE PERMANEN

Lobby disimpan sebagai environment final permanen langsung di `Workspace.Map`, bukan dibuat oleh script saat Play:

- **Lobby (512x512 studs)**: spawn di selatan, Pos Ronda di tengah, Easy pad di barat, Medium pad di utara, dan Hard pad di timur. Sekeliling area bermain dikelilingi **hutan desa gelap** sebagai boundary visual alami.
- **Main game (2048×2048 studs)**: gerbang dan spawn di selatan, pos ronda/checkpoint di area selatan, rumah warga 01-08 di rute lingkar, hutan tengah di pusat map, sumur/ritual di tengah, rumah kosong di timur, zona bambu di timur laut, pohon beringin di tenggara.
- Visual lobby dibangun sebagai model final. Tidak ada map builder, marker debug, atau placeholder yang dijalankan saat Play.

Koordinat utama ada di:

```text
src/shared/Modules/Data/WorldData.lua
```

Main game builder masih berada di:

```text
src/game/ServerScriptService/World/VillageWorldBuilder.lua
```

Lobby tidak memiliki builder. `src/lobby/ServerScriptService/Bootstrap.server.lua` hanya menghubungkan sistem queue, matchmaking, dan teleport ke instance permanen yang sudah ada di `Workspace.Map.Gameplay`.

---

## 1. STRUKTUR WORKSPACE (Roblox Studio)
Agar map tidak berantakan di Explorer, gunakan struktur folder yang ketat. Semua objek visual harus dimasukkan ke dalam folder `Workspace.Map`.

```text
Workspace
 └── Map
      ├── Buildings      (Rumah warga, Pos Ronda, landmark desa)
      ├── Foliage        (Pohon pisang, bambu, semak, rumput, hutan keliling)
      ├── Roads          (Jalan aspal rusak, jalan tanah, paving block)
      ├── Props          (Tiang listrik, tempat sampah, jemuran, motor parkir)
      ├── Lights         (Lampu jalan kuning, lampu teras rumah)
      ├── Gameplay       (Zona interact, clue spawns, jimpitan spawns)
      └── Bounds         (Invisible walls/Part transparan untuk batas map)
```
**Tips:** Kunci (Lock) folder `Buildings`, `Roads`, dan `Foliage` saat Anda sedang menempatkan `Props` atau `Gameplay` object agar tidak tergeser secara tidak sengaja.

---

## 2. PANDUAN TATA LETAK DESA (Game Map — 2048×2048 studs)
Agar map tidak terasa sempit dan berantakan, terapkan prinsip **Pacing & Spacing**:

### A. Jarak Antar Bangunan (Renggang & Natural)
- **Jangan menempelkan rumah terlalu rapat** kecuali untuk area spesifik (seperti gang sempit). Di desa Indonesia, biasanya ada pekarangan kecil, selokan, atau kebun di antara rumah.
- Berikan jarak minimal **15-20 studs** antar rumah besar untuk memberikan ruang bagi pemain berlari atau bersembunyi.
- Gunakan pagar bambu, tanaman perdu, atau selokan kecil sebagai pembatas antar rumah.

### B. Lebar Jalan
- **Jalan Utama:** Lebar sekitar **25-30 studs**. Cukup luas untuk memberikan kesan sepi dan *vulnerable* (rentan) saat pemain berjalan di tengahnya pada malam hari.
- **Jalan Gang/Setapak:** Lebar **10-15 studs**. Gunakan gang ini untuk menghubungkan jalan utama, memberikan sensasi klaustrofobia yang kontras dengan jalan utama yang luas.

### C. Pembagian Zona (Zoning)
Bagi desa menjadi beberapa area agar pemain mudah mengingat lokasi (Landmarks):
1. **Zona Pusat (Pos Ronda & Pertigaan):** Area aman (relatif), terang oleh lampu jalan neon kuning/putih, ada radio tua yang berbunyi pelan.
2. **Zona Pemukiman:** Deretan rumah warga. Beberapa teras memiliki lampu yang menyala, beberapa mati total. Tempat utama mencari *Jimpitan*.
3. **Zona Gelap (Kebun Pisang / Sawah / Hutan Bambu):** Sangat minim cahaya, hanya diterangi sinar bulan. Area ini untuk rute pintas, namun *Entity* lebih sering muncul di sini.
4. **Zona Religi/Mistis Opsional:** Bisa ditambahkan nanti di ujung map jika ingin memperluas denah, tetapi generated marker saat ini mengikuti gambar referensi utama.

### D. Penempatan Clue & Jimpitan
- Jangan meletakkan terlalu banyak objek di satu titik. Sebar tempat jimpitan di *cantelan* pagar, tiang teras, atau pintu rumah.
- Berikan *visual cue* (petunjuk visual) seperti cahaya redup di dekat tempat clue penting berada, agar pemain secara natural tertarik ke sana.

### E. BLUEPRINT (Denah Kasar) & INTEGRASI SCRIPT
Untuk memastikan map terasa "lega" (spacious) namun tetap terintegrasi dengan script `MapManager.luau`, ikuti visualisasi tata letak berikut:

```text
=========================================================
[HUTAN BAMBU / BATAS MAP] (Gelap Gulita)
=========================================================
                                    | Gang |
      [RUMAH 1]      (15 studs)     |Sempit|   [MUSHOLA]
       [JS]   [JS]   <-- Jarak -->  |      |     [JS]
....................................|      |................
      JALAN SETAPAK (Lebar 15 studs)               
....................................|      |................
                                    |      |
      [RUMAH 2]      (20 studs)     |      |   [RUMAH 3]
  [JS]                            [POHON]         [JS]
                                  [BESAR]
---------------------------------------------------------
            JALAN UTAMA ASPAL (Lebar 30 studs)           
---------------------------------------------------------
                                          [POS RONDA]
      [RUMAH 4]      (15 studs)           (Titik Start)
   [JS]                                       [JS]
=========================================================
[SAWAH / BATAS MAP] (Gelap Gulita)
=========================================================

Keterangan:
[JS] = JimpitanSpawn (Part transparan seukuran kaleng)
```

**Cara Setup Script Jimpitan:**
1. Di dalam `Workspace.Map`, buat sebuah folder bernama `Gameplay`.
2. Di dalam folder `Gameplay`, buat folder bernama `JimpitanSpawns`.
3. Buat sebuah `Part` kecil (ukuran sekitar `0.5 x 0.5 x 0.5`). Centang `Anchored`, hilangkan centang `CanCollide`, dan set `Transparency` ke `1` (tidak terlihat).
4. Letakkan `Part` ini di tiang teras rumah, pagar, atau pintu tempat Anda ingin uang Jimpitan muncul.
5. Duplikat (Ctrl+D) part tersebut dan sebar (berdasarkan denah `[JS]`) ke seluruh penjuru desa dengan jarak yang berjauhan. Pastikan diletakkan di dalam folder `Workspace.Map.Gameplay.JimpitanSpawns`.
6. Script `MapManager.luau` yang sudah saya buat akan otomatis mendeteksi semua `Part` di folder tersebut dan memunculkan model *Jimpitan* secara acak setiap kali game dimulai!

---

## 3. PANDUAN LOBBY MAP (512×512 studs — KOMPAK)

> **PENTING:** Lobby menggunakan ukuran **512×512 studs** (bukan 2048×2048). Ini sengaja dibuat kecil agar pemain bisa langsung akses semua fitur tanpa jalan jauh. Pemain baru bisa langsung lihat queue pads, shop, dan leaderboard dari spawn point.

### A. Konsep
Sebuah pos kamling / warkop modern di pinggir hutan desa. Pemain muncul di tengah dan langsung bisa melihat semua fasilitas lobby.

### B. Layout Kompak (512×512)
```text
=======================================================
           HUTAN DESA (Forest Ring Boundary)
=======================================================
   [BAMBU]                              [BANYAN TREE]
       \                                    /
        +-------BATAS AREA BERMAIN--------+
        |                                 |
        | [EASY PAD]    [MEDIUM PAD]  [HARD PAD] |
        |    (barat)     (utara)      (timur)    |
        |                                 |
        |      [SHOP]  [POS RONDA]  [LEADERBOARD]|
        |      (kiri)   (tengah)    (kanan)      |
        |                                 |
        |          [SPAWN POINT]          |
        |           (selatan)             |
        +------ radius ~210 studs --------+
       /                                    \
=======================================================
           HUTAN DESA (Forest Ring Boundary)
=======================================================

Jarak spawn → queue pad     : ~100-120 studs (5-6 detik jalan)
Jarak spawn → shop          : ~80-90 studs  (4-5 detik jalan)
Jarak spawn → leaderboard   : ~80-90 studs  (4-5 detik jalan)
Total area bermain          : ~420×420 studs (radius 210)
Total baseplate             : 512×512 studs
```

### C. Forest Ring (Hutan Keliling)
- Sekeliling area bermain dikelilingi hutan gelap (radius 210-256 studs dari pusat).
- 48 pohon penanda + 72 semak membentuk dinding alami.
- Menggantikan invisible wall agar terasa seamless — pemain merasa dikelilingi hutan misterius, bukan tembok tak terlihat.
- Dari dalam lobby, hutan terlihat gelap dan mengundang rasa penasaran tentang desa yang akan dikunjungi.

### D. Lighting
- Gunakan pencahayaan neon (Cyber-village/Modern Horror aesthetic) yang kontras dengan kegelapan hutan di sekeliling.
- Fog distance diperkecil (start: 80, end: 350) karena map lebih kecil.
- Atmosphere haze sedikit lebih tinggi untuk menyembunyikan tepi hutan.

### E. Konfigurasi
Semua koordinat lobby ada di `WorldData.Lobby` dalam file:
```text
src/shared/Modules/Data/WorldData.lua
```

Ukuran lobby dikonfigurasi di `GameConfig.World`:
```lua
LOBBY_MAP_SIZE = 512       -- total baseplate
LOBBY_MAP_HALF_SIZE = 256  -- setengah baseplate
```

Queue pad positions di `GameConfig.Queue.PAD_POSITIONS`:
```lua
Easy   = Vector3.new(-170, 2, -60)
Medium = Vector3.new(0, 2, -170)
Hard   = Vector3.new(170, 2, -60)
```

---

## 4. LIGHTING & ATMOSPHERE SETTINGS (PROPERTIES)
Untuk mendapatkan kesan horor desa yang *cinematic*:

**Di Service `Lighting`:**
- `Technology`: **Future** (Wajib untuk shadow yang realistis dari senter/lampu).
- `Ambient`: `[20, 20, 30]` (Biru sangat gelap).
- `OutdoorAmbient`: `[10, 10, 15]`.
- `Brightness`: `0.5`.
- `ClockTime`: `0.5` (Jam 12:30 Malam).
- `ColorShift_Top`: `[40, 50, 60]` (Bulan pucat).

**Tambahkan di `Lighting`:**
1. **Atmosphere:**
   - `Density`: `0.35` (Kabut tipis menyelimuti).
   - `Offset`: `0.2`.
   - `Color`: `[25, 30, 35]`.
   - `Decay`: `[15, 18, 20]`.
   - `Glare`: `0`.
   - `Haze`: `1.5`.
2. **ColorCorrectionEffect:**
   - `Contrast`: `0.1` (Membuat area gelap benar-benar gelap).
   - `Saturation`: `-0.2` (Warna sedikit pucat/desaturated).

---

## 5. TIPS OPTIMASI MAP
- Aktifkan **StreamingEnabled** di `Workspace` agar map desa yang luas tidak membuat lag pemain dengan HP/PC spesifikasi rendah.
- Gunakan *MeshPart* untuk pohon dan objek kompleks, kurangi penggunaan *Union*.
- Matikan `CastShadow` pada part-part kecil seperti daun, rumput, atau detail prop kecil. Hanya nyalakan `CastShadow` pada bangunan, pohon besar, dan karakter.

---

## 6. RINGKASAN UKURAN MAP

| Map | Ukuran | Alasan |
|-----|--------|--------|
| **Lobby** | 512×512 studs | Kompak, pemain langsung akses semua fitur. Hutan keliling sebagai boundary. |
| **Main Game** | 2048×2048 studs | Luas untuk eksplorasi desa, rute patroli, dan suasana horor. |
