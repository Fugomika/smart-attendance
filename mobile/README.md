# Smart Attendance Mobile

Smart Attendance Mobile adalah aplikasi Flutter untuk presensi employee dan
operasional admin. Aplikasi ini terhubung ke Laravel API melalui Sanctum Bearer
Token dan memakai pola `Screen -> Provider -> Repository -> ApiClient`.

## Fitur

Employee:

- Login, register dengan avatar opsional, forgot-password, profile, dan logout.
- Clock-in/clock-out dengan validasi lokasi dan selfie.
- Riwayat dan detail presensi.
- Outside reason, remote selfie, reject note, dan Google Maps direction.

Admin:

- Dashboard summary.
- List/detail karyawan.
- History presensi per karyawan.
- Laporan presensi per tanggal.
- Detail presensi dengan selfie, lokasi, outside reason, dan reject note.
- Approve/reject presensi pending.
- Update active office.
- Pull-to-refresh dan infinite scroll pada flow admin utama.

## Tech Stack

- Flutter dan Dart.
- Riverpod untuk state management.
- GoRouter untuk routing.
- Dio untuk HTTP client.
- Flutter Secure Storage untuk token.
- flutter_dotenv untuk environment.
- Camera, image_picker, geolocator, flutter_map, dan url_launcher.

## Quick Start

```bash
cd mobile
cp .env.example .env
flutter pub get
flutter run
```

Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Sesuaikan `mobile/.env` sebelum menjalankan aplikasi:

```env
API_BASE_URL=http://159.89.196.37:8765/api/v1
SHOW_DEBUG_PREVIEW=false
```

Catatan:

- `API_BASE_URL` wajib berakhir dengan `/api/v1`.
- Lakukan full restart setelah mengubah `.env`.
- `.env` dibundel sebagai asset aplikasi, jadi jangan menyimpan password, token,
  atau secret di file ini.
- `SHOW_DEBUG_PREVIEW=true` hanya berpengaruh pada debug build karena UI preview
  tetap dilindungi `kDebugMode`.

## Struktur Folder

```txt
lib/
  app/        routing, theme, dan setup aplikasi
  core/       config, enum, network, storage, dan utility umum
  data/       models, repositories, dan provider dependency
  features/   auth, employee, admin, profile, dan shared feature
  shared/     widget reusable lintas fitur
```

## Command Development

Install dependency:

```bash
flutter pub get
```

Run debug:

```bash
flutter run
```

Quality check:

```bash
flutter analyze
flutter test
```

Format file Dart yang disentuh:

```bash
dart format <path-file-dart>
```

## Build APK Release

Pastikan `mobile/.env` sudah mengarah ke API target release/internal:

```env
API_BASE_URL=http://159.89.196.37:8765/api/v1
SHOW_DEBUG_PREVIEW=false
```

API di atas masih memakai HTTP dan sudah diizinkan secara scoped pada Android
network security config untuk kebutuhan release internal. Untuk release publik,
gunakan HTTPS.

Pastikan file signing lokal sudah tersedia dan tidak di-commit:

```txt
android/key.properties
android/app/smart-attendance-release.jks
```

Isi `android/key.properties`:

```properties
storePassword=PASSWORD_KEYSTORE
keyPassword=PASSWORD_KEY
keyAlias=smart-attendance
storeFile=app/smart-attendance-release.jks
```

Build APK:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Output APK:

```txt
build/app/outputs/flutter-apk/app-release.apk
```

Untuk Play Store, gunakan AAB:

```bash
flutter build appbundle --release
```

## Catatan Release

- `android/key.properties` dan file `.jks` sudah di-ignore oleh Git.
- Simpan backup keystore dan password dengan aman.
- Application ID saat ini masih `com.kel6_abp.smartattendnace`.
