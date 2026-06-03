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

        // Buat instance notifikasi
        $notification = new MidtransNotification();

        // Pisahkan order_id asli dari timestamp
        $orderIdParts = explode('-', $notification->order_id);
        $orderId = $orderIdParts[0];

        $status = $notification->transaction_status;
        $type = $notification->payment_type;
        $fraud = $notification->fraud_status;

        $order = Order::find($orderId);

        if (!$order) {
            return response()->json(['message' => 'Order not found.'], 404);
        }

        // Handle status transaksi
        if ($status == 'capture') {
            if ($type == 'credit_card') {
                if ($fraud == 'challenge') {
                    // TODO: set transaction status on your database to 'challenge'
                } else {
                    $order->transaction->status = 'approved';
                    // Anda mungkin juga ingin mengubah status order utama
                    // $order->status = 'processing'; 
                }
            }
        } elseif ($status == 'settlement') {
            // Jika status pembayaran berhasil (settlement)
            $order->transaction->status = 'approved';
            $order->status = 'ordered'; // atau 'processing' jika Anda punya status itu
            
        } elseif ($status == 'pending') {
            $order->transaction->status = 'pending';
        } elseif ($status == 'deny' || $status == 'expire' || $status == 'cancel') {
            $order->transaction->status = 'declined';
            $order->status = 'canceled'; // Batalkan pesanan
        }

        $order->transaction->save();
        $order->save();

        return response()->json(['message' => 'Notification handled.']);
    }
}
