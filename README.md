# flutter-driverapp-s2smfg

Aplikasi Android (Flutter) untuk **Driver S2SMFG** — digunakan oleh supir/driver untuk mengelola pengiriman, scan truk, dan tracking pengiriman secara real-time.

---

## Deskripsi

Aplikasi mobile native Flutter yang berkomunikasi langsung dengan backend API S2SMFG. Driver dapat login, melihat daftar delivery plan, melakukan scan QR truk, mencatat kedatangan, dan melaporkan insiden perjalanan.

### Arsitektur

```
Flutter App (Android)
    ↓  REST API (HTTPS)
Backend Laravel S2SMFG (s2smfg.biz.id)
    ↓
Database MySQL
```

---

## Fitur

- ✅ **Login** — autentikasi dengan username/password atau QR badge scan
- ✅ **Delivery Plan** — melihat daftar rencana pengiriman hari ini
- ✅ **Scan Truk** — scan QR code truk untuk memulai perjalanan
- ✅ **Active Delivery** — tracking pengiriman yang sedang berjalan
- ✅ **Arrival** — konfirmasi kedatangan di titik tujuan
- ✅ **Incident Report** — melaporkan insiden selama perjalanan
- ✅ **Secure Storage** — token login tersimpan aman di device

---

## Prasyarat

- Flutter SDK ≥ 3.11.0 / Dart SDK ^3.11.0
- Android device (minSdk 21)
- Koneksi internet ke server S2SMFG
- Akun driver yang sudah terdaftar di sistem S2SMFG

---

## Dependensi Utama

| Package | Versi | Kegunaan |
|---------|-------|----------|
| `get` | ^4.6.6 | State management + navigation (GetX) |
| `dio` | ^5.7.0 | HTTP client untuk API calls |
| `flutter_secure_storage` | ^9.2.2 | Penyimpanan token login yang aman |
| `mobile_scanner` | ^5.2.3 | QR Code scanner (truk & badge login) |
| `image_picker` | ^1.1.2 | Kamera untuk foto bukti pengiriman |
| `intl` | ^0.19.0 | Format tanggal & waktu |

---

## Struktur Folder

```
lib/
├── main.dart                     # Entry point app
└── app/
    ├── constants/
    │   └── api_constants.dart    # Base URL API & endpoint names
    ├── controllers/              # GetX controllers
    │   ├── auth_controller.dart
    │   ├── delivery_controller.dart
    │   └── shipping_controller.dart
    ├── models/                   # Data models
    │   ├── user_model.dart
    │   ├── delivery_model.dart
    │   └── shipping_model.dart
    ├── routes/
    │   └── app_routes.dart       # Definisi routing halaman
    ├── services/
    │   ├── api_service.dart      # HTTP client (Dio wrapper)
    │   └── auth_service.dart     # Login & token management
    └── views/                    # Halaman UI
        ├── auth/
        ├── delivery/
        └── widgets/
```

---

## Cara Build (Android)

```bash
# 1. Install dependencies
flutter pub get

# 2. Build APK (debug)
flutter build apk --debug

# 3. Build APK (release)
flutter build apk --release

# APK output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Konfigurasi API

Base URL dan endpoint API dikonfigurasi di [`lib/app/constants/api_constants.dart`](lib/app/constants/api_constants.dart).

---

## Hubungan dengan Repo Lain

- **Backend/Web**: [ardyansyahp/s2smfg](https://github.com/ardyansyahp/s2smfg) — Laravel application (server-side & API)
- **WebView App**: [ardyansyahp/flutter-webview-s2smfg](https://github.com/ardyansyahp/flutter-webview-s2smfg) — Aplikasi manufacturing tablet terpisah
