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
];
