<?php

namespace App\Http\Controllers;

use App\Models\Address;
use App\Models\CartItem;
use App\Models\Coupon;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Midtrans\Config as MidtransConfig;
use Midtrans\Snap as MidtransSnap;
use Illuminate\Support\Facades\Http;

class CartController extends Controller
{
    // ====================== ONGKIR (tetap) ======================
    public function calculateShipping(Request $request)
    {
        $request->validate([
            'origin'      => 'required',
            'destination' => 'required',
            'weight'      => 'required|integer|min:1',
            'courier'     => 'required'
        ]);

        $apiKey = env('RAJAONGKIR_KEY');
        $url = 'https://api.rajaongkir.com/starter/cost';

        $payload = [
            'origin'      => $request->origin,
            'destination' => $request->destination,
            'weight'      => (int) $request->weight,
            'courier'     => $request->courier
        ];

        $response = Http::withHeaders(['key' => $apiKey])->post($url, $payload);
        if (!$response->ok()) {
            return response()->json(['message' => 'Gagal menghitung ongkir'], 422);
        }

        $data = $response->json();
        $services = [];
        if (!empty($data['rajaongkir']['results'][0]['costs'])) {
            foreach ($data['rajaongkir']['results'][0]['costs'] as $row) {
                foreach ($row['cost'] as $c) {
                    $services[] = [
                        'service' => trim(($row['service'] ?? '') . ' ' . ($row['description'] ?? '')),
                        'etd'     => $c['etd'] ?? null,
                        'value'   => (int) ($c['value'] ?? 0)
                    ];
                }
            }
        }

        return response()->json([
            'courier'  => $request->courier,
            'services' => $services
        ]);
    }

    private function safeGram(int $g): int { return max(1, $g); }

    // ====================== CART (tetap) ======================
    public function index(Request $request)
    {
        $userId = Auth::id();
        $items = CartItem::where('user_id', $userId)->orderBy('created_at', 'DESC')->get();
        $productId = $request->product_id;
        $product = Product::where('id', $productId)->first();

        $subtotal = 0;
        foreach ($items as $item) {
            $subtotal += $item->price * $item->quantity;
        }

        $discount = 0;
        if (session()->has('coupon')) {
            $this->calculateDiscount();
        }

        $total = $subtotal - $discount;

        return view('cart', compact('productId', 'product', 'items', 'subtotal', 'discount', 'total'));
    }

    public function add_to_cart(Request $request)
    {
        if (!Auth::check()) return redirect()->route('login');

        $userId   = Auth::id();
        $product  = Product::find($request->id);

        if (!$product || $product->quantity < $request->quantity) {
            return redirect()->back()->with('error', 'Barang tidak tersedia atau stok tidak mencukupi!');
        }

        $item = CartItem::where('user_id', $userId)->where('product_id', $product->id)->first();

        if ($item) {
            if ($product->quantity < ($item->quantity + $request->quantity)) {
                return redirect()->back()->with('error', 'Stok produk tidak mencukupi!');
            }
            $item->increment('quantity', $request->quantity ?? 1);
        } else {
            CartItem::create([
                'user_id'    => $userId,
                'product_id' => $product->id,
                'quantity'   => $request->quantity ?? 1,
                'price'      => $product->sale_price > 0 ? $product->sale_price : $product->regular_price,
            ]);
        }

        return redirect()->back()->with('success', 'Produk berhasil ditambahkan ke keranjang!');
    }

    public function buyNow(Request $request)
    {
        if (!Auth::check()) return redirect()->route('login');

        $request->validate([
            'id'       => 'required|exists:products,id',
            'quantity' => 'required|integer|min:1',
        ]);

        $product = Product::find($request->id);
        if (!$product || $product->quantity < $request->quantity) {
            return redirect()->back()->with('error', 'Stok produk tidak mencukupi!');
        }

        session()->put('buy_now_item', [
            'product_id' => $request->id,
            'quantity'   => $request->quantity,
        ]);

        session()->forget('selected_checkout_items');
        return redirect()->route('cart.checkout');
    }

