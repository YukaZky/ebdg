<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductReview;
use App\Models\StoreProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class ApiMarketplaceReviewController extends Controller
{
    private function productReviewQuery(?int $productId = null)
    {
        $query = ProductReview::with(['user:id,name', 'product:id,name'])->latest();
        if ($productId) $query->where('product_id', $productId);
        return $query;
    }

    private function storeReviewQuery(int $storeId)
    {
        if (! Schema::hasTable('store_reviews')) return collect();

        return DB::table('store_reviews')
            ->leftJoin('users', 'users.id', '=', 'store_reviews.user_id')
            ->where('store_reviews.store_id', $storeId)
            ->orderByDesc('store_reviews.id')
            ->select('store_reviews.*', 'users.name as user_name')
            ->get()
            ->map(fn ($item) => [
                'id' => $item->id,
                'store_id' => $item->store_id,
                'user_id' => $item->user_id,
                'rating' => (int) $item->rating,
                'review' => $item->review,
                'created_at' => $item->created_at,
                'updated_at' => $item->updated_at,
                'user' => ['id' => $item->user_id, 'name' => $item->user_name ?: 'Pengulas'],
            ]);
    }

    private function refreshStoreRating(StoreProfile $store): void
    {
        if (! Schema::hasTable('store_reviews')) return;
        $query = DB::table('store_reviews')->where('store_id', $store->id);
        $store->rating_average = round((float) $query->avg('rating'), 2);
        $store->rating_count = (clone $query)->count();
        $store->save();
    }

    public function productReviews($productId)
    {
        $reviews = $this->productReviewQuery((int) $productId)->get();
        $average = round((float) ProductReview::where('product_id', $productId)->avg('rating'), 2);
        $count = ProductReview::where('product_id', $productId)->count();

        return response()->json(['success' => true, 'average' => $average, 'count' => $count, 'data' => $reviews]);
    }

    public function addProductReview(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'order_id' => 'nullable|exists:orders,id',
            'rating' => 'required|integer|min:1|max:5',
            'review' => 'nullable|string|max:1000',
        ]);

        $product = Product::findOrFail($request->product_id);
        $store = StoreProfile::firstOrCreate(
            ['user_id' => $product->user_id],
            ['name' => 'Store', 'slug' => Str::slug('store-' . $product->user_id), 'status' => 'active']
        );

        $where = ['product_id' => $product->id, 'user_id' => $request->user()->id];
        $where['order_id'] = $request->filled('order_id') ? $request->order_id : null;

        $review = ProductReview::updateOrCreate(
            $where,
            ['store_id' => $store->id, 'rating' => (int) $request->rating, 'review' => $request->review]
        );

        return response()->json(['success' => true, 'message' => 'Ulasan produk berhasil disimpan.', 'data' => $review->load(['user:id,name', 'product:id,name'])], 200);
    }

    public function storeReviews($slug)
    {
        $store = StoreProfile::where('slug', $slug)->firstOrFail();
        $this->refreshStoreRating($store);
        $store = $store->fresh();

        return response()->json([
            'success' => true,
            'average' => (float) $store->rating_average,
            'count' => (int) $store->rating_count,
            'data' => $this->storeReviewQuery($store->id),
        ]);
    }

    public function addStoreReview(Request $request, $id)
    {
        $request->validate(['rating' => 'required|integer|min:1|max:5', 'review' => 'nullable|string|max:1000']);

        if (! Schema::hasTable('store_reviews')) {
            return response()->json(['success' => false, 'message' => 'Tabel store_reviews belum tersedia. Jalankan migration.'], 422);
        }

        $store = StoreProfile::findOrFail($id);
        if ((int) $store->user_id === (int) $request->user()->id) {
            return response()->json(['success' => false, 'message' => 'Tidak bisa memberi ulasan ke toko sendiri.'], 422);
        }

        $existing = DB::table('store_reviews')->where('store_id', $store->id)->where('user_id', $request->user()->id)->first();
        $payload = ['rating' => (int) $request->rating, 'review' => $request->review, 'updated_at' => now()];

        if ($existing) {
            DB::table('store_reviews')->where('id', $existing->id)->update($payload);
        } else {
            $payload['store_id'] = $store->id;
            $payload['user_id'] = $request->user()->id;
            $payload['created_at'] = now();
            DB::table('store_reviews')->insert($payload);
        }

        $this->refreshStoreRating($store);
        $store = $store->fresh();

        return response()->json([
            'success' => true,
            'message' => 'Ulasan toko berhasil disimpan.',
            'average' => (float) $store->rating_average,
            'count' => (int) $store->rating_count,
            'data' => $this->storeReviewQuery($store->id),
        ], 200);
    }
}
