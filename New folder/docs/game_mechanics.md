# Game Mechanics & Loop

Dokumen ini adalah hasil konversi dari PDF ke Markdown agar mudah dibaca oleh AI agent lain. Isi dipertahankan dari dokumen sumber dengan perapian format, penggabungan baris yang terpotong, dan normalisasi tanda baca.

- Sumber PDF: `C:\Users\sulta\Downloads\GAME MECHANICS-Jimpitan dan malam Ngeronda - Google Dokumen.pdf`
- Tanggal: 29 April 2026
- Project Manager: Muhammad Sultan Baqa
- Kelas: 04 Pengembangan Game
- Judul Game: Jimpitan dan Malam Ronda
- Team:
  - Titi Alfiana Pramesti
  - Ida Masruroh

## A. Rules

1. Pemain harus menyelesaikan tugas ronda malam dengan mengumpulkan jimpitan dan menemukan petunjuk sebelum waktu ronda berakhir pada setiap level.
2. Gagal menyelesaikan misi, salah mengambil keputusan penting, atau kehilangan terlalu banyak kepercayaan warga akan menyebabkan pemain kembali ke checkpoint sebelumnya.
3. Tingkat kepercayaan (trust) warga bersifat kritikal, di mana penurunan trust dapat membatasi akses dialog, informasi, dan bahkan menghambat progres permainan.
4. Petunjuk yang tersedia memiliki tingkat kejelasan yang berbeda pada setiap level, yaitu jelas pada easy, semi-ambigu pada medium, dan ambigu pada hard, sehingga pemain harus menyesuaikan cara analisisnya.
5. Beberapa dialog dan informasi hanya dapat diakses jika pemain telah menemukan petunjuk tertentu atau mencapai tingkat kepercayaan tertentu dengan NPC.
6. Gangguan mistis muncul secara acak selama permainan dan dapat mempengaruhi persepsi pemain, memunculkan false clue sementara, serta mengganggu fokus investigasi.
7. Pemain harus menyelesaikan puzzle untuk membuka akses terhadap petunjuk, area baru, atau perkembangan cerita.
8. Lingkungan malam hari berfungsi sebagai pembatas (environmental limiter), di mana keterbatasan pencahayaan dan suasana meningkatkan kesulitan eksplorasi dan investigasi.
9. Jika pemain mengalami kegagalan investigasi berulang sebanyak beberapa kali, sistem akan membuka hint opsional untuk membantu pemain melanjutkan investigasi.

## B. Player Actions

### Explore

- Deskripsi: Pemain berjalan dan menjelajahi lingkungan desa pada malam hari, mengunjungi rumah warga, serta berinteraksi dengan objek di sekitar.
- Dampak: Membuka area baru, menemukan jimpitan, serta memicu event atau petunjuk tersembunyi.

### Collect Item

- Deskripsi: Pemain mengambil jimpitan dan item lain yang berkaitan dengan investigasi dari rumah warga atau lingkungan sekitar.
- Dampak: Menambah informasi atau bukti yang dapat digunakan dalam proses investigasi dan penyelesaian puzzle.

### Investigate

- Deskripsi: Pemain mengamati lingkungan, memeriksa objek tertentu, dan mengumpulkan petunjuk yang berkaitan dengan kejadian hilangnya uang.
- Dampak: Membuka informasi baru, memperjelas alur kejadian, serta membantu pemain dalam menentukan pelaku.

### Solve Puzzle

- Deskripsi: Pemain menyelesaikan puzzle berbasis logika dan observasi yang berkaitan dengan petunjuk atau kondisi lingkungan.
- Dampak: Membuka akses ke petunjuk penting, area baru, atau perkembangan cerita.

### Dialogue Choice

- Deskripsi: Pemain memilih opsi dialog saat berinteraksi dengan NPC untuk mendapatkan informasi atau merespon situasi sosial.
- Dampak: Mempengaruhi tingkat kepercayaan warga, respon sosial NPC, akses informasi, perubahan lingkungan sosial, serta jalur cerita.

### Make Decision

- Deskripsi: Pemain menentukan dugaan pelaku berdasarkan petunjuk yang telah dikumpulkan serta mengambil keputusan penting dalam permainan.
- Dampak: Menentukan perkembangan cerita, mempengaruhi ending, respon warga, perubahan akses area tertentu, serta berdampak besar pada sistem kepercayaan warga.

### Avoid Disturbance

- Deskripsi: Pemain menghindari gangguan mistis yang muncul secara acak seperti suara, bayangan, atau kejadian aneh selama eksplorasi.
- Dampak: Menjaga fokus pemain, menghindari gangguan persepsi, false clue, serta mempertahankan akurasi investigasi.

### Observe Behavior

- Deskripsi: Pemain memperhatikan perilaku dan respon NPC untuk mendeteksi kejanggalan atau indikasi kecurigaan.
- Dampak: Membantu dalam proses analisis dan meningkatkan akurasi dalam menentukan pelaku.

