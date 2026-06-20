<?php

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\Request;
use Midtrans\Config as MidtransConfig;
use Midtrans\Notification as MidtransNotification;

class MidtransController extends Controller
{
    public function notificationHandler(Request $request)
    {
        // Set konfigurasi Midtrans
        MidtransConfig::$serverKey = config('midtrans.server_key');
        MidtransConfig::$isProduction = config('midtrans.is_production');

        // Buat instance notifikasi otomatis dari Midtrans
        $notification = new MidtransNotification();

        // =========================================================================
        // PERBAIKAN BUG UTAMA:
        // Format order_id dari checkout adalah: "ORDER-[ID_ORDER]-[TIMESTAMP]"
        // Contoh: "ORDER-15-17187123"
        // Hasil explode: index [0] = 'ORDER', index [1] = '15', index [2] = '17187123'
        // =========================================================================
        $orderIdParts = explode('-', $notification->order_id);
        $orderId = $orderIdParts[1] ?? null; // Diubah ke index 1 untuk mengambil ID numerik asli

        $status = $notification->transaction_status;
        $type = $notification->payment_type;
        $fraud = $notification->fraud_status;

        // Cari data order berdasarkan ID asli
        $order = Order::find($orderId);

        if (!$order) {
            return response()->json(['message' => 'Order not found.'], 404);
        }

        // Ambil relasi transaksi dari model Order
        $transaction = $order->transaction;

        if (!$transaction) {
            return response()->json(['message' => 'Transaction record not found for this order.'], 404);
        }

        // Handle status transaksi dari Midtrans (Skema ini sama baik untuk Snap maupun Core API)
        if ($status == 'capture') {
            if ($type == 'credit_card') {
                if ($fraud == 'challenge') {
                    $transaction->status = 'challenge';
                } else {
                    $transaction->status = 'approved';
                    $order->status = 'ordered'; 
                }
            }
        } elseif ($status == 'settlement') {
            // Jika status pembayaran berhasil/lunas (settlement)
            $transaction->status = 'approved';
            $order->status = 'ordered'; // Anda bisa menyesuaikan menjadi 'processing' jika ada status itu
            
        } elseif ($status == 'pending') {
            // Jika pengguna baru mendapatkan VA/QRIS tetapi belum membayar
            $transaction->status = 'pending';
            $order->status = 'ordered'; 
            
        } elseif ($status == 'deny' || $status == 'expire' || $status == 'cancel') {
            // Jika pembayaran ditolak, kedaluwarsa, atau dibatalkan
            $transaction->status = 'declined';
            $order->status = 'canceled'; // Otomatis batalkan pesanan di sistem toko
        }

        // Simpan perubahan ke masing-masing tabel di database
        $transaction->save();
        $order->save();

        return response()->json(['message' => 'Notification handled successfully.']);
    }
}