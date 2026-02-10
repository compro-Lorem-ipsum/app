# 📱 BIMA App – Sistem Absensi & Patroli

BIMA App adalah aplikasi mobile berbasis **Flutter** untuk mendukung sistem **absensi wajah** dan **pelaporan patroli** petugas keamanan.  
Aplikasi ini menggunakan kamera, GPS, dan validasi backend untuk memastikan keakuratan data.

---

## 🔹 Persyaratan Perangkat

Pastikan perangkat Android memenuhi spesifikasi berikut:

- ✅ **Android minimal 6.0 (Marshmallow / API 23)**
- ✅ Arsitektur CPU:
  - **arm64-v8a (64-bit)** – mayoritas perangkat Android saat ini
  - **armeabi-v7a (32-bit)** – perangkat Android lama
- ✅ Kamera aktif
- ✅ GPS / Location aktif
- ✅ Ruang penyimpanan kosong ± **50 MB** (aplikasi 20 MB)
- ✅ Izin aplikasi:
  - Kamera
  - Lokasi
  - Penyimpanan

---

## 📦 File APK
Aplikasi tersedia dalam dua varian APK:

### 1️⃣ APK Normal (Direkomendasikan)
bima_app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

**Keterangan:**
- Untuk perangkat Android **64-bit (arm64-v8a)**
- Performa lebih stabil
- Direkomendasikan untuk penggunaan harian

### 2️⃣ APK Ringan
bima_app/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk

**Keterangan:**
- Untuk perangkat Android **32-bit (armeabi-v7a)**
- Ukuran lebih kecil
- Cocok untuk perangkat lama

---

## 📲 Cara Install Aplikasi (Seperti APK Biasa)

### 1. Salin APK ke Perangkat
Salin file APK ke perangkat Android melalui:
- Kabel USB
- WhatsApp
- Google Drive
- Bluetooth

---

### 2. Aktifkan Izin Install Aplikasi Tidak Dikenal
Masuk ke:
Pengaturan → Keamanan → Install aplikasi tidak dikenal

Aktifkan izin untuk aplikasi yang digunakan membuka APK  
(contoh: File Manager, Chrome, atau WhatsApp).

---

### 3. Install APK
1. Buka file APK
2. Tekan **Install**
3. Tunggu hingga proses selesai
4. Tekan **Open**

---

## ⚠️ Troubleshooting Instalasi

| Masalah | Penyebab | Solusi |
|------|--------|-------|
| INSTALL_FAILED_NO_MATCHING_ABIS | Arsitektur APK tidak cocok | Gunakan APK **arm64-v8a** |
| Aplikasi tidak bisa dipasang | Android < 6.0 | Perangkat tidak didukung |
| Gagal install | Storage penuh | Kosongkan ruang penyimpanan |
| APK diblokir | Izin belum aktif | Aktifkan “Install unknown apps” |

---

## 📌 Catatan Tambahan

- Ukuran aplikasi ± **15–20 MB**

---

