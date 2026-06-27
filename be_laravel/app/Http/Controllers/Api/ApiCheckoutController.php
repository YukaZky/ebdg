<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CartItem;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Midtrans\Config;
use Midtrans\CoreApi;

class ApiCheckoutController extends Controller
{
    public function checkout(Request $request)
    {
        $this->validateFinalOrderPayload($request);
        $request->validate([
            'payment_type' => 'required|string|in:bank_transfer,qris,gopay',
            'bank' => 'required_if:payment_type,bank_transfer|string|in:bca,bni,bri,permata',
        ]);

        try {
            $user = Auth::user();
            $activePayment = $this->activePaymentFromRequest($request, $user);
            if ($activePayment) {
                return response()->json($activePayment, 200);
            }

            $order = DB::transaction(fn () => $this->persistFinalOrder($request, $user));
            return $this->chargePaymentMethod($request, $order);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memproses checkout: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function finalize(Request $request)
    {
        $this->validateFinalOrderPayload($request);

        try {
            $user = Auth::user();
            $order = DB::transaction(fn () => $this->persistFinalOrder($request, $user));

            return response()->json([
                'success' => true,
                'message' => 'Order final berhasil dibuat dari alamat dan ongkir.',
                'order' => $order->load('items.product', 'transaction'),
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal finalisasi order: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function setPaymentMethod(Request $request, $id)
    {
        $request->validate([
            'payment_type' => 'required|string|in:bank_transfer,qris,gopay',
            'bank' => 'required_if:payment_type,bank_transfer|string|in:bca,bni,bri,permata',
        ]);

        $order = Order::with('transaction', 'items.product')
            ->where('user_id', Auth::id())
            ->find($id);

        if (! $order) {
            return response()->json(['success' => false, 'message' => 'Pesanan tidak ditemukan.'], 404);
        }

        if ((float) $order->total <= 0) {
            return response()->json(['success' => false, 'message' => 'Total pesanan belum valid.'], 422);
        }

        try {
            return $this->chargePaymentMethod($request, $order);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat instruksi pembayaran: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function resetPayment(Request $request, $id)
    {
        $order = Order::with('transaction', 'items.product')
            ->where('user_id', Auth::id())
            ->find($id);

        if (! $order) {
            return response()->json(['success' => false, 'message' => 'Pesanan tidak ditemukan.'], 404);
        }

        $transaction = $order->transaction ?: new Transaction();
        $previousDetails = $this->transactionDetails($transaction);
        $history = $this->appendSupersededAttempt($previousDetails, $transaction, 'Pembayaran direset oleh user.');

        $transaction->user_id = $order->user_id;
        $transaction->order_id = $order->id;
        $transaction->mode = 'card';
        $transaction->status = 'pending';
        $transaction->payment_token = null;
        $transaction->payment_url = null;
        $this->setTransactionDetails($transaction, [
            'stage' => 'waiting_payment_method',
            'message' => 'Metode pembayaran direset oleh user.',
            'superseded_attempts' => $history,
        ]);
        $transaction->save();

        return response()->json([
            'success' => true,
            'message' => 'Status pembayaran berhasil direset.',
            'order' => $order->fresh()->load('items.product', 'transaction'),
        ], 200);
    }

    public function completeCheckout($id)
    {
        $order = Order::with('items.product', 'transaction')
            ->where('user_id', Auth::id())
            ->find($id);

        if (! $order) {
            return response()->json(['success' => false, 'message' => 'Pesanan tidak ditemukan.'], 404);
        }

        $transaction = $order->transaction;
        if (! $transaction || ! in_array($transaction->status, ['approved', 'settlement', 'capture'], true)) {
            return response()->json([
                'success' => false,
                'message' => 'Checkout akhir hanya bisa dilakukan setelah pembayaran diterima.',
            ], 422);
        }

        $details = $this->transactionDetails($transaction);
        $details['stage'] = 'checkout_completed';
        $details['checkout_completed_at'] = now()->toDateTimeString();
        $this->setTransactionDetails($transaction, $details);
        $transaction->save();

        return response()->json([
            'success' => true,
            'message' => 'Checkout akhir berhasil diselesaikan.',
            'order' => $order->fresh()->load('items.product', 'transaction'),
        ], 200);
    }

    public function show($id)
    {
        $order = Order::with('items.product', 'transaction')
            ->where('user_id', Auth::id())
            ->find($id);

        if (! $order) {
            return response()->json(['success' => false, 'message' => 'Pesanan tidak ditemukan.'], 404);
        }

        return response()->json(['success' => true, 'order' => $order], 200);
    }

    public function checkStatus($id)
    {
        $order = Order::with('transaction')->find($id);

        if (! $order) {
            return response()->json(['success' => false, 'message' => 'Pesanan tidak ditemukan'], 404);
        }

        $details = $this->transactionDetails($order->transaction);

        return response()->json([
            'success' => true,
            'order_id' => $order->id,
            'order_status' => $order->status,
            'transaction_status' => $order->transaction ? $order->transaction->status : 'no_transaction',
            'payment_info' => $this->paymentInfoFromTransaction($order->transaction),
            'checkout_signature' => $details['checkout_signature'] ?? null,
            'payment_stage' => $details['stage'] ?? null,
        ], 200);
    }

    private function validateFinalOrderPayload(Request $request): void
    {
        $request->validate([
            'order_id' => 'nullable|integer',
            'checkout_signature' => 'nullable|string',
            'address' => 'required|string',
            'phone' => 'required|string',
            'province_name' => 'required|string',
            'city_name' => 'required|string',
            'courier' => 'required|string',
            'shipping_cost' => 'required|numeric|min:0',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.price' => 'nullable|numeric|min:0',
            'items.*.cart_item_id' => 'nullable|integer',
            'items.*.variation_id' => 'nullable',
            'items.*.variation_name' => 'nullable',
            'items.*.selected_image' => 'nullable',
            'items.*.weight' => 'nullable',
        ]);
    }

    private function persistFinalOrder(Request $request, $user): Order
    {
        $cartItems = $request->items;
        $subtotal = $this->calculateSubtotal($cartItems);
        $discount = 0;
        $tax = 0;
        $total = $subtotal + (float) $request->shipping_cost - $discount;
        $courierParts = explode(' - ', $request->courier);

        $order = null;
        $isNewOrder = true;
        if ($request->filled('order_id')) {
            $order = Order::with('transaction')
                ->where('user_id', $user->id)
                ->find($request->order_id);
            if (! $order) {
                throw new \Exception('Order sebelumnya tidak ditemukan.');
            }
            $isNewOrder = false;
        }

        if (! $order) {
            $order = new Order();
            $order->user_id = $user->id;
        }

        $order->subtotal = $subtotal;
        $order->discount = $discount;
        $order->tax = $tax;
        $order->total = $total;
        $order->mode_pengiriman = $courierParts[0] ?? 'Tidak Diketahui';
        $order->jenis_pengiriman = $courierParts[1] ?? '-';
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

        if (! $isNewOrder) {
            OrderItem::where('order_id', $order->id)->delete();
        }

        foreach ($cartItems as $item) {
            $product = Product::find($item['product_id']);
            if (! $product) {
                continue;
            }

            $price = isset($item['price']) && is_numeric($item['price'])
                ? (float) $item['price']
                : (float) ($product->sale_price ?: $product->regular_price);

            $orderItem = new OrderItem();
            $orderItem->order_id = $order->id;
            $orderItem->product_id = $item['product_id'];
            $orderItem->price = $price;
            $orderItem->quantity = $item['quantity'];
            $orderItem->option = json_encode([
                'variation_id' => $item['variation_id'] ?? null,
                'variation_name' => $item['variation_name'] ?? null,
                'selected_image' => $item['selected_image'] ?? null,
                'weight' => $item['weight'] ?? null,
            ]);
            $orderItem->save();
        }

        $transaction = $order->transaction ?: new Transaction();
        $previousDetails = $this->transactionDetails($transaction);
        $history = $this->appendSupersededAttempt($previousDetails, $transaction, 'Data checkout berubah sebelum pembayaran selesai.');
        $transaction->user_id = $user->id;
        $transaction->order_id = $order->id;
        $transaction->mode = 'card';
        $transaction->status = 'pending';
        $transaction->payment_token = null;
        $transaction->payment_url = null;
        $this->setTransactionDetails($transaction, [
            'stage' => 'waiting_payment_method',
            'message' => 'Order sudah final, menunggu user memilih metode pembayaran.',
            'checkout_signature' => $this->checkoutSignature($request),
            'superseded_attempts' => $history,
        ]);
        $transaction->save();

        if ($isNewOrder) {
            $this->removeCheckedCartItems($cartItems, $user->id);
        }

        return $order->fresh()->load('items.product', 'transaction');
    }

    private function calculateSubtotal(array $cartItems): float
    {
        $subtotal = 0;
        foreach ($cartItems as $item) {
            $product = Product::find($item['product_id']);
            if (! $product) {
                continue;
            }

            $price = isset($item['price']) && is_numeric($item['price'])
                ? (float) $item['price']
                : (float) ($product->sale_price ?: $product->regular_price);
            $subtotal += $price * (int) $item['quantity'];
        }

        return $subtotal;
    }

    private function removeCheckedCartItems(array $cartItems, int $userId): void
    {
        $cartItemIds = collect($cartItems)->pluck('cart_item_id')->filter()->map(fn ($id) => (int) $id)->unique()->values()->all();
        if (! empty($cartItemIds)) {
            CartItem::where('user_id', $userId)->whereIn('id', $cartItemIds)->delete();
        }
    }

    private function chargePaymentMethod(Request $request, Order $order)
    {
        $signature = $this->checkoutSignature($request);
        $existingPayment = $this->activePaymentResponse($order, $signature);
        if ($existingPayment) {
            return response()->json($existingPayment, 200);
        }

        $this->configureMidtrans();
        $params = [
            'transaction_details' => [
                'order_id' => 'ORDER-' . $order->id . '-' . substr(sha1($signature), 0, 10) . '-' . time(),
                'gross_amount' => (int) round($order->total),
            ],
            'customer_details' => [
                'first_name' => $order->name,
                'email' => Auth::user()->email,
                'phone' => $order->phone,
            ],
        ];

        if ($request->payment_type === 'bank_transfer') {
            if ($request->bank === 'permata') {
                $params['payment_type'] = 'permata';
            } else {
                $params['payment_type'] = 'bank_transfer';
                $params['bank_transfer'] = ['bank' => $request->bank];
            }
        } elseif ($request->payment_type === 'qris') {
            $params['payment_type'] = 'qris';
            $params['qris'] = ['acquirer' => 'gopay'];
        } elseif ($request->payment_type === 'gopay') {
            $params['payment_type'] = 'gopay';
        }

        $midtransArray = $this->toArray(CoreApi::charge($params));
        $paymentInfo = $this->extractPaymentInfo($midtransArray);
        $transaction = $order->transaction ?: new Transaction();
        $previousDetails = $this->transactionDetails($transaction);
        $history = $previousDetails['superseded_attempts'] ?? [];

        $transaction->user_id = $order->user_id;
        $transaction->order_id = $order->id;
        $transaction->mode = 'card';
        $transaction->status = 'pending';
        $transaction->payment_token = $midtransArray['transaction_id'] ?? null;
        $transaction->payment_url = $paymentInfo['qr_code_url'] ?? null;
        $this->setTransactionDetails($transaction, [
            'stage' => 'payment_instruction_created',
            'checkout_signature' => $signature,
            'gross_amount' => (int) round($order->total),
            'payment_type' => $request->payment_type,
            'bank' => $request->input('bank'),
            'payment_info' => $paymentInfo,
            'midtrans_response' => $midtransArray,
            'superseded_attempts' => $history,
        ]);
        $transaction->save();

        return response()->json([
            'success' => true,
            'message' => 'Metode pembayaran berhasil dibuat.',
            'payment_info' => $paymentInfo,
            'midtrans_response' => $midtransArray,
            'order' => $order->fresh()->load('items.product', 'transaction'),
        ], 200);
    }

    private function configureMidtrans(): void
    {
        Config::$serverKey = config('midtrans.server_key', env('MIDTRANS_SERVER_KEY'));
        Config::$isProduction = config('midtrans.is_production', env('MIDTRANS_IS_PRODUCTION', false));
        Config::$isSanitized = true;
        Config::$is3ds = true;
        Config::$curlOptions = [
            CURLOPT_SSL_VERIFYPEER => false,
            CURLOPT_SSL_VERIFYHOST => false,
            CURLOPT_HTTPHEADER => [],
        ];
    }

    private function toArray($value): array
    {
        return json_decode(json_encode($value), true) ?: [];
    }

    private function extractPaymentInfo(array $midtrans): array
    {
        $vaNumber = null;
        $qrCodeUrl = null;
        if (! empty($midtrans['va_numbers'][0]['va_number'])) {
            $vaNumber = $midtrans['va_numbers'][0]['va_number'];
        } elseif (! empty($midtrans['permata_va_number'])) {
            $vaNumber = $midtrans['permata_va_number'];
        } elseif (! empty($midtrans['bill_key'])) {
            $vaNumber = 'Bill Key: ' . $midtrans['bill_key'] . "\nBiller Code: " . ($midtrans['biller_code'] ?? '');
        }

        if (! empty($midtrans['actions']) && is_array($midtrans['actions'])) {
            foreach ($midtrans['actions'] as $action) {
                if (($action['name'] ?? null) === 'generate-qr-code') {
                    $qrCodeUrl = $action['url'] ?? null;
                    break;
                }
            }
        }

        return [
            'va_number' => $vaNumber,
            'qr_code_url' => $qrCodeUrl,
            'expiry_time' => $midtrans['expiry_time'] ?? null,
            'transaction_id' => $midtrans['transaction_id'] ?? null,
            'transaction_status' => $midtrans['transaction_status'] ?? null,
            'payment_type' => $midtrans['payment_type'] ?? null,
        ];
    }

    private function checkoutSignature(Request $request): string
    {
        if ($request->filled('checkout_signature')) {
            return (string) $request->checkout_signature;
        }

        $items = collect($request->items ?? [])
            ->map(fn ($item) => [
                'cart_item_id' => $item['cart_item_id'] ?? null,
                'product_id' => (int) ($item['product_id'] ?? 0),
                'quantity' => (int) ($item['quantity'] ?? 1),
                'price' => isset($item['price']) ? (int) $item['price'] : null,
                'variation_id' => $item['variation_id'] ?? null,
            ])
            ->sortBy(fn ($item) => ($item['cart_item_id'] ?? '') . ':' . $item['product_id'] . ':' . ($item['variation_id'] ?? ''))
            ->values()
            ->all();

        return json_encode([
            'address' => trim((string) $request->address),
            'phone' => trim((string) $request->phone),
            'province_name' => trim((string) $request->province_name),
            'city_name' => trim((string) $request->city_name),
            'courier' => trim((string) $request->courier),
            'shipping_cost' => (int) $request->shipping_cost,
            'payment_type' => (string) $request->payment_type,
            'bank' => $request->input('bank'),
            'items' => $items,
        ]);
    }

    private function activePaymentFromRequest(Request $request, $user): ?array
    {
        if (! $request->filled('order_id')) {
            return null;
        }

        $order = Order::with('transaction', 'items.product')
            ->where('user_id', $user->id)
            ->find($request->order_id);

        return $order ? $this->activePaymentResponse($order, $this->checkoutSignature($request)) : null;
    }

    private function activePaymentResponse(Order $order, ?string $signature = null): ?array
    {
        $order->loadMissing('transaction', 'items.product');
        $transaction = $order->transaction;
        if (! $transaction || empty($transaction->payment_token)) {
            return null;
        }

        $details = $this->transactionDetails($transaction);
        if ($signature && (($details['checkout_signature'] ?? null) !== $signature)) {
            return null;
        }

        $paymentInfo = $details['payment_info'] ?? null;
        if (! is_array($paymentInfo) || ! $this->paymentInfoIsActive($paymentInfo)) {
            return null;
        }

        return [
            'success' => true,
            'message' => 'Instruksi pembayaran aktif digunakan kembali.',
            'reused_payment' => true,
            'payment_info' => $paymentInfo,
            'midtrans_response' => $details['midtrans_response'] ?? null,
            'order' => $order->fresh()->load('items.product', 'transaction'),
        ];
    }

    private function paymentInfoIsActive(array $paymentInfo): bool
    {
        if (empty($paymentInfo['expiry_time'])) {
            return true;
        }
        $timestamp = strtotime($paymentInfo['expiry_time']);
        return ! $timestamp || $timestamp > time();
    }

    private function appendSupersededAttempt(array $details, Transaction $transaction, string $reason): array
    {
        $history = $details['superseded_attempts'] ?? [];
        if (! is_array($history)) {
            $history = [];
        }

        if (! empty($transaction->payment_token) || ! empty($details['payment_info'])) {
            $history[] = [
                'reason' => $reason,
                'superseded_at' => now()->toDateTimeString(),
                'payment_token' => $transaction->payment_token,
                'payment_url' => $transaction->payment_url,
                'checkout_signature' => $details['checkout_signature'] ?? null,
                'gross_amount' => $details['gross_amount'] ?? null,
                'payment_type' => $details['payment_type'] ?? null,
                'bank' => $details['bank'] ?? null,
                'payment_info' => $details['payment_info'] ?? null,
                'midtrans_response' => $details['midtrans_response'] ?? null,
            ];
        }

        return $history;
    }

    private function transactionDetails(?Transaction $transaction): array
    {
        if (! $transaction || ! Schema::hasColumn('transactions', 'payment_details') || empty($transaction->payment_details)) {
            return [];
        }
        $details = json_decode($transaction->payment_details, true);
        return is_array($details) ? $details : [];
    }

    private function setTransactionDetails(Transaction $transaction, array $details): void
    {
        if (Schema::hasColumn('transactions', 'payment_details')) {
            $transaction->payment_details = json_encode($details);
        }
    }

    private function paymentInfoFromTransaction(?Transaction $transaction): ?array
    {
        $details = $this->transactionDetails($transaction);
        return empty($details) ? null : ($details['payment_info'] ?? null);
    }
}
