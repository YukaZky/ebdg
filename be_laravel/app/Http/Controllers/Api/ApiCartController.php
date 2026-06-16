<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CartItem;
use App\Models\Product;
use App\Models\ProductVariation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ApiCartController extends Controller
{
    private function productCoverImage(Product $product): ?string
    {
        if (! empty($product->image) && $product->image !== 'null') {
            return $product->image;
        }

        $galleryImage = DB::table('product_images')
            ->where('product_id', $product->id)
            ->orderBy('id', 'asc')
            ->value('image');

        return $galleryImage ?: null;
    }

    public function index(Request $request)
    {
        $cartItems = CartItem::with(['product.store', 'product.user:id,name', 'variation'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        $total = 0;
        foreach ($cartItems as $item) {
            $total += $item->price * $item->quantity;

            if ($item->product) {
                $store = $item->product->store;
                $seller = $item->product->user;
                $storeName = $store?->name ?: ($seller?->name ? $seller->name . ' Store' : 'Toko Penjual');
                $storeId = $store?->id ?: 'seller_' . ($item->product->user_id ?? 'unknown');

                $item->product->store_name = $storeName;
                $item->product->store_key = (string) $storeId;
                $item->product->seller_name = $seller?->name;
            }
        }

        return response()->json(['success' => true, 'data' => $cartItems, 'total' => $total], 200);
    }

    public function add(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'variation_id' => 'nullable|exists:product_variations,id',
            'quantity' => 'required|integer|min:1',
        ]);

        $user = $request->user();
        $product = Product::findOrFail($request->product_id);
        $variation = null;

        if ($request->filled('variation_id')) {
            $variation = ProductVariation::where('product_id', $product->id)
                ->where('id', $request->variation_id)
                ->firstOrFail();
        }

        $selectedPrice = $variation
            ? ($variation->sale_price ?: $variation->regular_price)
            : ($product->sale_price ?: $product->regular_price);

        $selectedImage = $variation && ! empty($variation->image)
            ? $variation->image
            : $this->productCoverImage($product);

        $selectedWeight = $variation
            ? ($variation->weight ?? 0)
            : ($product->weight ?? 0);

        $cartItemQuery = CartItem::where('user_id', $user->id)
            ->where('product_id', $product->id);

        if ($variation) {
            $cartItemQuery->where('variation_id', $variation->id);
        } else {
            $cartItemQuery->whereNull('variation_id');
        }

        $cartItem = $cartItemQuery->first();

        if ($cartItem) {
            $cartItem->quantity += $request->quantity;
            $cartItem->price = $selectedPrice;
            $cartItem->variation_name = $variation?->name;
            $cartItem->selected_image = $selectedImage;
            $cartItem->weight = $selectedWeight;
            $cartItem->save();
        } else {
            CartItem::create([
                'user_id' => $user->id,
                'product_id' => $product->id,
                'variation_id' => $variation?->id,
                'variation_name' => $variation?->name,
                'quantity' => $request->quantity,
                'price' => $selectedPrice,
                'selected_image' => $selectedImage,
                'weight' => $selectedWeight,
            ]);
        }

        return response()->json(['success' => true, 'message' => 'Produk berhasil ditambahkan ke keranjang'], 200);
    }

    public function remove(Request $request, $id)
    {
        $cartItem = CartItem::where('user_id', $request->user()->id)->where('id', $id)->first();
        if ($cartItem) {
            $cartItem->delete();
            return response()->json(['success' => true, 'message' => 'Item dihapus']);
        }
        return response()->json(['success' => false, 'message' => 'Item tidak ditemukan'], 404);
    }
}
