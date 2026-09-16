# GeoDesaConnect - Google Play Release

Branch ini menggunakan package final `com.geodesaconnect.app`, target API 36,
API produksi `https://geodesaconnect.id/api`, dan upload signing terpisah dari
debug signing.

## 1. Konfigurasi Laravel Produksi

Pastikan `.env` server memuat nilai berikut, lalu jalankan `php artisan config:cache`:

```dotenv
APP_ENV=production
APP_DEBUG=false
APP_URL=https://geodesaconnect.id

ANDROID_PACKAGE_NAME=com.geodesaconnect.app
ANDROID_SHA256_FINGERPRINTS=SHA256_DARI_APP_SIGNING_PLAY_CONSOLE

PRIVACY_ENTITY_NAME=GeoDesaConnect
PRIVACY_CONTACT_EMAIL=support@geodesaconnect.id
```

Periksa URL berikut setelah deployment:

- `https://geodesaconnect.id/up`
- `https://geodesaconnect.id/api/products`
- `https://geodesaconnect.id/privacy-policy`
- `https://geodesaconnect.id/account-deletion`
- `https://geodesaconnect.id/.well-known/assetlinks.json`

## 2. Buat Upload Keystore

Jalankan satu kali dan simpan keystore serta password di tempat aman:

```bash
keytool -genkeypair -v \
  -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Salin `android/key.properties.example` menjadi `android/key.properties`, lalu
isi password sebenarnya. Kedua file rahasia tersebut sudah diabaikan Git.

## 3. Build dan Pemeriksaan

Gunakan Flutter stabil terbaru dan JDK 17:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Bundle hasil build berada di:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 4. App Links

Setelah aplikasi dibuat di Play Console, buka **App integrity**, salin SHA-256
sertifikat **App signing key**, lalu masukkan ke
`ANDROID_SHA256_FINGERPRINTS`. Nilai ini berbeda dari SHA-256 upload key.

## 5. Isian Play Console

- Upload `fe_flutter/store_assets/play-store-icon-512.png` sebagai ikon toko.
- Siapkan feature graphic 1024 x 500 dan screenshot ponsel yang sesuai aplikasi.
- Privacy policy: `https://geodesaconnect.id/privacy-policy`.
- Account deletion URL: `https://geodesaconnect.id/account-deletion`.
- Deklarasikan nama, email, telepon, alamat, lokasi, foto, pesan, pesanan,
  pembayaran, dan bukti transfer pada Data safety sesuai penggunaan sebenarnya.
- Berikan akun demo pembeli dan penjual pada bagian App access.
- Uji pembayaran manual, lokasi, upload gambar, chat, checkout, deep link, dan
  penghapusan akun melalui Internal testing sebelum mengajukan Production.
