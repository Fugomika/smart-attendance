# Smart Attendance

Smart Attendance adalah sistem presensi berbasis mobile dengan validasi lokasi,
selfie attendance, dashboard admin, dan API backend Laravel. Repository ini
berisi aplikasi Flutter mobile serta Laravel Web API dengan Filament admin
panel.

## Fitur Utama

- Login, register, forgot-password, profile, dan session mobile.
- Presensi employee dengan GPS, selfie, clock-in, dan clock-out.
- Riwayat dan detail presensi employee.
- Admin dashboard summary.
- Admin list/detail karyawan.
- Admin laporan presensi per tanggal.
- Admin detail presensi dengan selfie, lokasi, outside reason, dan reject note.
- Admin approve/reject presensi pending.
- Admin update active office.
- Filament web admin untuk data operasional backend.

## Struktur Repository

```txt
smart-attendance/
  mobile/   Flutter mobile app
  web-api/  Laravel API dan Filament admin panel
  docs/     API contract, smoke test, dan dokumentasi teknis
```

## Quick Start

Untuk menjalankan aplikasi mobile:

```bash
cd mobile
cp .env.example .env
flutter pub get
flutter run
```

Untuk menjalankan backend lokal:

```bash
cd web-api
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan storage:link
php artisan serve --host=0.0.0.0 --port=8765
```

Jika memakai Windows PowerShell, gunakan `Copy-Item .env.example .env` untuk
menyalin file environment.

Detail setup ada di:

- [Flutter Mobile README](mobile/README.md)
- [Laravel API README](web-api/README.md)

## API Target

Mobile membaca base URL dari `mobile/.env`.

Contoh API internal:

```env
API_BASE_URL=http://159.89.196.37:8765/api/v1
SHOW_DEBUG_PREVIEW=false
```

Untuk release publik, gunakan API HTTPS.

## Dokumentasi

- `docs/api/mobile-api-contract-phase-1.md`
- `docs/api/mobile-api-contract-phase-2.md`

## Tim

Kelompok 6 - Telkom University.

| Nama | NIM |
| --- | --- |
| Egi Meisandi Moh Rizki | 103042310051 |
| Ammar Annajih Fasifiki | 103042310020 |
| Abdurrahman Farras. F | 103042310070 |
| Qonita | 103042310027 |
| Ella Aurelia | 103042310063 |
| Vica Febrianti Jatnika | 103042310044 |
