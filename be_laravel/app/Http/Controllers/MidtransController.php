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

        // Format order_id yang pernah dipakai project ini:
        // 1. "15-17187123"        => ID order ada di bagian pertama
        // 2. "ORDER-15-17187123"  => ID order ada di bagian kedua
        // 3. "15"                 => ID order langsung
        $orderId = $this->extractOrderId($notification->order_id);

        $status = $notification->transaction_status;
        $type = $notification->payment_type;
        $fraud = $notification->fraud_status;

        // Cari data order berdasarkan ID asli
        $order = Order::with(['items.product', 'transaction'])->find($orderId);

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

    private function extractOrderId(?string $midtransOrderId): ?int
    {
        if (! $midtransOrderId) {
            return null;
        }

        if (preg_match('/^ORDER-(\d+)-?/', $midtransOrderId, $matches)) {
            return (int) $matches[1];
        }

        if (preg_match('/^(\d+)-?/', $midtransOrderId, $matches)) {
            return (int) $matches[1];
        }

        return is_numeric($midtransOrderId) ? (int) $midtransOrderId : null;
    }

    private function sellerStoreFromProduct($product): StoreProfile
    {
        // Di project ini pemilik barang/toko dibaca dari products.user_id.
        // Jadi saldo pendapatan order item harus masuk ke StoreProfile milik user tersebut.
        return StoreProfile::firstOrCreate(
            ['user_id' => $product->user_id],
            [
                'name' => 'Toko ' . $product->user_id,
                'slug' => Str::slug('toko-' . $product->user_id),
                'status' => 'active',
            ]
        );
    }

    private function sellerBalanceHoldWeekdays(): int
    {
        // Di sandbox/development, saldo langsung available agar testing tarik tunai tidak perlu menunggu 3 hari.
        if (! (bool) config('midtrans.is_production')) {
            return (int) env('SELLER_BALANCE_HOLD_WEEKDAYS_SANDBOX', 0);
        }

        return (int) env('SELLER_BALANCE_HOLD_WEEKDAYS', 3);
    }

    private function createSellerBalances(Order $order): void
    {
        $order->loadMissing(['items.product']);
        $holdWeekdays = $this->sellerBalanceHoldWeekdays();

        foreach ($order->items as $item) {
            if (! $item->product || ! $item->product->user_id) {
                continue;
            }

            if (SellerBalance::where('order_item_id', $item->id)->exists()) {
                continue;
            }

            $product = $item->product;
            $store = $this->sellerStoreFromProduct($product);

            $grossAmount = (float) $item->price * (int) $item->quantity;
            if ($grossAmount <= 0) {
                continue;
            }

            // Default komisi platform 10%. Bisa diubah lewat .env: MARKETPLACE_COMMISSION_RATE=10
            $commissionRate = (float) env('MARKETPLACE_COMMISSION_RATE', 10);
            $platformFee = round($grossAmount * ($commissionRate / 100), 2);
            $sellerNetAmount = round($grossAmount - $platformFee, 2);
            $isImmediatelyAvailable = $holdWeekdays <= 0;

            SellerBalance::create([
                'store_id' => $store->id,
                'order_id' => $order->id,
                'order_item_id' => $item->id,
                'gross_amount' => $grossAmount,
                'platform_fee' => $platformFee,
                'amount' => $sellerNetAmount,
                'type' => 'credit',
                'status' => $isImmediatelyAvailable ? 'available' : 'pending',
                'available_at' => $isImmediatelyAvailable ? now() : now()->addWeekdays($holdWeekdays),
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
