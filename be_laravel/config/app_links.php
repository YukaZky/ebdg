<?php

return [
    /*
    |--------------------------------------------------------------------------
    | GeoDesaConnect App Link Download Targets
    |--------------------------------------------------------------------------
    |
    | URL ini hanya dipakai ketika aplikasi tidak berhasil dibuka dari link
    | yang dibagikan. Ubah nilainya melalui .env di server/cPanel agar tidak
    | perlu rebuild aplikasi Flutter hanya untuk mengganti link download.
    |
    */

    'android_download_url' => env(
        'APP_ANDROID_DOWNLOAD_URL',
        'https://geodesaconnect.id'
    ),

    'ios_download_url' => env(
        'APP_IOS_DOWNLOAD_URL',
        'https://geodesaconnect.id'
    ),

    'fallback_download_url' => env(
        'APP_FALLBACK_DOWNLOAD_URL',
        'https://geodesaconnect.id'
    ),

    /*
    |--------------------------------------------------------------------------
    | APK Download dari public/
    |--------------------------------------------------------------------------
    |
    | Path bersifat relatif terhadap folder public Laravel. Contoh jika file
    | berada di public/GeoDesaConnect.apk maka isi APP_APK_PUBLIC_PATH dengan
    | GeoDesaConnect.apk. Jika berada di public/downloads/app.apk, isi dengan
    | downloads/app.apk.
    |
    */

    'apk_public_path' => env('APP_APK_PUBLIC_PATH', 'GeoDesaConnect.apk'),
    'apk_download_name' => env('APP_APK_DOWNLOAD_NAME', 'GeoDesaConnect.apk'),
];