    public function decrease_cart_quantity(Request $request, $id)
    {
        $userId = Auth::id();
        $item = CartItem::where('id', $id)->where('user_id', $userId)->first();
        if (!$item) return redirect()->back()->with('error', 'Item tidak ditemukan di keranjang.');

        if ($item->quantity > 1) {
            $item->decrement('quantity', 1);
            if (Session::has('coupon')) $this->calculateDiscount();
            return redirect()->back()->with('success', 'Kuantitas produk berhasil diperbarui.');
        }
        return redirect()->back()->with('error', 'Kuantitas minimum adalah 1. Gunakan tombol hapus untuk menghilangkan produk.');
    }

    public function update_cart_quantity(Request $request, $id)
    {
        $request->validate(['quantity' => 'required|numeric|min:1'], ['quantity.min' => 'Kuantitas minimum untuk produk adalah 1.']);

        $userId = Auth::id();
        $item   = CartItem::where('id', $id)->where('user_id', $userId)->first();
        if (!$item) return redirect()->back()->with('error', 'Item tidak ditemukan di keranjang.');

        $product = Product::find($item->product_id);
        if ($product->quantity < $request->quantity) {
            return redirect()->back()->with('error', 'Stok produk tidak mencukupi!');
        }

        $item->quantity = $request->quantity;
        $item->save();

        if (Session::has('coupon')) $this->calculateDiscount();
        return redirect()->back()->with('success', 'Kuantitas produk berhasil diperbarui.');
    }

    public function checkoutSelected(Request $request)
    {
        $selectedProductIds = $request->input('selected_products', []);
        if (empty($selectedProductIds)) {
            return redirect()->back()->with('error', 'Silakan pilih produk yang akan di-checkout.');
        }

        $userId = Auth::id();
        $selectedItems = CartItem::where('user_id', $userId)
            ->whereIn('id', $selectedProductIds)
            ->get();

        if ($selectedItems->isEmpty()) {
            return redirect()->back()->with('error', 'Produk yang dipilih tidak valid.');
        }

        session()->put('selected_checkout_items', $selectedItems);
        session()->forget('buy_now_item');

        return redirect()->route('cart.checkout');
    }

    // ====================== CHECKOUT (3 skenario) ======================
    public function checkout(Request $request)
    {
        $user    = Auth::user();
        $address = Address::where('user_id', $user->id)->first();

        // 1) BUY NOW
        if (session()->has('buy_now_item')) {
            $buyNowData = session('buy_now_item');
            $product  = Product::find($buyNowData['product_id']);
            $quantity = $buyNowData['quantity'];

            if (!$product) {
                session()->forget('buy_now_item');
                return redirect()->route('shop.index')->with('error', 'Produk tidak ditemukan.');
            }

            $price    = $product->sale_price > 0 ? $product->sale_price : $product->regular_price;
            $subtotal = $price * $quantity;
            $total    = $subtotal;

            $item = new \stdClass();
            $item->product  = $product;
            $item->quantity = $quantity;
            $item->subtotal = $subtotal;
            $items = collect([$item]);

            $this->setAmountForCheckout(true); // [FIX] akan memasukkan diskon kupon bila ada

            // berat total buy now
            $totalWeightG = $this->safeGram(((int)($product->weight_gram ?? 0)) * (int)$quantity);

            return view('checkout', compact('address', 'items', 'subtotal', 'total', 'totalWeightG'));
        }
        // 2) SELECTED ITEMS
        elseif (session()->has('selected_checkout_items')) {
            $items = session('selected_checkout_items');
            if ($items->isEmpty()) {
                return redirect()->route('cart.index')->with('info', 'Tidak ada item terpilih.');
            }

            $subtotal = $items->sum(fn($item) => $item->price * $item->quantity);
            $total    = $subtotal;

            $this->setAmountForCheckout(false, $items); // [FIX] diskon diterapkan ke item terpilih

            $totalWeightG = 0;
            foreach ($items as $it) {
                $p = Product::find($it->product_id);
                $totalWeightG += ((int)($p->weight_gram ?? 0)) * (int)$it->quantity;
            }
            $totalWeightG = $this->safeGram($totalWeightG);

            return view('checkout', compact('address', 'items', 'subtotal', 'total', 'totalWeightG'));
        }
        // 3) SEMUA ITEM CART
        else {
            $items = CartItem::where('user_id', $user->id)->get();
            if ($items->isEmpty()) {
                return redirect()->route('cart.index')->with('info', 'Keranjang Anda kosong.');
            }

            $subtotal = $items->sum(fn($item) => $item->price * $item->quantity);

            $this->calculateDiscount(); // pakai logika cart
            if (Session::has('discounts')) {
                $subtotal = Session::get('discounts')['subtotal']; // AFTER diskon
                $total    = Session::get('discounts')['total'];
            } else {
                $total = $subtotal;
            }

            $this->setAmountForCheckout(false);

            $totalWeightG = 0;
            foreach ($items as $it) {
                $p = Product::find($it->product_id);
                $totalWeightG += ((int)($p->weight_gram ?? 0)) * (int)$it->quantity;
            }
            $totalWeightG = $this->safeGram($totalWeightG);

            return view('checkout', compact('address', 'items', 'subtotal', 'total', 'totalWeightG'));
        }
    }