## C. Game Object

### Quest Item

- Contoh object: Uang jimpitan, catatan warga, barang bukti.
- Fungsi gameplay: Menjadi tujuan utama misi serta bahan utama dalam proses investigasi.

### Clue Object

- Contoh object: Kondisi rumah yang berubah, benda mencurigakan, suara atau benda aneh.
- Fungsi gameplay: Memberikan petunjuk yang membantu pemain dalam menganalisis dan menentukan pelaku.

### Puzzle Object

- Contoh object: Pola objek, mekanisme sederhana di lingkungan.
- Fungsi gameplay: Digunakan untuk menyelesaikan puzzle yang membuka akses ke petunjuk atau area baru.

### NPC

- Contoh object: Pak RT, warga desa, karakter mencurigakan.
- Fungsi gameplay: Sumber informasi, pemberi misi, serta elemen utama dalam sistem dialog dan trust.

### Suspect Character

- Contoh object: Warga dengan perilaku mencurigakan atau informasi yang tidak konsisten.
- Fungsi gameplay: Menjadi target investigasi dan menentukan arah pengambilan keputusan pemain.

### Environmental Object

- Contoh object: Rumah warga, pos ronda, jalan desa, area gelap, serta petunjuk visual lingkungan seperti lampu berkedip, suara tertentu, dan perubahan kondisi area.
- Fungsi gameplay: Menjadi ruang eksplorasi dan tempat ditemukannya item dan clue.

### Environmental Hazard (Mistis)

- Contoh object: Suara aneh, bayangan, entitas mistis.
- Fungsi gameplay: Memberikan tekanan psikologis, mengganggu fokus pemain, dan meningkatkan suasana horor.

### UI Object

- Contoh object: Minimap, jurnal petunjuk (clue journal), notifikasi sistem, serta indikator trust sederhana berupa simbol atau respon visual NPC.
- Fungsi gameplay: Membantu navigasi, menampilkan progres pemain, serta memberikan informasi penting selama permainan.

### Checkpoint

- Contoh object: Pos ronda, titik tertentu setelah investigasi atau pengumpulan jimpitan.
- Fungsi gameplay: Menjadi titik penyimpanan progres pemain dan tempat kembali saat gagal.

## D. Player Skill

### Observation

- Cara muncul di game: Pemain mengamati lingkungan desa, menemukan kejanggalan di rumah warga, serta mengidentifikasi petunjuk tersembunyi seperti jejak, posisi barang, atau perubahan kondisi lingkungan.
- Aspek yang dilatih: Logika, ketelitian, dan perhatian terhadap detail.

### Analytical Thinking

- Cara muncul di game: Pemain menghubungkan berbagai petunjuk yang ditemukan untuk membangun kesimpulan dan menentukan kemungkinan pelaku berdasarkan informasi yang terbatas dan terkadang ambigu.
- Aspek yang dilatih: Penalaran logis, analisis informasi, dan pengambilan kesimpulan.

### Problem Solving

- Cara muncul di game: Pemain menyelesaikan puzzle berbasis logika dan observasi untuk membuka akses ke petunjuk baru atau melanjutkan investigasi.
- Aspek yang dilatih: Kemampuan memecahkan masalah dan berpikir sistematis.

### Decision Making

- Cara muncul di game: Pemain memilih opsi dalam dialog, menentukan siapa yang dicurigai, serta mengambil keputusan penting yang berdampak pada jalannya permainan dan tingkat kepercayaan warga.
- Aspek yang dilatih: Pengambilan keputusan, evaluasi risiko, dan tanggung jawab terhadap konsekuensi.

### Emotional Control

- Cara muncul di game: Pemain menghadapi gangguan mistis secara acak seperti suara, bayangan, atau kejadian tidak terduga yang dapat mengganggu fokus saat bermain.
- Aspek yang dilatih: Kontrol emosi, konsentrasi, dan ketahanan mental.

### Social Awareness

- Cara muncul di game: Pemain berinteraksi dengan NPC, membaca situasi sosial, serta memahami respon warga yang dipengaruhi oleh tingkat kepercayaan terhadap pemain.
- Aspek yang dilatih: Empati, pemahaman sosial, dan komunikasi interpersonal.

## E. Game Loop

### Core Loop

#### Challenge

- Deskripsi spesifik: Pemain menerima tugas ronda malam untuk mengumpulkan jimpitan sekaligus menghadapi kasus hilangnya uang warga yang semakin kompleks di setiap level.
- Contoh di game: "Kumpulkan jimpitan dari seluruh rumah di RT ini dan cari tahu kenapa uang warga mulai hilang."

#### Action

