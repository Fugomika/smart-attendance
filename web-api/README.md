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

## Menambah Resource Filament

Selalu gunakan command generator untuk menjaga konsistensi:

```bash
php artisan make:filament-resource NamaModel --generate
```
