# Smart Attendance Mobile

Smart Attendance adalah aplikasi presensi internal kantor berbasis Flutter. Aplikasi ini memiliki dua mode, yaitu mode karyawan dan mode admin.

Pada tahap ini aplikasi sedang di-wire bertahap ke Laravel API Phase 1. Auth dan profile sudah memakai API; fitur admin, office, dan attendance tertentu masih memakai dummy/in-memory sesuai batch integrasi.

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

## Akun Dev API

Karyawan:

```txt
Email    : user@gmail.com
Password : password
```

Admin:

```txt
Email    : admin@gmail.com
Password : Admin123
```

## Struktur Folder

```txt
lib/
  app/        konfigurasi aplikasi, routing, dan theme
  core/       enum dan helper umum
  data/       model, dummy data, repository, dan API repository
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
- `data` digunakan untuk menyimpan model, dummy data, repository, dan API repository.
- `features` digunakan untuk memisahkan bagian aplikasi berdasarkan fitur.
- `shared` digunakan untuk komponen UI yang dipakai berulang.

Alur data:

```txt
Screen -> Provider -> Repository -> API Client / Dummy Store
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

- Base URL dev HP saat ini: `http://192.168.1.6:8000/api/v1`.
- Admin feature data masih dummy untuk Phase 1.
- Office dan attendance API masih dikerjakan bertahap 
