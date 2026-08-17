<?php

$isProduction = filter_var(
    env('MIDTRANS_IS_PRODUCTION', false),
    FILTER_VALIDATE_BOOL
);

return [
    'merchant_id' => env('MIDTRANS_MERCHANT_ID'),
    'client_key' => env('MIDTRANS_CLIENT_KEY'),
    'server_key' => env('MIDTRANS_SERVER_KEY'),
    'is_production' => $isProduction,
    'snap_url' => $isProduction
        ? 'https://app.midtrans.com/snap/snap.js'
        : 'https://app.sandbox.midtrans.com/snap/snap.js',
    'is_sanitized' => true,
    'is_3ds' => true,
];
