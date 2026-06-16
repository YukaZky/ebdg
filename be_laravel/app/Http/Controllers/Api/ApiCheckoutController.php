<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\OrderItem;
use Midtrans\Config;
use Midtrans\Snap;
use App\Models\Product;
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

            Config::$serverKey = config('midtrans.server_key', env('MIDTRANS_SERVER_KEY'));
            Config::$isProduction = config('midtrans.is_production', env('MIDTRANS_IS_PRODUCTION', false));
            Config::$isSanitized = true;
            Config::$is3ds = true;
            Config::$curlOptions = [
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

            $paymentUrl = Snap::createTransaction($params)->redirect_url;
            $paymentToken = basename($paymentUrl);

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
