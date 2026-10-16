# 🌴 RP-Plugin - Panduan Sistem Dasar Live Economy & Studio Plugin

Selamat datang di repositori framework **RP-Plugin (Live Economy Suite)**. Sistem ini dibuat khusus untuk developer map Roblox bertema **Roleplay Indonesia (Pulau / Pesisir / Kota)** dengan fokus pada **Live Economy** (ekonomi hidup dalam server): perdagangan langsung antar pemain (P2P Trade), sistem pencetakan uang (Faucet), dan sistem pembakaran/pengeluaran uang (Sink) agar server tidak mengalami hiperinflasi.

---

## 📁 Struktur Proyek

```text
RP-Plugin/
├── plugin/
│   └── LiveEconomy_StudioPlugin.server.luau  <-- File Plugin Roblox Studio (DockWidget UI)
├── tools/
│   ├── InstallCommandBar.luau                <-- Script 1-Click untuk Command Bar Studio
│   └── bundle_installer.js                  <-- Generator bundler otomatis
├── framework/
│   ├── ReplicatedStorage/
│   │   └── EconomySystem/
│   │       ├── Config/
│   │       │   └── EconomyConfig.luau        <-- Konfigurasi Rupiah, Item, Job, Pajak
│   │       └── Modules/
│   │           ├── EconomyNetwork.luau       <-- RemoteEvent & RemoteFunction handler
│   │           └── Types.luau                <-- Type definition (Luau strict mode)
│   ├── ServerScriptService/
│   │   └── EconomySystem/
│   │       ├── EconomyServer.server.luau     <-- Server Controller Utama
│   │       └── Services/
│   │           ├── WalletService.luau        <-- Manajemen Kas, Bank & DataStore
│   │           ├── TradeService.luau         <-- Sistem P2P Trade Atomik & Pajak
│   │           ├── JobService.luau           <-- Payday & Sistem Pekerjaan
│   │           └── ShopService.luau          <-- Toko Warung & Penjualan Komoditas
│   └── StarterPlayer/
│       └── StarterPlayerScripts/
│           └── EconomySystem/
│               └── EconomyClient.client.luau <-- HUD Dompet, Notifikasi & Interaksi Proximity
└── default.project.json                      <-- Konfigurasi Rojo (Opsional)
```

---

## 🚀 3 Cara Pemasangan ke Map Roblox Studio

Pilihlah salah satu cara termudah berikut:

### CARA 1: Menggunakan Plugin Studio (Sangat Direkomendasikan ⭐)
1. Buka Roblox Studio dan buka Map Anda.
2. Buat sebuah **Script** baru di Roblox Studio (misal di ServerStorage atau Workspace).
3. Salin seluruh isi dari file [`LiveEconomy_StudioPlugin.server.luau`](../plugin/LiveEconomy_StudioPlugin.server.luau).
4. Klik kanan pada script tersebut di Roblox Studio Explorer -> Pilih **"Save as Local Plugin..."**.
5. Simpan plugin tersebut. Di toolbar atas Roblox Studio sekarang akan muncul menu **"IndoRP Live Economy"** dengan tombol **"Live Economy Suite"**!
6. Buka panel tersebut, lalu klik tombol **"🚀 Pasang / Update Framework Otomatis"**. Seluruh folder, modul, dan script akan otomatis diinjeksi ke tempat yang tepat!

---

### CARA 2: Melalui Command Bar (Instan 1 Detik ⚡)
Jika Anda tidak ingin memasang plugin lokal:
1. Buka Roblox Studio dan muat file map game Anda.
2. Pastikan jendela **Command Bar** terbuka (Menu atas: `View` -> centang `Command Bar`).
3. Buka file [`tools/InstallCommandBar.luau`](../tools/InstallCommandBar.luau).
4. Copy seluruh kodenya, lalu Paste ke kolom Command Bar di bagian bawah Roblox Studio dan tekan **Enter**.
5. Selesai! Seluruh struktur ReplicatedStorage, ServerScriptService, dan StarterPlayerScripts langsung terpasang dan siap dimainkan!

---

### CARA 3: Menggunakan Rojo (Bagi Developer Profesional 🛠️)
Jika Anda menggunakan VS Code dan Rojo:
1. Buka terminal di folder proyek ini.
2. Jalankan:
   ```bash
   rojo serve
   ```
3. Di Roblox Studio, buka plugin Rojo dan klik **Connect**. Semua script akan tersinkronisasi otomatis secara realtime!

---

## 💎 Konsep Live Economy (Keseimbangan Faucet vs Sink)

Masalah terbesar game Roleplay di Roblox adalah **Hiperinflasi** (pemain terlalu cepat kaya, uang menjadi tidak berharga, dan pasar jual-beli antar pemain mati). Framework ini menerapkan rumus ekonomi berimbang:

```
[ TOTAL UANG MASUK (FAUCET) ]  ≈  [ TOTAL UANG KELUAR/HANGUS (SINK) ]
```

### 1. 🟢 Faucet (Sumber Penghasilan Pemain)
- **Gaji Pekerjaan (Payday)**:
  - Pembagian upah otomatis setiap 5 menit (dapat diubah di `EconomyConfig.luau`).
  - Gaji langsung ditransfer ke rekening bank untuk keamanan.
  - Pekerjaan tersedia: **Warga Bebas (Bansos)**, **Kurir Ekspedisi**, **Nelayan**, **Pedagang**, **Polisi**, **Tenaga Medis**.
