<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\ConversationMessage;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductReview;
use App\Models\StoreProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ApiMarketplaceController extends Controller
{
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

        return response()->json(['success' => true, 'data' => $store]);
    }

    public function saveStore(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:30',
            'description' => 'nullable|string',
            'address' => 'nullable|string',
        ]);

        $store = StoreProfile::firstOrNew(['user_id' => $request->user()->id]);
        $store->fill($request->only(['name', 'phone', 'description', 'address', 'province_name', 'city_name']));
        $store->slug = $store->slug ?: Str::slug($request->name . '-' . $request->user()->id);

        if ($request->hasFile('logo')) {
            $logoName = time() . '_store_logo.' . $request->logo->extension();
            $request->logo->move(public_path('uploads/stores'), $logoName);
            $store->logo = $logoName;
        }

        if ($request->hasFile('banner')) {
            $bannerName = time() . '_store_banner.' . $request->banner->extension();
            $request->banner->move(public_path('uploads/stores'), $bannerName);
            $store->banner = $bannerName;
        }

        $store->status = 'active';
        $store->save();

        return response()->json(['success' => true, 'message' => 'Profil toko berhasil disimpan', 'data' => $store]);
    }

    public function storeDetail($slug)
    {
        $store = StoreProfile::withCount('products')->where('slug', $slug)->firstOrFail();
        $products = Product::with(['category', 'brand', 'variations'])->where('user_id', $store->user_id)->latest()->get();

        return response()->json(['success' => true, 'data' => ['store' => $store, 'products' => $products]]);
    }

    public function sellerOrders(Request $request)
    {
        $orders = Order::with(['items.product'])
            ->where(function ($query) use ($request) {
                $query->where('seller_id', $request->user()->id)
                    ->orWhereHas('items.product', fn ($q) => $q->where('user_id', $request->user()->id));
            })
            ->latest()
            ->get();

        return response()->json(['success' => true, 'data' => $orders]);
    }

    public function updateSellerOrderStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required|string']);

        $order = Order::where(function ($query) use ($request) {
            $query->where('seller_id', $request->user()->id)
                ->orWhereHas('items.product', fn ($q) => $q->where('user_id', $request->user()->id));
        })->findOrFail($id);

        $order->status = $request->status;
        $order->save();

        return response()->json(['success' => true, 'message' => 'Status pesanan berhasil diperbarui', 'data' => $order]);
    }

    public function productReviews($productId)
    {
        $reviews = ProductReview::with('user:id,name')->where('product_id', $productId)->latest()->get();
        $average = round((float) ProductReview::where('product_id', $productId)->avg('rating'), 2);

        return response()->json(['success' => true, 'average' => $average, 'data' => $reviews]);
    }

    public function addReview(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'rating' => 'required|integer|min:1|max:5',
            'review' => 'nullable|string',
        ]);

        $product = Product::findOrFail($request->product_id);
        $store = StoreProfile::where('user_id', $product->user_id)->first();

        $review = ProductReview::updateOrCreate(
            ['product_id' => $product->id, 'user_id' => $request->user()->id, 'order_id' => $request->order_id],
            ['store_id' => $store?->id, 'rating' => $request->rating, 'review' => $request->review]
        );

        if ($store) {
            $store->rating_average = round((float) ProductReview::where('store_id', $store->id)->avg('rating'), 2);
            $store->rating_count = ProductReview::where('store_id', $store->id)->count();
            $store->save();
        }

        return response()->json(['success' => true, 'message' => 'Ulasan berhasil disimpan', 'data' => $review]);
    }

    public function conversations(Request $request)
    {
        $data = Conversation::where('buyer_id', $request->user()->id)
            ->orWhere('seller_id', $request->user()->id)
            ->latest('last_message_at')
            ->get();

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function startConversation(Request $request)
    {
        $request->validate(['seller_id' => 'required|exists:users,id']);

        $conversation = Conversation::firstOrCreate(
            [
                'buyer_id' => $request->user()->id,
                'seller_id' => $request->seller_id,
                'product_id' => $request->product_id,
            ],
            ['last_message_at' => now()]
        );

        return response()->json(['success' => true, 'data' => $conversation]);
    }

    public function messages(Request $request, $conversationId)
    {
        $conversation = Conversation::where(function ($query) use ($request) {
            $query->where('buyer_id', $request->user()->id)->orWhere('seller_id', $request->user()->id);
        })->findOrFail($conversationId);

        $messages = ConversationMessage::where('conversation_id', $conversation->id)->orderBy('id')->get();
        return response()->json(['success' => true, 'data' => $messages]);
    }

    public function sendMessage(Request $request, $conversationId)
    {
        $request->validate(['message' => 'required|string']);

        $conversation = Conversation::where(function ($query) use ($request) {
            $query->where('buyer_id', $request->user()->id)->orWhere('seller_id', $request->user()->id);
        })->findOrFail($conversationId);

        $message = ConversationMessage::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $request->user()->id,
            'message' => $request->message,
        ]);

        $conversation->last_message = $request->message;
        $conversation->last_message_at = now();
        $conversation->save();

        return response()->json(['success' => true, 'data' => $message]);
    }
}
