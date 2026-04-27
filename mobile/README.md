# Smart Attendance Mobile

Smart Attendance adalah aplikasi presensi internal kantor berbasis Flutter. Aplikasi ini memiliki dua mode, yaitu mode karyawan dan mode admin.

Pada tahap ini aplikasi masih menggunakan data dummy dan belum terhubung ke backend/API.

## Fitur Sementara

- Login dummy untuk karyawan dan admin
- Tampilan dasar untuk mode karyawan
- Tampilan dasar untuk mode admin
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

## Akun Dummy

Karyawan:

```txt
Email    : user@gmail.com
Password : password
```

Admin:

```txt
Email    : admin@gmail.com
Password : password
```

## Struktur Folder

```txt
lib/
  app/        konfigurasi aplikasi, routing, dan theme
  core/       enum dan helper umum
  data/       model, dummy data, dan repository dummy
  features/   fitur aplikasi seperti auth, employee, dan admin
  shared/     widget reusable yang dipakai di banyak halaman
```

## Architecture

Project ini menggunakan struktur sederhana berbasis fitur.

- `app` digunakan untuk pengaturan utama aplikasi seperti theme dan routing.
- `core` digunakan untuk kebutuhan umum yang bisa dipakai di banyak fitur.
- `data` digunakan untuk menyimpan model, dummy data, dan repository.
- `features` digunakan untuk memisahkan bagian aplikasi berdasarkan fitur.
- `shared` digunakan untuk komponen UI yang dipakai berulang.

Alur data sementara:

```txt
Dummy Data -> Repository -> Provider -> Screen
```

Nantinya saat backend sudah tersedia, bagian dummy data dapat diganti dengan API tanpa mengubah terlalu banyak struktur halaman.

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

- Backend/API belum digunakan.
- Camera, GPS, dan map asli belum diimplementasikan.
- Tampilan fitur masih berupa placeholder.
- Implementasi UI final akan dikerjakan bertahap pada tahap berikutnya.
