<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CartItem;
use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Support\Str;
use Midtrans\Config;
use Midtrans\Snap;
use App\Models\Product;
use App\Models\Transaction;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ApiCheckoutController extends Controller
{
    public function checkout(Request $request)
    {
        $request->validate([
            'address' => 'required|string',
            'phone' => 'required|string',
            'province_name' => 'required|string',
            'city_name' => 'required|string',
            'courier' => 'required|string',
            'shipping_cost' => 'required|numeric',
            'items' => 'required|array',
        ]);

        $user = Auth::user();
        $cartItems = $request->items;

        // 1. Hitung Subtotal dari items yang dikirim Flutter
        $subtotal = 0;
        foreach ($cartItems as $item) {
            $product = Product::find($item['product_id']);
            if ($product) {
                $subtotal += ($product->regular_price * $item['quantity']);
            }
        }

        $discount = 0; // Sesuaikan jika ada sistem kupon nanti
        $tax = 0;
        $total = $subtotal + $request->shipping_cost - $discount;

        // Pecah kurir dan layanan (Contoh input dari Flutter: "JNE - REG")
        $courierParts = explode(' - ', $request->courier);
        $modePengiriman = $courierParts[0] ?? 'Tidak Diketahui';
        $jenisPengiriman = $courierParts[1] ?? '-';

        DB::beginTransaction();

        try {
            // 2. Simpan ke Tabel Orders
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

            // 3. Simpan ke Tabel Order Items
            foreach ($cartItems as $item) {
                $product = Product::find($item['product_id']);

                $orderItem = new OrderItem();
                $orderItem->order_id = $order->id;
                $orderItem->product_id = $item['product_id'];
                $orderItem->price = $product->regular_price;
                $orderItem->quantity = $item['quantity'];
                $orderItem->option = json_encode($item['options'] ?? null); // Menyimpan variasi jika ada
                $orderItem->save();

                // Opsional: Kurangi stok produk di sini jika diperlukan
                // $product->decrement('quantity', $item['quantity']);
            }

            // 4. Konfigurasi Midtrans & Generate Snap Token/URL
            \Midtrans\Config::$serverKey = config('midtrans.server_key', env('MIDTRANS_SERVER_KEY'));
            \Midtrans\Config::$isProduction = config('midtrans.is_production', env('MIDTRANS_IS_PRODUCTION', false));
            \Midtrans\Config::$isSanitized = true;
            \Midtrans\Config::$is3ds = true;

            // PERBAIKAN: Cara yang benar untuk mematikan verifikasi SSL khusus internal cURL Midtrans
            \Midtrans\Config::$curlOptions = [
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_SSL_VERIFYHOST => false,
                CURLOPT_HTTPHEADER => [],
            ];

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

            // Generate payment URL
            $paymentUrl = \Midtrans\Snap::createTransaction($params)->redirect_url;
            $paymentToken = basename($paymentUrl);

            // 5. Simpan ke Tabel Transactions
            $transaction = new \App\Models\Transaction();
            $transaction->user_id = $user->id;
            $transaction->order_id = $order->id;
            $transaction->mode = 'transfer';
            $transaction->status = 'pending';
            $transaction->payment_token = $paymentToken;
            $transaction->payment_url = $paymentUrl;
            $transaction->save();

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Order berhasil dibuat',
                'payment_url' => $paymentUrl,
                'order' => $order->load('items.product')
            ], 200);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Gagal memproses checkout: ' . $e->getMessage()
            ], 500);
        }
    }
}
