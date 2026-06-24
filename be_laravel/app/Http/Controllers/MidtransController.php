<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\SellerBalance;
use App\Models\StoreProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
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
        $order = Order::with(['items.product.store', 'transaction'])->find($orderId);

        if (! $order) {
            return response()->json(['message' => 'Order not found.'], 404);
        }

        // Ambil relasi transaksi dari model Order
        $transaction = $order->transaction;

        if (! $transaction) {
            return response()->json(['message' => 'Transaction record not found for this order.'], 404);
        }

        DB::transaction(function () use ($status, $type, $fraud, $order, $transaction) {
            // Handle status transaksi dari Midtrans (Skema ini sama baik untuk Snap maupun Core API)
            if ($status == 'capture') {
                if ($type == 'credit_card') {
                    if ($fraud == 'challenge') {
                        $transaction->status = 'challenge';
                    } else {
                        $transaction->status = 'approved';
                        $order->status = 'ordered';
                        $this->createSellerBalances($order);
                    }
                }
            } elseif ($status == 'settlement') {
                // Jika status pembayaran berhasil/lunas (settlement)
                $transaction->status = 'approved';
                $order->status = 'ordered'; // Anda bisa menyesuaikan menjadi 'processing' jika ada status itu
                $this->createSellerBalances($order);
            } elseif ($status == 'pending') {
                // Jika pengguna baru mendapatkan VA/QRIS tetapi belum membayar
                $transaction->status = 'pending';
                $order->status = 'ordered';
            } elseif ($status == 'deny' || $status == 'expire' || $status == 'cancel') {
                // Jika pembayaran ditolak, kedaluwarsa, atau dibatalkan
                $transaction->status = 'declined';
                $order->status = 'canceled'; // Otomatis batalkan pesanan di sistem toko
                $this->cancelSellerBalances($order);
            }

            // Simpan perubahan ke masing-masing tabel di database
            $transaction->save();
            $order->save();
        });

        return response()->json(['message' => 'Notification handled successfully.']);
    }

    private function createSellerBalances(Order $order): void
    {
        $order->loadMissing(['items.product.store']);

        foreach ($order->items as $item) {
            if (! $item->product) {
                continue;
            }

            if (SellerBalance::where('order_item_id', $item->id)->exists()) {
                continue;
            }

            $product = $item->product;
            $store = $product->store ?: StoreProfile::firstOrCreate(
                ['user_id' => $product->user_id],
                [
                    'name' => 'Toko ' . $product->user_id,
                    'slug' => Str::slug('toko-' . $product->user_id),
                    'status' => 'active',
                ]
            );

            $grossAmount = (float) $item->price * (int) $item->quantity;
            if ($grossAmount <= 0) {
                continue;
            }

            // Default komisi platform 10%. Bisa diubah lewat .env: MARKETPLACE_COMMISSION_RATE=10
            $commissionRate = (float) env('MARKETPLACE_COMMISSION_RATE', 10);
            $platformFee = round($grossAmount * ($commissionRate / 100), 2);
            $sellerNetAmount = round($grossAmount - $platformFee, 2);
            $holdWeekdays = (int) env('SELLER_BALANCE_HOLD_WEEKDAYS', 3);

            SellerBalance::create([
                'store_id' => $store->id,
                'order_id' => $order->id,
                'order_item_id' => $item->id,
                'gross_amount' => $grossAmount,
                'platform_fee' => $platformFee,
                'amount' => $sellerNetAmount,
                'type' => 'credit',
                'status' => 'pending',
                'available_at' => now()->addWeekdays($holdWeekdays),
            ]);
        }
    }

    private function cancelSellerBalances(Order $order): void
    {
        SellerBalance::where('order_id', $order->id)
            ->whereIn('status', ['pending', 'available'])
            ->update([
                'status' => 'cancelled',
                'updated_at' => now(),
            ]);
    }
}