- Deskripsi spesifik: Pemain melakukan eksplorasi desa, mengumpulkan jimpitan, mencari dan menganalisis petunjuk, menyelesaikan puzzle berbasis logika, berinteraksi dengan NPC melalui dialog bercabang yang mempengaruhi respon sosial warga, serta menghadapi gangguan mistis yang dapat mempengaruhi persepsi investigasi.
- Contoh di game: Pemain berkeliling desa, mengambil jimpitan, menemukan jejak mencurigakan di salah satu rumah, lalu berbicara dengan warga untuk mencari informasi tambahan sambil menghindari gangguan seperti suara atau bayangan.

#### Outcome

- Deskripsi spesifik: Hasil yang diperoleh pemain bergantung pada keberhasilan dalam melakukan investigasi dan pengambilan keputusan, baik dalam menemukan petunjuk maupun menentukan dugaan pelaku.
- Contoh di game: Pemain berhasil menemukan petunjuk penting dari rumah warga, atau justru salah menuduh seseorang sehingga informasi menjadi terbatas.

#### Reward

- Deskripsi spesifik: Keberhasilan pemain akan memberikan informasi baru, membuka akses dialog tambahan, serta meningkatkan kepercayaan warga. Kegagalan akan menurunkan tingkat kepercayaan dan dapat menyebabkan pemain kembali ke checkpoint.
- Contoh di game: Trust warga meningkat sehingga NPC memberikan informasi rahasia dan bantuan investigasi tambahan, atau trust menurun sehingga warga menolak berbicara, area tertentu tertutup, dan pemain harus mengulang dari checkpoint.

#### Loop Back

- Deskripsi spesifik: Pemain melanjutkan ronda berikutnya dengan tingkat kesulitan yang meningkat, diiringi perubahan kondisi sosial dan gangguan mistis yang semakin intens.
- Contoh di game: Setelah satu malam selesai, pemain melanjutkan ronda berikutnya dengan lebih banyak konflik antar warga dan kejadian mistis yang lebih sering muncul.

### Secondary Loop

#### Investigation Loop

- Fokus: Mengumpulkan, membandingkan, dan menyimpulkan petunjuk untuk menentukan pelaku.
- Fungsi: Mendorong pemain untuk mengumpulkan, membandingkan, dan menganalisis petunjuk guna menentukan pelaku secara logis maupun interpretatif.

#### Horror Loop

- Fokus: Menghadapi gangguan mistis acak yang mempengaruhi persepsi dan fokus pemain.
- Fungsi: Menciptakan tekanan psikologis melalui gangguan mistis acak yang dapat mempengaruhi fokus dan persepsi pemain selama bermain.

#### Social Loop (Trust System)

- Fokus: Interaksi dengan NPC mempengaruhi kepercayaan warga yang berdampak langsung pada akses informasi dan ending.
- Fungsi: Mengatur hubungan antara pemain dan NPC, di mana tingkat kepercayaan akan mempengaruhi akses informasi, jalannya cerita, serta kemungkinan ending.

#### Progression Loop

- Fokus: Perkembangan dari konflik sosial (easy), ambigu (medium), hingga kompleks dan mistis (hard).
- Fungsi: Memberikan perkembangan pengalaman bermain dari konflik sosial sederhana hingga konflik kompleks yang melibatkan unsur mistis dan ambiguitas.

## F. Masukan dan Status Revisi

### 1. Hint opsional saat gagal berulang

- Status: Diambil.
- Alasan: Membantu pemain yang mengalami stuck saat investigasi tanpa langsung menghilangkan tantangan utama gameplay.

### 2. Indikator trust diperjelas

- Status: Diambil.
- Alasan: Trust merupakan sistem inti yang mempengaruhi dialog, informasi, dan ending sehingga pemain membutuhkan feedback visual yang lebih jelas.

### 3. Gangguan mistis lebih aktif

- Status: Diambil sebagian.
- Alasan: Gangguan mistis ditambahkan pengaruhnya terhadap persepsi dan investigasi, tetapi tidak dibuat terlalu agresif agar fokus game tetap pada investigasi sosial.

### 4. Dampak keputusan lebih terasa

- Status: Diambil.
- Alasan: Agar pemain merasakan konsekuensi nyata dari pilihan yang diambil melalui perubahan respon NPC, akses informasi, dan kondisi lingkungan.

### 5. Petunjuk visual/desain level lebih halus

- Status: Diambil.
- Alasan: Membantu pemain menemukan arah investigasi secara natural tanpa mengurangi rasa eksplorasi dan misteri.

### 6. Gangguan mistis terlalu agresif seperti chase/combat

- Status: Tidak diambil.
- Alasan: Akan mengubah fokus game menjadi survival horror.

### 7. Hint langsung menunjukkan jawaban

- Status: Tidak diambil.
- Alasan: Mengurangi elemen investigasi dan analisis.

### 8. Trust menggunakan angka detail penuh

- Status: Tidak diambil.
- Alasan: Mengurangi nuansa misteri dan immersion.
