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

class ApiCheckoutController extends Controller
{
    public function process(Request $request)
    {
        // Validasi data pengiriman dari Flutter
        $request->validate([
            'address' => 'required|string',
            'phone' => 'required|string',
        ]);

        $user = $request->user();
        
        // 1. Ambil data keranjang
        $cartItems = CartItem::with('product')->where('user_id', $user->id)->get();
        
        if ($cartItems->isEmpty()) {
            return response()->json(['success' => false, 'message' => 'Keranjang kosong'], 400);
        }

        // 2. Hitung Total Harga
        $totalPrice = 0;
        foreach ($cartItems as $item) {
            $totalPrice += $item->product->regular_price * $item->quantity;
        }

        // 3. Buat Data Pesanan (Order)
        $order = Order::create([
            'user_id' => $user->id,
            'subtotal' => $totalPrice,
            'discount' => 0,
            'tax' => 0,
            'total' => $totalPrice,
            'name' => $user->name,
            'phone' => $request->phone,
            'locality' => 'Mobile Checkout', 
            'address' => $request->address,
            'city' => 'Semarang', // Sementara di-hardcode, tahap selanjutnya bisa diintegrasikan dengan API RajaOngkir Anda
            'state' => 'Jawa Tengah',
            'country' => 'Indonesia',
            'landmark' => '',
            'zip' => '',
            'type' => 'home',
            'status' => 'ordered',
            'is_shipping_different' => false,
        ]);

        // 4. Pindahkan Item dari Keranjang ke Order Items
        foreach ($cartItems as $item) {
            OrderItem::create([
                'product_id' => $item->product_id,
                'order_id' => $order->id,
                'price' => $item->product->regular_price,
                'quantity' => $item->quantity,
                'options' => '',
            ]);
        }

        // Hapus keranjang setelah dipindah ke order
        CartItem::where('user_id', $user->id)->delete();

        // 5. Konfigurasi Midtrans
        Config::$serverKey = config('midtrans.server_key'); // Pastikan server_key ada di .env
        Config::$isProduction = config('midtrans.is_production', false);
        Config::$isSanitized = true;
        Config::$is3ds = true;

        // 6. Siapkan Parameter untuk Midtrans
        $params = [
            'transaction_details' => [
                'order_id' => 'ORD-' . $order->id . '-' . time(),
                'gross_amount' => $totalPrice,
            ],
            'customer_details' => [
                'first_name' => $user->name,
                'email' => $user->email,
                'phone' => $request->phone,
            ],
        ];

        try {
            // Minta Snap URL Pembayaran ke Midtrans
            $paymentUrl = Snap::createTransaction($params)->redirect_url;
            
            return response()->json([
                'success' => true,
                'message' => 'Pesanan berhasil dibuat',
                'payment_url' => $paymentUrl
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat pembayaran Midtrans: ' . $e->getMessage()
            ], 500);
        }
    }
}