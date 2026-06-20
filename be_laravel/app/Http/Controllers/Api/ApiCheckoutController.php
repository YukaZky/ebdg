<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\OrderItem;
use Midtrans\Config;
use Midtrans\CoreApi;
use App\Models\Product;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ApiCheckoutController extends Controller
{
    public function checkout(Request $request)
    {
        // Tambahkan validasi payment_type dan bank
        $request->validate([
            'address' => 'required|string',
            'phone' => 'required|string',
            'province_name' => 'required|string',
            'city_name' => 'required|string',
            'courier' => 'required|string',
            'shipping_cost' => 'required|numeric',
            'items' => 'required|array',
            'payment_type' => 'required|string|in:bank_transfer,qris,gopay',
            'bank' => 'required_if:payment_type,bank_transfer|string|in:bca,bni,bri,permata',
        ]);

        $user = Auth::user();
        $cartItems = $request->items;

        $subtotal = 0;
        foreach ($cartItems as $item) {
            $product = Product::find($item['product_id']);
            if ($product) {
                $price = isset($item['price']) && is_numeric($item['price'])
                    ? (float) $item['price']
                    : (float) ($product->sale_price ?: $product->regular_price);

                $subtotal += $price * (int) $item['quantity'];
            }
        }

        $discount = 0;
        $tax = 0;
        $total = $subtotal + $request->shipping_cost - $discount;

        $courierParts = explode(' - ', $request->courier);
        $modePengiriman = $courierParts[0] ?? 'Tidak Diketahui';
        $jenisPengiriman = $courierParts[1] ?? '-';

        DB::beginTransaction();

        try {
            $order = new Order();
            $order->user_id = $user->id;
            $order->subtotal = $subtotal;
            $order->discount = $discount;
            $order->tax = $tax;
            $order->total = $total;
            $order->mode_pengiriman = $modePengiriman;
            $order->jenis_pengiriman = $jenisPengiriman;
            $order->ongkir = $request->shipping_cost;
            $order->name = $user->name;
            $order->phone = $request->phone;
            $order->address = $request->address;
            $order->city = $request->city_name;
            $order->state = $request->province_name;
            $order->country = 'Indonesia';
            $order->locality = '-';
            $order->zip = '-';
            $order->status = 'ordered';
            $order->save();

            foreach ($cartItems as $item) {
                $product = Product::find($item['product_id']);
                if (! $product) continue;

                $price = isset($item['price']) && is_numeric($item['price'])
                    ? (float) $item['price']
                    : (float) ($product->sale_price ?: $product->regular_price);

                $options = [
                    'variation_id' => $item['variation_id'] ?? null,
                    'variation_name' => $item['variation_name'] ?? null,
                    'selected_image' => $item['selected_image'] ?? null,
                    'weight' => $item['weight'] ?? null,
                ];

                $orderItem = new OrderItem();
                $orderItem->order_id = $order->id;
                $orderItem->product_id = $item['product_id'];
                $orderItem->price = $price;
                $orderItem->quantity = $item['quantity'];
                $orderItem->option = json_encode($options);
                $orderItem->save();
            }

            // Konfigurasi Midtrans
            Config::$serverKey = config('midtrans.server_key', env('MIDTRANS_SERVER_KEY'));
            Config::$isProduction = config('midtrans.is_production', env('MIDTRANS_IS_PRODUCTION', false));
            Config::$isSanitized = true;
            Config::$is3ds = true;
            Config::$curlOptions = [
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_SSL_VERIFYHOST => false,
                CURLOPT_HTTPHEADER => [],
            ];

            // Setup Parameter Dasar
            $params = [
                'transaction_details' => [
                    'order_id' => 'ORDER-' . $order->id . '-' . time(),
                    'gross_amount' => (int) $total,
                ],
                'customer_details' => [
                    'first_name' => $user->name,
                    'email' => $user->email,
                    'phone' => $request->phone,
                ],
            ];

            // Penyesuaian Payload Berdasarkan Tipe Pembayaran (Core API)
            if ($request->payment_type === 'bank_transfer') {
                if ($request->bank === 'permata') {
                    $params['payment_type'] = 'permata';
                } else {
                    $params['payment_type'] = 'bank_transfer';
                    $params['bank_transfer'] = [
                        'bank' => $request->bank
                    ];
                }
            } elseif ($request->payment_type === 'qris') {
                $params['payment_type'] = 'qris';
                $params['qris'] = [
                    'acquirer' => 'gopay' // default acquirer QRIS di Midtrans
                ];
            } elseif ($request->payment_type === 'gopay') {
                $params['payment_type'] = 'gopay';
            }

            // Eksekusi Charge ke Midtrans Core API
            $midtransResponse = CoreApi::charge($params);

            // Simpan informasi transaksi ke database lokal
            $transaction = new \App\Models\Transaction();
            $transaction->user_id = $user->id;
            $transaction->order_id = $order->id;
            $transaction->mode = 'transfer';
            $transaction->status = 'pending';
            $transaction->payment_token = $midtransResponse->transaction_id ?? null; // simpan transaction_id dari midtrans
            $transaction->payment_url = null; // Core API tidak menggunakan redirect URL umum snap

            // Opsional: Jika Anda punya kolom payment_details (tipe JSON/Text) di tabel transactions, simpan response mentah dari Midtrans
            if (\Schema::hasColumn('transactions', 'payment_details')) {
                $transaction->payment_details = json_encode($midtransResponse);
            }

            $transaction->save();

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Order dan Transaksi Core API berhasil dibuat',
                'midtrans_response' => $midtransResponse, // Response ini berisi nomor VA atau data QRIS yang dibutuhkan frontend
                'order' => $order->load('items.product')
            ], 200);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Gagal memproses checkout Core API: ' . $e->getMessage()
            ], 500);
        }
    }

    public function checkStatus($id)
    {
        // Cari order beserta relasi transaksi miliknya
        $order = Order::with('transaction')->find($id);

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Pesanan tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'order_id' => $order->id,
            'order_status' => $order->status, // ordered / canceled
            'transaction_status' => $order->transaction ? $order->transaction->status : 'no_transaction' // pending / approved / declined
        ], 200);
    }
}
