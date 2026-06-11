# Smart Attendance Laravel API

Backend Laravel untuk Smart Attendance. Project ini menyediakan REST API mobile,
Laravel Sanctum authentication, dan Filament admin panel.

## Requirements

- PHP 8.3 atau lebih baru.
- Composer.
- Database SQLite, MySQL, atau PostgreSQL.
- Node.js dan npm untuk asset Filament.

## Setup

```bash
cd web-api
composer install
cp .env.example .env
php artisan key:generate
npm install
npm run build
php artisan migrate
php artisan storage:link
```

Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Sesuaikan konfigurasi database pada `.env`.

Contoh MySQL:

```env
DB_DATABASE=smart_attendance
DB_USERNAME=root
DB_PASSWORD=
```

Pastikan `APP_URL` sesuai host yang dapat diakses mobile agar `photoUrl` dan
`selfieUrl` dapat dibuka dari device.

Contoh internal server:

```env
APP_URL=http://159.89.196.37:8765
```

## Membuat Admin

```bash
php artisan app:create-admin
```

Command akan meminta nama, email, password, konfirmasi password, dan jabatan.
Role otomatis diset `ADMIN`.

Jangan gunakan `php artisan make:filament-user` untuk admin aplikasi ini karena
command tersebut tidak mengisi kolom `role`.

## Menjalankan Server

Localhost:

```bash
php artisan serve
```

Agar dapat diakses device lain dalam jaringan/server:

```bash
php artisan serve --host=0.0.0.0 --port=8765
```

URL penting:

```txt
API base:    http://159.89.196.37:8765/api/v1
Admin panel: http://159.89.196.37:8765/admin
```

## Filament Admin Panel

Panel admin berada di `/admin` dan mencakup:

| Menu | Fungsi |
| --- | --- |
| Karyawan | CRUD data employee dan admin |
| Kantor | CRUD kantor, koordinat, radius, dan active office |
| Hari Libur | CRUD hari libur |
| Absensi | Validasi dan audit presensi |
| Log Absensi | Riwayat perubahan status presensi |

Catatan:

- Hanya satu kantor yang boleh aktif.
- Status attendance pada Filament dibuat read-only.
- Create/delete attendance melalui Filament dinonaktifkan agar audit trail aman.

## API Mobile

Base path:

```txt
/api/v1
```

Auth:

```txt
Authorization: Bearer <sanctum-token>
```

Endpoint public dan authenticated umum:

| Method | Path | Fungsi |
| --- | --- | --- |
| POST | `/auth/mobile/login` | Login mobile |
| POST | `/auth/register` | Register employee, avatar opsional |
| POST | `/auth/forgot-password` | Validasi keberadaan email |
| GET | `/auth/me` | Data user saat ini |
| POST | `/auth/logout` | Logout dan revoke token |
| PATCH | `/users/{id}` | Update profil |
| PATCH | `/users/{id}/password` | Ubah password |
| POST | `/files` | Upload file multipart |
| GET | `/files/{id}` | Metadata file |
| GET | `/offices/active` | Kantor aktif |
| GET | `/attendances/today` | Presensi hari ini |
| GET | `/attendances/history` | Riwayat presensi |
| GET | `/attendances/{id}` | Detail presensi |
| POST | `/attendances/clock-in` | Clock-in GPS + selfie |
| POST | `/attendances/clock-out` | Clock-out |

Endpoint admin:

| Method | Path | Fungsi |
| --- | --- | --- |
| GET | `/admin/dashboard/summary` | Summary dashboard admin |
| GET | `/admin/users` | List user |
| GET | `/admin/users/{id}` | Detail user |
| GET | `/admin/attendances` | History/list attendance admin |
| GET | `/admin/attendances/report` | Report attendance per tanggal |
| GET | `/admin/attendances/{id}` | Detail attendance admin |
| PATCH | `/admin/attendances/{id}/validation` | Approve/reject pending attendance |
| PATCH | `/admin/offices/{id}` | Update active office |

Untuk detail request/response, baca:

- `../docs/api/mobile-api-contract-phase-1.md`
- `../docs/api/mobile-api-contract-phase-2.md`

## Testing

Jalankan seluruh automated test:

```bash
php artisan test
```

Test per area:

```bash
php artisan test --filter=AdminFoundationTest
php artisan test --filter=AdminReadApiTest
php artisan test --filter=AdminActionsAndOfficeTest
php artisan test --filter=AuthEnhancementsTest
```

Route audit:

```bash
php artisan route:list --path=api/v1
php artisan route:list --path=api/v1/admin
```

REST smoke test:

```txt
../docs/api/rest/smoke-test.http
../docs/api/rest/phase-2-smoke-test.http
```

## Menambah Resource Filament

Gunakan generator Filament agar struktur konsisten:

```bash
php artisan make:filament-resource NamaModel --generate
```
