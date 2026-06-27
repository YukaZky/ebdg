<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Address;
use App\Models\Conversation;
use App\Models\ConversationMessage;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductReview;
use App\Models\StoreProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class ApiMarketplaceController extends Controller
{
    private function attachGalleryImagesAndCover($product)
    {
        $galleryImages = DB::table('product_images')
            ->where('product_id', $product->id)
            ->orderBy('id', 'asc')
            ->get();

        $product->images = $galleryImages;
        $product->product_images = $galleryImages;

        if ((empty($product->image) || $product->image === 'null') && $galleryImages->isNotEmpty()) {
            $product->image = $galleryImages->first()->image;
        }

        return $product;
    }

    private function storeAddress($userId)
    {
        return Address::where('user_id', $userId)
            ->orderBy('is_store_address', 'desc')
            ->orderBy('isdefault', 'desc')
            ->latest()
            ->first();
    }

    private function mergeStoreAddress($store)
    {
        $address = $this->storeAddress($store->user_id);
        if (! $address) return [$store, null];

        $area = collect([$address->locality, $address->city_name, $address->province_name])
            ->filter(fn ($item) => ! empty($item) && $item !== '-')
            ->implode(', ');

        $store->address = trim($address->address . ($area ? ', ' . $area : '')) ?: $store->address;
        $store->phone = $address->phone ?: $store->phone;
        $store->province_name = $address->province_name ?: $store->province_name;
        $store->city_name = $address->city_name ?: $store->city_name;

        if ($address->latitude && $address->longitude) {
            $store->maps_url = 'https://www.google.com/maps/search/?api=1&query=' . $address->latitude . ',' . $address->longitude;
        }

        return [$store, $address];
    }

    private function verifiedReviewQuery($productId = null, $storeId = null)
    {
        $query = ProductReview::with(['user:id,name', 'product:id,name', 'order:id,status'])
            ->where(function ($q) {
                $q->whereNull('order_id')
                    ->orWhereHas('order', fn ($order) => $order->whereIn('status', ['delivered', 'done', 'completed', 'complete', 'selesai']));
            });

        if ($productId) $query->where('product_id', $productId);
        if ($storeId) $query->where('store_id', $storeId);

        return $query;
    }

    private function refreshStoreRating(?StoreProfile $store): void
    {
        if (! $store) return;

        $reviewQuery = ProductReview::where('store_id', $store->id)
            ->whereHas('product', fn ($product) => $product->where('user_id', $store->user_id));

        $store->rating_average = round((float) $reviewQuery->avg('rating'), 2);
        $store->rating_count = (clone $reviewQuery)->count();
        $store->save();
    }

    private function conversationQueryForUser(Request $request, ?string $role = null)
    {
        $userId = $request->user()->id;
        $query = Conversation::with(['customer:id,name,email', 'merchant:id,name,email', 'product:id,user_id,name,slug,image']);

        if ($role === 'seller') return $query->where('seller_id', $userId);
        if ($role === 'buyer') return $query->where('buyer_id', $userId);

        return $query->where(function ($query) use ($userId) {
            $query->where('buyer_id', $userId)->orWhere('seller_id', $userId);
        });
    }

    private function conversationPayload(Conversation $conversation, int $userId): array
    {
        $isMerchant = (int) $conversation->seller_id === $userId;
        $counterpart = $isMerchant ? $conversation->customer : $conversation->merchant;
        $payload = $conversation->toArray();
        $payload['role'] = $isMerchant ? 'seller' : 'buyer';
        $payload['counterpart'] = $counterpart ? [
            'id' => $counterpart->id,
            'name' => $counterpart->name,
            'email' => $counterpart->email,
        ] : null;
        $payload['buyer'] = $conversation->customer;
        $payload['seller'] = $conversation->merchant;
        return $payload;
    }

    public function myStore(Request $request)
    {
        $store = StoreProfile::firstOrCreate(
            ['user_id' => $request->user()->id],
            [
                'name' => $request->user()->name . ' Store',
                'slug' => Str::slug($request->user()->name . '-' . $request->user()->id),
                'status' => 'active',
            ]
        );

        [$store, $address] = $this->mergeStoreAddress($store);
        $this->refreshStoreRating($store);
        $store->store_address = $address;

        return response()->json(['success' => true, 'data' => $store]);
    }

    public function saveStore(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:30',
            'description' => 'nullable|string',
            'address' => 'nullable|string',
            'maps_url' => 'nullable|string',
            'instagram' => 'nullable|string|max:255',
            'tiktok' => 'nullable|string|max:255',
            'facebook' => 'nullable|string|max:255',
            'website' => 'nullable|string|max:255',
            'logo' => 'nullable|image|max:2048',
            'banner' => 'nullable|image|max:4096',
        ]);

        $store = StoreProfile::firstOrNew(['user_id' => $request->user()->id]);
        $store->fill($request->only([
            'name', 'phone', 'description', 'address', 'maps_url', 'province_name', 'city_name',
            'instagram', 'tiktok', 'facebook', 'website',
        ]));
        $store->slug = $store->slug ?: Str::slug($request->name . '-' . $request->user()->id);

        $directory = public_path('uploads/stores');
        if (! is_dir($directory)) mkdir($directory, 0755, true);

        if ($request->hasFile('logo')) {
            $logoName = time() . '_' . $request->user()->id . '_store_logo.' . $request->logo->extension();
            $request->logo->move($directory, $logoName);
            $store->logo = $logoName;
        }
        if ($request->hasFile('banner')) {
            $bannerName = time() . '_' . $request->user()->id . '_store_banner.' . $request->banner->extension();
            $request->banner->move($directory, $bannerName);
            $store->banner = $bannerName;
        }

        $store->status = 'active';
        $store->save();
        $this->refreshStoreRating($store);

        return response()->json(['success' => true, 'message' => 'Profil toko berhasil disimpan', 'data' => $store]);
    }

    public function storeDetail($slug)
    {
        $store = StoreProfile::withCount('products')->where('slug', $slug)->firstOrFail();
        [$store, $storeAddress] = $this->mergeStoreAddress($store);
        $this->refreshStoreRating($store);

        $products = Product::with(['category', 'brand', 'variations', 'reviews'])
            ->where('user_id', $store->user_id)
            ->latest()
            ->get();

        foreach ($products as $product) {
            $this->attachGalleryImagesAndCover($product);
        }

        $reviews = $this->verifiedReviewQuery(storeId: $store->id)->latest()->get();

        return response()->json([
            'success' => true,
            'data' => [
                'store' => $store,
                'store_address' => $storeAddress,
                'products' => $products,
                'reviews' => $reviews,
            ]
        ]);
    }

    public function sellerOrders(Request $request)
    {
        $sellerId = (int) $request->user()->id;
        $orders = Order::with(['items.product', 'transaction'])
            ->whereHas('items.product', fn ($q) => $q->where('user_id', $sellerId))
            ->latest()
            ->get()
            ->map(fn ($order) => $this->sellerOrderPayload($order, $sellerId))
            ->filter(fn ($order) => in_array($order['seller_status'], ['paid', 'packing', 'delivered', 'done', 'canceled'], true))
            ->values();

        return response()->json(['success' => true, 'data' => $orders]);
    }

    public function updateSellerOrderStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required|string|in:packing,delivered,done,canceled']);

        $sellerId = (int) $request->user()->id;
        $order = Order::with(['items.product', 'transaction'])
            ->whereHas('items.product', fn ($q) => $q->where('user_id', $sellerId))
            ->findOrFail($id);

        $currentStatus = $this->sellerStatus($order);
        $nextStatus = $request->status;
        $allowed = [
            'paid' => ['packing', 'canceled'],
            'packing' => ['delivered', 'canceled'],
            'delivered' => ['done'],
        ];

        if (! in_array($nextStatus, $allowed[$currentStatus] ?? [], true)) {
            return response()->json(['success' => false, 'message' => 'Status pesanan tidak bisa diperbarui dari tahap saat ini.'], 422);
        }

        $order->status = $nextStatus;
        if ($nextStatus === 'delivered') $order->delivered_date = now()->toDateString();
        if ($nextStatus === 'canceled') $order->canceled_date = now()->toDateString();
        $order->save();

        return response()->json([
            'success' => true,
            'message' => 'Status pesanan berhasil diperbarui',
            'data' => $this->sellerOrderPayload($order->fresh()->load('items.product', 'transaction'), $sellerId),
        ]);
    }

    private function sellerOrderPayload(Order $order, int $sellerId): array
    {
        $order->loadMissing(['items.product', 'transaction']);
        $sellerItems = $order->items->filter(fn ($item) => $item->product && (int) $item->product->user_id === $sellerId)->values();
        $data = $order->toArray();
        $data['items'] = $sellerItems->map(function ($item) {
            $payload = $item->toArray();
            $payload['line_total'] = (float) $item->price * (int) $item->quantity;
            return $payload;
        })->all();
        $data['seller_total'] = $sellerItems->sum(fn ($item) => (float) $item->price * (int) $item->quantity);
        $data['seller_item_count'] = $sellerItems->sum(fn ($item) => (int) $item->quantity);
        $data['transaction'] = $order->transaction?->toArray();
        $data['transaction_status'] = $order->transaction ? (string) $order->transaction->status : 'no_transaction';
        $details = $this->transactionDetails($order->transaction);
        $data['payment_stage'] = $details['stage'] ?? null;
        $data['payment_type'] = $details['payment_type'] ?? null;
        $data['payment_bank'] = $details['bank'] ?? null;
        $data['payment_info'] = $details['payment_info'] ?? null;
        $data['payment_transaction_id'] = is_array($data['payment_info']) ? ($data['payment_info']['transaction_id'] ?? null) : null;
        $data['seller_status'] = $this->sellerStatus($order);
        $data['seller_status_label'] = $this->sellerStatusLabel($data['seller_status']);
        return $data;
    }

    private function sellerStatus(Order $order): string
    {
        $orderStatus = strtolower((string) $order->status);
        $transactionStatus = strtolower((string) ($order->transaction?->status ?? ''));
        if (in_array($orderStatus, ['canceled', 'cancelled'], true) || in_array($transactionStatus, ['declined', 'cancel', 'canceled', 'expire', 'expired'], true)) return 'canceled';
        if (in_array($orderStatus, ['done', 'completed', 'complete', 'selesai'], true)) return 'done';
        if (in_array($orderStatus, ['delivered', 'deliver', 'dikirim'], true)) return 'delivered';
        if (in_array($orderStatus, ['packing', 'processing', 'shipped', 'dikemas'], true)) return 'packing';
        if (in_array($transactionStatus, ['approved', 'settlement', 'capture'], true)) return 'paid';
        return 'pending_payment';
    }

    private function sellerStatusLabel(string $status): string
    {
        return match ($status) {
            'paid' => 'Dibayar',
            'packing' => 'Dikemas',
            'delivered' => 'Dikirim',
            'done' => 'Selesai',
            'canceled' => 'Dibatalkan',
            default => 'Belum Dibayar',
        };
    }

    private function transactionDetails($transaction): array
    {
        if (! $transaction || ! Schema::hasColumn('transactions', 'payment_details') || empty($transaction->payment_details)) return [];
        $details = json_decode($transaction->payment_details, true);
        return is_array($details) ? $details : [];
    }

    public function productReviews($productId)
    {
        $reviews = $this->verifiedReviewQuery(productId: $productId)->latest()->get();
        $average = round((float) $this->verifiedReviewQuery(productId: $productId)->avg('rating'), 2);
        return response()->json(['success' => true, 'average' => $average, 'data' => $reviews]);
    }

    public function addReview(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'order_id' => 'required|exists:orders,id',
            'rating' => 'required|integer|min:1|max:5',
            'review' => 'nullable|string|max:1000',
        ]);

        $product = Product::findOrFail($request->product_id);
        $order = Order::with('items.product')
            ->where('user_id', $request->user()->id)
            ->where('id', $request->order_id)
            ->firstOrFail();

        $status = strtolower((string) $order->status);
        if (! in_array($status, ['delivered', 'done', 'completed', 'complete', 'selesai'], true)) {
            return response()->json(['success' => false, 'message' => 'Ulasan hanya bisa diberikan untuk pesanan dikirim atau selesai.'], 422);
        }

        $belongsToOrder = $order->items->contains(fn ($item) => (int) $item->product_id === (int) $product->id);
        if (! $belongsToOrder) {
            return response()->json(['success' => false, 'message' => 'Produk tidak ditemukan pada pesanan ini.'], 422);
        }

        $store = StoreProfile::firstOrCreate(
            ['user_id' => $product->user_id],
            ['name' => 'Store', 'slug' => Str::slug('store-' . $product->user_id), 'status' => 'active']
        );

        $review = ProductReview::updateOrCreate(
            ['product_id' => $product->id, 'user_id' => $request->user()->id, 'order_id' => $order->id],
            ['store_id' => $store->id, 'rating' => $request->rating, 'review' => $request->review]
        );

        $this->refreshStoreRating($store);

        return response()->json(['success' => true, 'message' => 'Ulasan berhasil disimpan', 'data' => $review->load(['user:id,name', 'product:id,name'])]);
    }

    public function conversations(Request $request)
    {
        $userId = $request->user()->id;
        $role = $request->query('role') ?: $request->query('scope');
        $role = in_array($role, ['seller', 'buyer'], true) ? $role : null;
        $data = $this->conversationQueryForUser($request, $role)
            ->withCount(['chatItems as unread_count' => function ($query) use ($userId) {
                $query->where('sender_id', '!=', $userId)->whereNull('read_at');
            }])
            ->latest('last_message_at')
            ->get()
            ->map(fn ($conversation) => $this->conversationPayload($conversation, $userId));
        return response()->json(['success' => true, 'data' => $data]);
    }

    public function startConversation(Request $request)
    {
        $request->validate([
            'seller_id' => 'nullable|required_without:product_id|exists:users,id',
            'product_id' => 'nullable|exists:products,id',
        ]);
        $product = $request->product_id ? Product::select('id', 'user_id')->findOrFail($request->product_id) : null;
        $sellerId = $product ? (int) $product->user_id : (int) $request->seller_id;
        $productId = $product ? $product->id : null;
        if ($sellerId <= 0) return response()->json(['success' => false, 'message' => 'Data penjual belum tersedia'], 422);
        if ($sellerId === (int) $request->user()->id) return response()->json(['success' => false, 'message' => 'Tidak bisa chat toko sendiri'], 422);
        $conversation = Conversation::firstOrCreate(
            ['buyer_id' => $request->user()->id, 'seller_id' => $sellerId, 'product_id' => $productId],
            ['last_message_at' => now()]
        );
        $conversation->load(['customer:id,name,email', 'merchant:id,name,email', 'product:id,user_id,name,slug,image']);
        return response()->json(['success' => true, 'data' => $this->conversationPayload($conversation, $request->user()->id)]);
    }

    public function messages(Request $request, $conversationId)
    {
        $conversation = $this->conversationQueryForUser($request)->findOrFail($conversationId);
        ConversationMessage::where('conversation_id', $conversation->id)
            ->where('sender_id', '!=', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);
        $messages = ConversationMessage::with('author:id,name,email')
            ->where('conversation_id', $conversation->id)
            ->orderBy('id')
            ->get()
            ->map(function ($item) {
                $payload = $item->toArray();
                $payload['sender'] = $item->author ? [
                    'id' => $item->author->id,
                    'name' => $item->author->name,
                    'email' => $item->author->email,
                ] : null;
                return $payload;
            });
        return response()->json(['success' => true, 'conversation' => $this->conversationPayload($conversation, $request->user()->id), 'data' => $messages]);
    }

    public function sendMessage(Request $request, $conversationId)
    {
        $request->validate(['message' => 'required|string']);
        $conversation = $this->conversationQueryForUser($request)->findOrFail($conversationId);
        $message = ConversationMessage::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $request->user()->id,
            'message' => $request->message,
        ]);
        $message->load('author:id,name,email');
        $conversation->last_message = $request->message;
        $conversation->last_message_at = now();
        $conversation->save();
        $payload = $message->toArray();
        $payload['sender'] = ['id' => $request->user()->id, 'name' => $request->user()->name, 'email' => $request->user()->email];
        return response()->json(['success' => true, 'data' => $payload]);
    }
}
