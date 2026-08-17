<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class PrepareMidtransCheckout
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Middleware ini hanya menyentuh HTML halaman checkout web.
        if (! $request->routeIs('cart.checkout')) {
            return $response;
        }

        $contentType = (string) $response->headers->get('Content-Type');
        if (! str_contains(strtolower($contentType), 'text/html')) {
            return $response;
        }

        $html = $response->getContent();
        if (! is_string($html) || $html === '') {
            return $response;
        }

        // checkout.blade.php lama menggunakan URL Sandbox secara hardcode.
        // Ganti pada response sesuai MIDTRANS_IS_PRODUCTION agar satu build
        // bisa dipakai untuk Sandbox maupun Production.
        $html = str_replace(
            'https://app.sandbox.midtrans.com/snap/snap.js',
            (string) config('midtrans.snap_url'),
            $html
        );

        // Status pending dari Snap bukan kegagalan. Pending berarti instruksi
        // pembayaran (VA/QR/dll.) sudah dibuat dan order harus dipertahankan.
        $legacyPendingHandler = <<<'JS'
              onPending: function(result) {
                alert("Pembayaran Gagal!");
                cancelOrder(pendingOrderId);
                payButton.prop('disabled', false).text('Buat Pesanan');
              },
JS;

        $safePendingHandler = <<<'JS'
              onPending: function(result) {
                pendingOrderId = null;
                sendPaymentResult(result);
              },
JS;

        $html = str_replace(
            $legacyPendingHandler,
            $safePendingHandler,
            $html
        );

        $response->setContent($html);

        return $response;
    }
}