    // ====================== PLACE ORDER ======================
    public function place_an_order(Request $request)
    {
        $request->validate(
            ['mode' => 'required|in:cod,transfer'],
            ['mode.required' => 'Silakan pilih metode pembayaran.']
        );

        $user_id = Auth::id();
        $address = Address::where('user_id', $user_id)->first();

        // Simpan alamat baru bila belum ada (tetap)
        if (!$address) {
            $validator = Validator::make($request->all(), [
                'name'     => 'required|string|max:255',
                'phone'    => 'required|string|max:20',
                'address'  => 'required|string',
                'landmark' => 'required|string',
                'locality' => 'required|string',
                'city'     => 'required|string',
                'state'    => 'required|string',
                'zip'      => 'required|string|max:10',
                'country'  => 'required|string',
                'type'     => 'required|in:Rumah,Kantor,Lainnya',
            ]);
            if ($validator->fails()) {
                return redirect()->back()->withErrors($validator)->withInput();
            }
            $address = new Address();
            $address->user_id  = $user_id;
            $address->name     = $request->name;
            $address->phone    = $request->phone;
            $address->address  = $request->address;
            $address->landmark = $request->landmark;
            $address->locality = $request->locality;
            $address->city     = $request->city;
            $address->state    = $request->state;
            $address->zip      = $request->zip;
            $address->country  = $request->country;
            $address->type     = $request->type;
            $address->isdefault = 1;
            $address->save();
        }

        $checkout = Session::get('checkout');
        if (!$checkout) {
            return redirect()->route('shop.index')->with('error', 'Sesi checkout berakhir, silakan coba lagi.');
        }

        DB::beginTransaction();
        try {
            $shippingCost = (int) $request->input('shipping_cost', 0);

            $order = new Order();
            $order->user_id   = $user_id;

            // [PENTING] Di struktur session 'checkout' kita simpan nilai SETELAH diskon.
            $order->subtotal  = $checkout['subtotal']; // setelah diskon (seperti sebelumnya)
            $order->discount  = $checkout['discount'];
            $order->tax       = 0;
            $order->total     = $checkout['total'] + $shippingCost; // konsisten dengan UI
            $order->name      = $address->name;
            $order->phone     = $address->phone;
            $order->address   = $address->address;
            $order->landmark  = $address->landmark;
            $order->locality  = $address->locality;
            $order->city      = $address->city;
            $order->state     = $address->state;
            $order->zip       = $address->zip;
            $order->country   = $address->country;
            $order->status    = 'ordered';

            $order->mode_pengiriman  = $request->input('shipping_courier');
            $order->jenis_pengiriman = $request->input('shipping_service');
            $order->ongkir           = $shippingCost;

            $order->save();

            // Items
            if ($checkout['is_buy_now']) {
                $buyNowData = session('buy_now_item');
                $product = Product::find($buyNowData['product_id']);
                OrderItem::create([
                    'product_id' => $buyNowData['product_id'],
                    'order_id'   => $order->id,
                    'price'      => $checkout['price'],
                    'quantity'   => $buyNowData['quantity']
                ]);
                $product->quantity -= $buyNowData['quantity'];
                $product->save();
            } elseif (isset($checkout['is_selected_checkout']) && $checkout['is_selected_checkout']) {
                $selectedItems = session('selected_checkout_items', collect());
                foreach ($selectedItems as $item) {
                    OrderItem::create([
                        'product_id' => $item->product_id,
                        'order_id'   => $order->id,
                        'price'      => $item->price,
                        'quantity'   => $item->quantity
                    ]);
                    $product = Product::find($item->product_id);
                    if ($product) {
                        $product->quantity -= $item->quantity;
                        $product->save();
                    }
                }
            } else {
                $cartItems = CartItem::where('user_id', $user_id)->get();
                foreach ($cartItems as $item) {
                    OrderItem::create([
                        'product_id' => $item->product_id,
                        'order_id'   => $order->id,
                        'price'      => $item->price,
                        'quantity'   => $item->quantity
                    ]);
                    $product = Product::find($item->product_id);
                    if ($product) {
                        $product->quantity -= $item->quantity;
                        $product->save();
                    }
                }
            }

            if ($request->mode == 'transfer') {
                return $this->processTransferOrder($order, $address);
            } else {
                CartItem::where('user_id', $user_id)->delete();
                return $this->processCodOrder($order);
            }
        } catch (\Exception $e) {
            DB::rollBack();
            return redirect()->route('cart.checkout')->with('error', 'Terjadi kesalahan saat memproses pesanan: ' . $e->getMessage());
        }
    }

