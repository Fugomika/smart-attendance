# Smart Attendance — Web API

Backend Laravel + Filament admin panel untuk sistem absensi berbasis mobile.

## Requirements

- PHP >= 8.3
- Composer
- SQLite (default) atau MySQL/PostgreSQL

## Setup

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan storage:link
```

Jalankan dev server:

```bash
php artisan serve
```

Admin panel tersedia di `http://localhost:8000/admin`.

## Membuat Admin

Gunakan command berikut untuk membuat akun admin yang bisa mengakses panel:

```bash
php artisan app:create-admin
```

Command akan meminta: nama, email, password (tersembunyi), konfirmasi password, dan jabatan (opsional). Role otomatis di-set `ADMIN`.

> **Catatan:** Jangan gunakan `php artisan make:filament-user` — command tersebut tidak mengisi kolom `role` yang wajib ada.

## Admin Panel

Panel admin (`/admin`) menggunakan Filament v5 dan mencakup:

| Menu | Fungsi |
|---|---|
| **Karyawan** | CRUD data karyawan dan admin |
| **Kantor** | CRUD data kantor (koordinat & radius) |
| **Hari Libur** | CRUD hari libur nasional & perusahaan |
| **Absensi** | Validasi absensi dari mobile (ubah status) |
| **Log Absensi** | Riwayat perubahan status (read-only) |

## API Mobile (Phase 1)

Base path: `/api/v1`. Auth menggunakan Sanctum Bearer Token (7 hari).

| # | Method | Path | Auth | Fungsi |
|---|--------|------|------|--------|
| 1 | `POST` | `/auth/mobile/login` | — | Login mobile, return token |
| 2 | `POST` | `/auth/register` | — | Register karyawan baru |
| 3 | `POST` | `/auth/forgot-password` | — | Request reset password (generic) |
| 4 | `GET` | `/auth/me` | ✓ | Data user saat ini |
| 5 | `PATCH` | `/users/:id` | ✓ | Update profil (nama, jabatan, foto) |
| 6 | `PATCH` | `/users/:id/password` | ✓ | Ubah password |
| 7 | `POST` | `/auth/logout` | ✓ | Invalidate token |
| 8 | `POST` | `/files` | ✓ | Upload foto (multipart/form-data) |
| 9 | `GET` | `/files/:id` | ✓ | Metadata file & URL |
| 10 | `GET` | `/offices/active` | ✓ | Data kantor aktif |
| 11 | `GET` | `/attendances/today` | ✓ | Absensi hari ini |
| 12 | `GET` | `/attendances/history` | ✓ | Riwayat absensi (paginated, filter bulan) |
| 13 | `GET` | `/attendances/:id` | ✓ | Detail absensi |
| 14 | `POST` | `/attendances/clock-in` | ✓ | Clock in (GPS + selfie) |
| 15 | `POST` | `/attendances/clock-out` | ✓ | Clock out |

## Menambah Resource Filament

Selalu gunakan command generator untuk menjaga konsistensi:

```bash
php artisan make:filament-resource NamaModel --generate
```