- **Komoditas & Hasil Alam**:
  - Nelayan menangkap ikan tongkol/kakap dan menjualnya ke **Dermaga TPI** untuk mendapatkan uang tunai instan.
- **Tugas Harian & Misi**:
  - Kurir yang berhasil mengantar paket ke warga menerima komisi tunai.

### 2. 🔴 Sink (Pengeluaran & Pembakaran Uang Server)
- **Kebutuhan Hidup (Lapar & Haus)**:
  - Pemain harus membeli makanan di Warung (Nasi Goreng, Mie Ayam, Es Teh, Kopi). Uang pembelian ini **dihapus dari server (burned)**.
- **Pajak Perdagangan P2P (Trade Tax / Pajak Pasar)**:
  - Setiap kali dua pemain bertransaksi uang tunai secara langsung, **3.5% uang dipotong otomatis sebagai pajak pulau**. Hal ini mencegah peredaran uang gelap dan menarik uang berlebih dari server.
- **Biaya Administrasi Bank**:
  - Transfer uang antar rekening bank dikenakan biaya admin 1% (minimal Rp 2.500).
- **Pengeluaran Tambahan**:
  - Pembelian surat izin (SIM, Izin Lapak Pasar), peralatan kerja (Joran Pancing), dan biaya rawat inap puskesmas saat pingsan.

### 3. 🤝 Sistem P2P Trade Atomik (Anti-Scam & Anti-Dupe)
- **Verifikasi Dua Arah**: Kedua pemain harus memasukkan penawaran dan mengunci (Lock).
- **Proteksi Pengubahan Menit Akhir**: Jika salah satu pemain mengubah jumlah uang atau item, status Lock lawan otomatis terlepas untuk mencegah scam penukaran cepat.
- **Jeda Hitung Mundur (Countdown)** sebelum transaksi final sah.
- **Pengecekan Jarak Fisik (Proximity)**: Karakter harus berjarak maksimal 15 studs saat transaksi terjadi.
- **Eksekusi Atomik Server**: Semua saldo dan slot inventori diperiksa ulang oleh server sebelum barang ditukar. Jika ada 1 item yang tidak valid, seluruh transaksi dibatalkan dengan aman (Rollback).

---

## 🛠️ Fitur Panel Studio Plugin

Di dalam panel Studio Plugin terdapat 3 modul utama:
1. **Kontrol Dasar Framework**:
   - Mendeteksi apakah komponen sistem telah terpasang.
   - Tombol instalasi sekali klik.
2. **Quick Prop & Node Spawner**:
   - **Spawn Mesin ATM**: Menaruh model ATM Bank lengkap dengan layar neon, keypad, dan `ProximityPrompt` ("Gunakan ATM").
   - **Spawn Warung Kelontong**: Menaruh model warung/minimarket khas Indonesia lengkap dengan kanopi dan `ProximityPrompt` ("Beli Makanan").
   - **Spawn Pos Ekspedisi**: Menaruh meja kerja pendaftaran profesi Kurir.
   - **Spawn Dermaga TPI**: Menaruh dermaga kayu dengan kotak es penyimpanan ikan untuk nelayan menjual hasil tangkapan.
   - **Spawn Area Pasar (Safe Trade Zone)**: Menaruh penanda zona perdagangan bebas aman antar warga.
3. **Live Economy Balancer**:
   - Menghitung simulasi peredaran uang 20 pemain secara matematis.
   - Tombol **Audit Report** yang membaca parameter `EconomyConfig` aktif dan memberikan saran penyesuaian inflasi di konsol output.

---

## ⚙️ Cara Menambah Item & Pekerjaan Baru

Buka file [`EconomyConfig.luau`](../framework/ReplicatedStorage/EconomySystem/Config/EconomyConfig.luau):

### Menambah Item Baru di Toko:
```lua
["food_sate"] = {
    Id = "food_sate",
    Name = "Sate Ayam Madura",
    Category = "Consumable",
    BasePrice = 25000,
    SellPrice = 6000,
    Description = "Sate ayam bumbu kacang gurih khas pulau.",
    MaxStack = 10,
    SinkEffect = { Hunger = 75, Health = 15 },
},
```

### Menambah Pekerjaan Baru:
```lua
["Miner"] = {
    Id = "Miner",
    Title = "Pekerja Tambang Pasir",
    Department = "Sipil",
    BaseSalaryPerCycle = 85000,
    SalaryIntervalSeconds = 300,
    RequirementLevel = 1,
    Description = "Mengumpulkan pasir dan material tambang untuk pembangunan pulau.",
},
```

---

## 🔒 Konfigurasi DataStore (Penyimpanan Saldo & Data)

Secara default, jika dijalankan di Studio tanpa Game Settings DataStore, sistem menggunakan **Memory Cache** sehingga aman diuji coba saat testing tanpa error.

Untuk mengaktifkan penyimpanan permanen ke database Roblox:
1. Buka **Home** -> **Game Settings** di Roblox Studio.
2. Buka tab **Security**.
3. Aktifkan **"Enable Studio Access to API Services"**.
4. Klik **Save**. Saldo Tunai, Saldo Bank, dan Inventori pemain akan otomatis tersimpan permanen menggunakan `DataStoreService`.

---
© 2026 MFNH Studio. All rights reserved.