    protected function processCodOrder(Order $order)
    {
        try {
            $transaction = new Transaction();
            $transaction->user_id = $order->user_id;
            $transaction->order_id = $order->id;
            $transaction->mode = 'cod';
            $transaction->status = 'pending';
            $transaction->save();

            Session::put('order_id', $order->id);

            DB::commit();

            Session::forget(['checkout', 'coupon', 'discounts', 'buy_now_item', 'selected_checkout_items']);

            return redirect()->route('cart.order.confirmation');
        } catch (\Exception $e) {
            DB::rollBack();
            return redirect()->route('cart.checkout')->with('error', 'Gagal memproses pesanan COD: ' . $e->getMessage());
        }
    }

    protected function processTransferOrder(Order $order, Address $address)
    {
        try {
            MidtransConfig::$serverKey   = config('midtrans.server_key');
            MidtransConfig::$isProduction = config('midtrans.is_production');
            MidtransConfig::$isSanitized  = true;
            MidtransConfig::$is3ds        = true;

            $params = [
                'transaction_details' => [
                    'order_id'      => $order->id . '-' . time(),
                    'gross_amount'  => $order->total, // sudah termasuk diskon + ongkir
                ],
                'customer_details' => [
                    'first_name' => $address->name,
                    'email'      => Auth::user()->email,
                    'phone'      => $address->phone,
                ],
            ];

            $snapToken = MidtransSnap::getSnapToken($params);

            $transaction = new Transaction();
            $transaction->user_id = $order->user_id;
            $transaction->order_id = $order->id;
            $transaction->mode = 'transfer';
            $transaction->status = 'pending';
            $transaction->payment_token = $snapToken;
            $transaction->save();

            Session::put('order_id', $order->id);

            DB::commit();

            return response()->json([
                'snap_token' => $snapToken,
                'order_id'   => $order->id
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function cancelPendingOrder(Request $request)
    {
        $orderId = $request->input('order_id');
        if (!$orderId) {
            return response()->json(['status' => 'error', 'message' => 'Order ID tidak ada.'], 400);
        }

        $userId = Auth::id();
        $order = Order::where('id', $orderId)
            ->where('user_id', $userId)
            ->where('status', 'ordered')
            ->first();

        if ($order) {
            $transaction = $order->transaction;
            if ($transaction && $transaction->status === 'pending') {
                DB::beginTransaction();
                try {
                    foreach ($order->orderItems as $item) {
                        $product = Product::find($item->product_id);
                        if ($product) {
                            $product->quantity += $item->quantity;
                            $product->save();
                        }
                    }

                    $order->orderItems()->delete();
                    $order->transaction()->delete();
                    $order->delete();

                    DB::commit();
                    return response()->json(['status' => 'success', 'message' => 'Pesanan berhasil dibatalkan.']);
                } catch (\Exception $e) {
                    DB::rollBack();
                    return response()->json(['status' => 'error', 'message' => 'Gagal membatalkan pesanan: ' . $e->getMessage()], 500);
                }
            }
        }

        return response()->json(['status' => 'error', 'message' => 'Pesanan tidak ditemukan atau sudah diproses.'], 404);
    }

    // ====================== INTI PERBAIKAN ======================
    /**
     * Terapkan kupon dari session ke sebuah subtotal (logika SAMA dengan cart).
     * Mengembalikan array [discount, subtotalSetelahDiskon].
     */
    private function applyCouponToSubtotal(int $rawSubtotal): array
    {
        $discount = 0;
        if (Session::has('coupon')) {
            $c = Session::get('coupon');
            if (($c['type'] ?? '') === 'fixed') {
                $discount = (int) $c['value'];
            } else {
                $discount = (int) floor($rawSubtotal * ((int)$c['value']) / 100);
            }
            // Clamp agar tidak minus
            if ($discount > $rawSubtotal) $discount = $rawSubtotal;
        }
        return [$discount, $rawSubtotal - $discount];
    }

    /**
     * [MODIFIKASI] Mengatur jumlah total untuk checkout.
     * Menangani 3 skenario dan MEMASUKKAN diskon kupon untuk
     * Buy Now & Checkout Pilihan (sebelumnya 0).
     */
    public function setAmountForCheckout($isBuyNow = false, $items = null)
    {
        $user_id = Auth::id();

        // 1) BUY NOW
        if ($isBuyNow && session()->has('buy_now_item')) {
            $buyNowData = session('buy_now_item');
            $product = Product::find($buyNowData['product_id']);
            $price   = $product->sale_price > 0 ? $product->sale_price : $product->regular_price;
            $rawSubtotal = $price * $buyNowData['quantity'];

            // [FIX] terapkan kupon ke subtotal Buy Now
            [$discount, $after] = $this->applyCouponToSubtotal((int)$rawSubtotal);

            // Untuk blade checkout (bagian Ringkasan) – konsisten dengan cart
            Session::put('discounts', [
                'discount' => $discount,
                'subtotal' => $after, // after diskon
                'tax'      => 0,
                'total'    => $after
            ]);

            // Untuk place_an_order
            Session::put('checkout', [
                'is_buy_now'            => true,
                'is_selected_checkout'  => false,
                'discount'              => $discount,
                'subtotal'              => $after, // disimpan AFTER diskon (seperti skenario cart sebelumnya)
                'tax'                   => 0,
                'total'                 => $after,
                'price'                 => $price
            ]);

            return;
        }

        // 2) CHECKOUT PILIHAN
        if ($items !== null) {
            $rawSubtotal = $items->sum(fn($item) => $item->price * $item->quantity);

            // [FIX] kupon diterapkan ke subtotal dari item terpilih
            [$discount, $after] = $this->applyCouponToSubtotal((int)$rawSubtotal);

            Session::put('discounts', [
                'discount' => $discount,
                'subtotal' => $after,
                'tax'      => 0,
                'total'    => $after
            ]);

            Session::put('checkout', [
                'is_buy_now'            => false,
                'is_selected_checkout'  => true,
                'discount'              => $discount,
                'subtotal'              => $after, // after diskon
                'tax'                   => 0,
                'total'                 => $after
            ]);

            return;
        }

        // 3) SEMUA ITEM CART (logika lama dipertahankan)
        $cartItems = CartItem::where('user_id', $user_id)->get();
        if ($cartItems->isEmpty()) {
            Session::forget('checkout');
            return;
        }

        $rawSubtotal = $cartItems->sum(fn($item) => $item->price * $item->quantity);

        if (Session::has('discounts')) {
            $discountData = Session::get('discounts');
            Session::put('checkout', [
                'is_buy_now'            => false,
                'is_selected_checkout'  => false,
                'discount'              => $discountData['discount'] ?? 0,
                'subtotal'              => $discountData['subtotal'] ?? $rawSubtotal, // after
                'tax'                   => 0,
                'total'                 => $discountData['total'] ?? ($rawSubtotal)
            ]);
        } else {
            Session::put('checkout', [
                'is_buy_now'            => false,
                'is_selected_checkout'  => false,
                'discount'              => 0,
                'subtotal'              => $rawSubtotal,
                'tax'                   => 0,
                'total'                 => $rawSubtotal,
            ]);
        }
    }

    // ====================== UTIL LAIN (tetap) ======================
    public function updateQty(Request $request, $id)
    {
        $request->validate(['quantity' => 'required|integer|min:1']);
        $item = CartItem::findOrFail($id);
        $item->quantity = $request->quantity;
        $item->save();
        return redirect()->back();
    }

    public function increase_cart_quantity($id)
    {
        $product = CartItem::find($id);
        $product->quantity += 1;
        $product->save();
        return redirect()->back();
    }

    public function apply_coupon_code(Request $request)
    {
        $coupon_code = $request->coupon_code;

        $coupon = Coupon::where('code', $coupon_code)
                        ->where('expiry_date', '>=', Carbon::today())
                        ->where('cart_value', '>', 0)
                        ->first();

        if (!$coupon) {
            return redirect()->back()->with('error', 'Voucher tidak valid atau sudah habis digunakan!');
        }

        try {
            DB::transaction(function () use ($coupon) {
                $coupon->decrement('cart_value', 1);
                Session::put('coupon', [
                    'code'  => $coupon->code,
                    'type'  => $coupon->type,
                    'value' => $coupon->value,
                ]);
            });

            // Jangan hitung di sini; akan dihitung ulang sesuai skenario checkout
            return redirect()->back()->with('success', 'Voucher Berhasil digunakan!');
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Terjadi kesalahan saat memproses voucher.');
        }
    }

    public function remove_coupon_code()
    {
        if (!Session::has('coupon')) return back();

        $couponCode = Session::get('coupon')['code'];

        try {
            DB::transaction(function () use ($couponCode) {
                $coupon = Coupon::where('code', $couponCode)->first();
                if ($coupon) $coupon->increment('cart_value', 1);
                Session::forget('coupon');
                Session::forget('discounts');
            });

            return back()->with('success', 'Voucher berhasil dihapus!');
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Terjadi kesalahan saat menghapus voucher.');
        }
    }

    public function remove_item(Request $request)
    {
        $userId     = Auth::id();
        $cartItemId = $request->id;

        CartItem::where('id', $cartItemId)->where('user_id', $userId)->delete();

        if (Session::has('coupon')) $this->calculateDiscount();

        return redirect()->back()->with('success', 'Produk berhasil dihapus dari keranjang!');
    }

    public function empty_cart()
    {
        $userId = Auth::id();
        CartItem::where('user_id', $userId)->delete();
        Session::forget(['coupon', 'discounts', 'selected_checkout_items']);
        return redirect()->back()->with('success', 'Keranjang berhasil dikosongkan!');
    }

    // Logika diskon versi CART (tetap)
    public function calculateDiscount()
    {
        if (!Session::has('coupon')) return;

        $user_id = Auth::id();
        $items   = CartItem::where('user_id', $user_id)->get();

        if ($items->isEmpty()) {
            Session::forget('coupon');
            Session::forget('discounts');
            return;
        }

        $subtotal = $items->sum(fn($item) => $item->price * $item->quantity);
        $discount = 0;

        $coupon = Session::get('coupon');
        if ($coupon['type'] == 'fixed') {
            $discount = (int) $coupon['value'];
        } else {
            $discount = (int) floor($subtotal * $coupon['value'] / 100);
        }

        if ($discount > $subtotal) $discount = $subtotal;

        $subtotalAfterDiscount = $subtotal - $discount;

        Session::put('discounts', [
            'discount' => $discount,
            'subtotal' => $subtotalAfterDiscount,
            'tax'      => 0,
            'total'    => $subtotalAfterDiscount
        ]);
    }

    public function paymentSuccess(Request $request)
    {
        $result = $request->input('result');

        Session::flash('transaction_details', [
            'transaction_id' => $result['transaction_id'],
            'payment_type'   => str_replace('_', ' ', $result['payment_type']),
            'status_message' => $result['status_message'],
            'gross_amount'   => number_format($result['gross_amount'], 0, ',', '.'),
        ]);

        $user_id = Auth::id();
        $checkout = Session::get('checkout');

        if ($checkout) {
            if (isset($checkout['is_selected_checkout']) && $checkout['is_selected_checkout']) {
                $selectedItems   = session('selected_checkout_items', collect());
                $itemIdsToDelete = $selectedItems->pluck('id')->toArray();
                CartItem::where('user_id', $user_id)->whereIn('id', $itemIdsToDelete)->delete();
            } else if (!$checkout['is_buy_now']) {
                CartItem::where('user_id', $user_id)->delete();
            }
        }

        Session::forget(['checkout', 'coupon', 'discounts', 'buy_now_item', 'selected_checkout_items']);

        return response()->json(['status' => 'success']);
    }

    public function order_confirmation()
    {
        if (!Session::has('order_id')) return redirect()->route('cart.index');

        $order = Order::find(Session::get('order_id'));
        $transactionDetails = Session::get('transaction_details');

        Session::forget('order_id');

        return view('order-confirmation', compact('order', 'transactionDetails'));
    }
}
