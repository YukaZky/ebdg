<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

$openAppOrRedirect = static function (Request $request, string $type, string $slug) {
    $allowedTypes = ['product', 'store'];
    abort_unless(in_array($type, $allowedTypes, true), 404);

    $fallback = trim((string) $request->query('fallback', 'https://geodesaconnect.id'));
    $fallbackParts = parse_url($fallback);
    $fallbackScheme = strtolower((string) ($fallbackParts['scheme'] ?? ''));
    $fallbackHost = strtolower((string) ($fallbackParts['host'] ?? ''));

    // Batasi tujuan redirect agar route ini tidak menjadi open-redirect bebas.
    $allowedFallbackHosts = [
        'geodesaconnect.id',
        'www.geodesaconnect.id',
        'play.google.com',
        'apps.apple.com',
    ];

    if ($fallbackScheme !== 'https' || ! in_array($fallbackHost, $allowedFallbackHosts, true)) {
        $fallback = 'https://geodesaconnect.id';
    }

    $safeSlug = rawurlencode($slug);
    $appUrl = "geodesaconnect://{$type}/{$safeSlug}";
    $appUrlJson = json_encode($appUrl, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_AMP | JSON_HEX_QUOT);
    $fallbackJson = json_encode($fallback, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_AMP | JSON_HEX_QUOT);

    $html = <<<HTML
<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="robots" content="noindex,nofollow">
    <title>Membuka GeoDesaConnect</title>
    <style>
        html,body{margin:0;background:#fff;color:#0c2442;font-family:Arial,sans-serif}
        .wrap{min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;text-align:center}
        .spinner{width:28px;height:28px;border:3px solid #dbeafe;border-top-color:#0c4da2;border-radius:50%;animation:spin .8s linear infinite;margin:0 auto 14px}
        p{margin:0;font-size:13px;color:#64748b}
        @keyframes spin{to{transform:rotate(360deg)}}
    </style>
</head>
<body>
<div class="wrap"><div><div class="spinner"></div><p>Membuka aplikasi GeoDesaConnect...</p></div></div>
<script>
(function () {
    const appUrl = {$appUrlJson};
    const fallback = {$fallbackJson};
    let appOpened = false;

    const markOpened = function () { appOpened = true; };
    document.addEventListener('visibilitychange', function () {
        if (document.hidden) markOpened();
    });
    window.addEventListener('pagehide', markOpened);
    window.addEventListener('blur', markOpened);

    window.location.href = appUrl;

    window.setTimeout(function () {
        if (!appOpened) window.location.replace(fallback);
    }, 1200);
})();
</script>
</body>
</html>
HTML;

    return response($html, 200, [
        'Content-Type' => 'text/html; charset=UTF-8',
        'Cache-Control' => 'no-store, no-cache, must-revalidate, max-age=0',
        'Pragma' => 'no-cache',
    ]);
};

Route::get('/open/product/{slug}', fn (Request $request, string $slug) => $openAppOrRedirect($request, 'product', $slug))
    ->where('slug', '[A-Za-z0-9._~-]+');

Route::get('/open/store/{slug}', fn (Request $request, string $slug) => $openAppOrRedirect($request, 'store', $slug))
    ->where('slug', '[A-Za-z0-9._~-]+');
