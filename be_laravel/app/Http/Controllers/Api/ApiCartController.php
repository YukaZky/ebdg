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

    private function currentPrice(Product $product, ?ProductVariation $variation = null)
    {
        if ($variation) {
            return $variation->sale_price ?: $variation->regular_price ?: 0;
        }

        return $product->sale_price ?: $product->regular_price ?: 0;
    }

    private function currentImage(Product $product, ?ProductVariation $variation = null): ?string
    {
        if ($variation && ! empty($variation->image)) {
            return $variation->image;
        }

        return $this->productCoverImage($product);
    }

    private function currentWeight(Product $product, ?ProductVariation $variation = null): int
    {
        return (int) ($variation ? ($variation->weight ?? 0) : ($product->weight ?? 0));
    }

    private function syncCartItemSnapshot(CartItem $item): void
    {
        if (! $item->product) return;

        $product = $item->product;
        $variation = $item->variation;

        $item->price = $this->currentPrice($product, $variation);
        $item->variation_name = $variation?->name;
        $item->selected_image = $this->currentImage($product, $variation);
        $item->weight = $this->currentWeight($product, $variation);
        $item->save();
    }

    public function index(Request $request)
    {
        $cartItems = CartItem::with(['product.store', 'product.user:id,name', 'variation'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        $total = 0;
        foreach ($cartItems as $item) {
            $this->syncCartItemSnapshot($item);
            $item->refresh()->load(['product.store', 'product.user:id,name', 'variation']);
            $total += $item->price * $item->quantity;

            if ($item->product) {
                $store = $item->product->store;
                $seller = $item->product->user;
                $item->seller_id = (int) $item->product->user_id;
                $storeName = $store?->name ?: ($seller?->name ? $seller->name . ' Store' : 'Toko Penjual');
                $storeId = $store?->id ?: 'seller_' . ($item->product->user_id ?? 'unknown');

                $item->product->store_name = $storeName;
                $item->product->store_key = (string) $storeId;
                $item->product->seller_name = $seller?->name;
            }
        }

        return response()
            ->json(['success' => true, 'data' => $cartItems, 'total' => $total], 200)
            ->header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
            ->header('Pragma', 'no-cache')
            ->header('Expires', '0');
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

        $availableStock = $variation ? (int) $variation->quantity : (int) $product->quantity;
        if ((string) $product->stock_status !== 'instock' || $availableStock <= 0) {
            return response()->json(['success' => false, 'message' => 'Stok produk habis.'], 422);
        }

        $cartItemQuery = CartItem::where('user_id', $user->id)
            ->where('product_id', $product->id);

        if ($variation) {
            $cartItemQuery->where('variation_id', $variation->id);
        } else {
            $cartItemQuery->whereNull('variation_id');
        }

        $cartItem = $cartItemQuery->first();
        $existingQty = $cartItem ? (int) $cartItem->quantity : 0;
        $requestedQty = (int) $request->quantity;

        if (($existingQty + $requestedQty) > $availableStock) {
            return response()->json([
                'success' => false,
                'message' => 'Jumlah produk di keranjang melebihi stok tersedia. Sisa stok: ' . $availableStock,
            ], 422);
        }

        $selectedPrice = $this->currentPrice($product, $variation);
        $selectedImage = $this->currentImage($product, $variation);
        $selectedWeight = $this->currentWeight($product, $variation);

        if ($cartItem) {
            $cartItem->quantity += $requestedQty;
            $cartItem->price = $selectedPrice;
            $cartItem->variation_name = $variation?->name;
            $cartItem->selected_image = $selectedImage;
            $cartItem->weight = $selectedWeight;
            $cartItem->save();
        } else {
            $cartItem = CartItem::create([
                'user_id' => $user->id,
                'product_id' => $product->id,
                'variation_id' => $variation?->id,
                'variation_name' => $variation?->name,
                'quantity' => $requestedQty,
                'price' => $selectedPrice,
                'selected_image' => $selectedImage,
                'weight' => $selectedWeight,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Produk berhasil ditambahkan ke keranjang',
            'data' => $cartItem->fresh(),
        ], 200);
    }

    public function updateQuantity(Request $request, $id)
    {
        $request->validate([
            'quantity' => 'required|integer|min:1',
        ]);

        $cartItem = CartItem::with(['product', 'variation'])
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$cartItem) {
            return response()->json([
                'success' => false,
                'message' => 'Item tidak ditemukan',
            ], 404);
        }

        $availableStock = $cartItem->variation
            ? (int) $cartItem->variation->quantity
            : (int) ($cartItem->product->quantity ?? 0);

        if ((int) $request->quantity > $availableStock) {
            return response()->json([
                'success' => false,
                'message' => 'Jumlah produk melebihi stok tersedia. Sisa stok: ' . $availableStock,
            ], 422);
        }

        $cartItem->quantity = (int) $request->quantity;
        $this->syncCartItemSnapshot($cartItem);

        return response()->json([
            'success' => true,
            'message' => 'Jumlah produk berhasil diperbarui',
            'data' => $cartItem->fresh(['product', 'variation']),
        ], 200);
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
