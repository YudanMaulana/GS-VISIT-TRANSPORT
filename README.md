# GS VISIT TRANSPORT (Admin & Logistik Transporter)

Aplikasi Desktop (Windows & Linux) berbasis Flutter untuk pengelolaan armada transporter, pencatatan surat jalan/DO muatan, konfirmasi masuk dan keluar gerbang dengan tanda tangan digital satpam, serta monitoring audit trail bongkar muat pada ekosistem **GarudaShield Visit**.

---

## 📌 Fitur Utama

1. **Dashboard Kendali Transporter**:
   - Ringkasan statistik armada aktif di dalam area pabrik.
   - Status sesi login petugas pemeriksa satpam.
   - Pintasan cepat konfirmasi masuk dan konfirmasi keluar.
2. **Papan Monitoring Armada di Area (Real-time)**:
   - Daftar seluruh kendaraan pengangkut yang sedang berada di area pabrik.
   - Pencarian cepat berdasarkan nomor polisi kendaraan, nama sopir, atau perusahaan ekspedisi.
   - Tombol langsung untuk memproses kepulangan armada.
3. **Konfirmasi Masuk Gerbang (Check-in Transporter)**:
   - Input identitas armada: Nomor Polisi (Plat), Nama Pengemudi/Sopir, Perusahaan Ekspedisi/Transporter.
   - Kategori muatan: Bahan Baku, Bahan Kemas, Produk Jadi (*Finished Goods*), Sparepart/Mesin, atau Lainnya.
   - Nomor surat jalan / Delivery Order (DO) dan rincian muatan (tonase/koli).
   - Pengesahan digital menggunakan kanvas tanda tangan digital satpam pos gerbang (*digital signature*).
4. **Konfirmasi Keluar Gerbang (Check-out Transporter)**:
   - Pemilihan armada dari daftar kendaraan yang ada di area.
   - Checklist verifikasi fisik: kelengkapan stempel surat jalan/DO, pemeriksaan fisik muatan bak/kontainer, dan nomor segel pengaman.
   - Pengesahan tanda tangan digital satpam gerbang keluar.
5. **Riwayat Bongkar Muat & Audit Log**:
   - Catatan histori kedatangan, jam keluar, nomor polisi, dan identitas petugas penerima muatan.
6. **Pusat Bantuan & Laporan Kendala**:
   - Kirimkan tiket kendala operasional pos gerbang langsung ke IT administrator.

---

## 🔐 Autentikasi & Hak Akses

- Menggunakan **Google Sign-In Desktop (OAuth 2.0 Loopback + PKCE Flow)**.
- Akun Google petugas satpam/logistik didaftarkan oleh administrator server via CLI (`python cli_admin_register.py --role transport`).
- Sekali terdaftar dan login, sesi berlaku terus-menerus (*persistent session*) sampai administrator server menonaktifkannya via CLI atau pengguna melakukan logout.
- Terikat dengan peran **`admin_transport`**.

---

## 💻 Cara Menjalankan & Build

### Persyaratan:
- Flutter SDK (v3.13 / channel beta atau stable terbaru)
- Dukungan Desktop aktif (`flutter config --enable-windows-desktop` atau `--enable-linux-desktop`)

### Menjalankan untuk Pengembangan (Linux / Windows):
```bash
# Ambil dependencies
flutter pub get

# Jalankan di Linux (lingkungan dev)
flutter run -d linux

# Jalankan di Windows
flutter run -d windows
```

### Build Aplikasi Rilis (Windows Executable):
```bash
flutter build windows --release
```
Hasil executable berada di: `build/windows/x64/runner/Release/`

---

## 📂 Struktur Proyek

```text
lib/
├── main.dart                          # Entry point aplikasi, auth guard, & sidebar layout
└── src/
    ├── admin_auth.dart                # Manajemen sesi admin & persistensi
    ├── api_client.dart                # REST Client komunikasi server
    ├── config.dart                    # Pengaturan server & OAuth
    ├── google_desktop_auth.dart       # OAuth loopback flow Google
    ├── models.dart                    # Data models (ActiveGuestRow, Branch, etc.)
    ├── pages/
    │   ├── transporter_dashboard_page.dart
    │   ├── transporter_area_page.dart
    │   ├── transporter_checkin_page.dart
    │   ├── transporter_checkout_page.dart
    │   ├── transporter_loads_page.dart
    │   └── transporter_support_page.dart
    └── widgets/
        ├── admin_login_dialog.dart    # Dialog login Google admin transporter
        ├── signature_pad.dart         # Kanvas tanda tangan digital satpam
        ├── console_ui.dart
        └── status_banner.dart
```

---

© 2026 PT Garudafood Putra Putri Jaya Tbk - GarudaShield Visit.
