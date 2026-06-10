# Smart Attendance Mobile

Smart Attendance adalah aplikasi presensi internal kantor berbasis Flutter. Aplikasi ini memiliki dua mode, yaitu mode karyawan dan mode admin.

Auth, profile, employee attendance, dan core admin mobile sudah di-wire ke
Laravel API Phase 1 dan Phase 2.

## Status Fitur

- Login API untuk karyawan dan admin
- Register, forgot password, profile, upload foto profile, dan ubah password via API
- Tampilan dasar mode karyawan: Home, Riwayat, Profil
- Tampilan dasar mode admin: Dashboard, Karyawan, Laporan, Profil
- Routing dasar antar halaman
- Tema warna sesuai style guide
- Komponen UI reusable dasar

## Tech Stack

- Flutter
- Dart
- Riverpod untuk state management
- GoRouter untuk routing
- Google Fonts untuk font Poppins
- Intl untuk format tanggal dan waktu

## Testing Stack

- Flutter Test untuk widget test
- Flutter Analyze untuk pengecekan kualitas kode

## Environment

Copy `.env.example` menjadi `.env` di folder `mobile/`, lalu sesuaikan:

```env
API_BASE_URL=http://192.168.1.5:8000/api/v1
SHOW_DEBUG_PREVIEW=false
```

- `.env` digunakan otomatis saat aplikasi dimulai sehingga development cukup
  memakai `flutter run`.
- `.env` tidak boleh berisi password, token, atau secret karena file tersebut
  dibundel sebagai asset aplikasi.
- `API_BASE_URL` wajib berupa URL HTTP/HTTPS valid. Aplikasi berhenti dengan
  error konfigurasi jika nilainya kosong atau tidak valid.
- `SHOW_DEBUG_PREVIEW` hanya berpengaruh pada debug build karena UI preview
  tetap dilindungi `kDebugMode`.
- Sebelum production build, isi `.env` dengan URL production dan set
  `SHOW_DEBUG_PREVIEW=false`.

## Struktur Folder

```txt
lib/
  app/        konfigurasi aplikasi, routing, dan theme
  core/       enum dan helper umum
  data/       model, data lokal terbatas, repository, dan API repository
  features/   fitur aplikasi seperti auth, employee, dan admin
  shared/     widget reusable yang dipakai di banyak halaman
```

Folder asset:

```txt
assets/
  images/         gambar umum seperti logo
  icons/          icon custom jika dibutuhkan
  illustrations/  ilustrasi halaman
```

## Architecture

Project ini menggunakan struktur sederhana berbasis fitur.

- `app` digunakan untuk pengaturan utama aplikasi seperti theme dan routing.
- `core` digunakan untuk kebutuhan umum yang bisa dipakai di banyak fitur.
- `data` digunakan untuk menyimpan model, data lokal terbatas, repository, dan API repository.
- `features` digunakan untuk memisahkan bagian aplikasi berdasarkan fitur.
- `shared` digunakan untuk komponen UI yang dipakai berulang.

Alur data:

```txt
Screen -> Provider -> Repository -> API Client
```

Navigasi utama menggunakan shell navigation agar bottom navigation tetap stabil saat berpindah menu.

## Menjalankan Project

```bash
flutter pub get
flutter run
```

Untuk pengecekan kode:

```bash
flutter analyze
flutter test
```

## Catatan

- Base URL dibaca dari `.env`.
- Dummy holidays masih dipertahankan karena berada di luar scope API Phase 2.
