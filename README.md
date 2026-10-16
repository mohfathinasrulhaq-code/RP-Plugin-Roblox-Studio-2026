# RP-Plugin-Roblox-Studio-2026
RP-Plugin adalah Roblox Studio Developer Suite &amp; Framework untuk map Roleplay dengan sistem Live Economy seimbang—menghadirkan perdagangan P2P aman, sistem Faucet &amp; Sink anti-hiperinflasi, serta spawner node map interaktif sekali klik.

# 🌴 RP-Plugin: Live Economy Developer Suite & Framework

Framework dan Roblox Studio Plugin dasar khusus untuk pengembangan Game / Map Roleplay dengan konsep **Live Economy** (perdagangan P2P antar pemain, penghasilan, dan pengeluaran seimbang anti-inflasi).

## 🚀 Fitur Unggulan
- **Roblox Studio Plugin (`plugin/LiveEconomy_StudioPlugin.server.luau`)**:
  - UI DockWidget bergaya Dark Mode dengan perlindungan hak cipta resmi.
  - 1-Click Framework Installer langsung ke dalam DataModel Studio.
  - Quick Spawner Properti Interaktif (ATM Bank, Warung Kelontong, Pos Kurir, Dermaga TPI, Lapak Pasar).
  - Live Economy Balancer & Audit Inflasi.
- **Sistem Keuangan Komprehensif**:
  - Format Mata Uang Rupiah (`Rp 1.000.000`).
  - Dompet Tunai (Cash) & Rekening Bank (ATM).
  - P2P Trade Atomik 2 Arah (Lock Offer -> Countdown -> Safe Swap).
  - Pajak Perdagangan P2P (Trade Tax) sebagai mekanisme pembakar uang (Sink) server.
  - Sistem Pekerjaan (Kurir, Nelayan, Pedagang, Polisi, Medis) dengan Payday berkala.
  - Sistem Warung Kelontong & Pengepul Hasil Laut (TPI).

## 📖 Dokumentasi Lengkap
Silakan baca panduan lengkap cara pasang dan kustomisasi di:
- 👉 [Panduan Penggunaan Lengkap](./docs/PANDUAN_PENGGUNAAN.md)
- 👉 [Installer Command Bar Instan](./tools/InstallCommandBar.luau)
- 👉 [Konfigurasi Nilai Ekonomi](./framework/ReplicatedStorage/EconomySystem/Config/EconomyConfig.luau)

---
© 2026 MFNH Studio. All rights reserved.

📋 Deskripsi Ringkas (3 Poin Utama)
1.Live Economy & Anti-Hiperinflasi (Faucet vs Sink): Mengatur perputaran mata uang secara realistis di dalam server; pemain memperoleh uang (Faucet)   melalui pekerjaan & jual komoditas, dan menghabiskan uang (Sink) melalui belanja kebutuhan pokok (makan/minum), biaya admin perbankan, dan pajak.

2.Perdagangan Aman Antar Pemain (P2P Trade Atomik): Sistem transaksi langsung antar pemain dengan proteksi anti-scam (kunci tawaran dua arah + hitung mundur konfirmasi) dan pemotongan pajak pasar otomatis untuk menjaga kestabilan nilai mata uang.

3.One-Click Studio Map Builder: Dilengkapi panel DockWidget di Roblox Studio untuk memasang seluruh sistem secara otomatis serta memunculkan model siap pakai (Mesin ATM, Warung Kelontong, Pos Kurir, Dermaga Nelayan TPI, dan Lapak Pasar) yang sudah terkonfigurasi dengan ProximityPrompt.

Created by MFNH Studio@2026.
