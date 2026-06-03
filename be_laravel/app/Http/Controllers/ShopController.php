<?php

namespace App\Http\Controllers;

use App\Models\Brand;
use App\Models\Category;
use App\Models\Product;
use App\Models\Wishlist; // --- TAMBAHAN UNTUK OPTIMASI WISHLIST ---
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth; // --- TAMBAHAN UNTUK OPTIMASI WISHLIST ---

class ShopController extends Controller
{
    public function index(Request $request)
    {
        // 1. Ambil input filter dari request
        $size = $request->query('size', 12);
        $order = $request->query('order', -1);
        $f_brands = $request->query('brands');
        $f_categories = $request->query('categories');
        
        // Ambil nilai min dan max untuk ditampilkan kembali di input filter
        $min_price = $request->query('min'); 
        $max_price = $request->query('max');

        // 2. Tentukan kolom dan urutan sorting
        $sortMap = [
            1 => ['created_at', 'DESC'],
            2 => ['created_at', 'ASC'],
            3 => ['sale_price', 'DESC'],
            4 => ['sale_price', 'ASC'],
        ];
        [$o_column, $o_order] = $sortMap[$order] ?? ['created_at', 'DESC'];

        // 3. Bangun query produk
        $products = Product::query()
            ->where('stock_status', 'instock')
            ->with('category')
            ->when($f_brands, function ($query, $f_brands) {
                return $query->whereIn('brand_id', explode(',', $f_brands));
            })
            ->when($f_categories, function ($query, $f_categories) {
                return $query->whereIn('category_id', explode(',', $f_categories));
            })
            ->when($request->has('min') && $request->has('max') && $request->min != null && $request->max != null, function ($query) use ($request) {
                return $query->where(function ($q) use ($request) {
                    $q->whereBetween('regular_price', [$request->min, $request->max])
                      ->orWhereBetween('sale_price', [$request->min, $request->max]);
                });
            })
            ->orderBy($o_column, $o_order)
            ->paginate($size);

        // Ambil data brand dan kategori untuk sidebar
        $brands = Brand::withCount('products')->orderBy('name', 'ASC')->get();
        $categories = Category::withCount('products')->orderBy('name', 'ASC')->get();

        // --- TAMBAHAN UNTUK OPTIMASI WISHLIST ---
        // Ambil semua ID produk yang ada di wishlist pengguna dalam satu kueri
        $wishlistedProductIds = [];
        if (Auth::check()) {
            $wishlistedProductIds = Wishlist::where('user_id', Auth::id())->pluck('product_id')->toArray();
        }
        // --- AKHIR DARI TAMBAHAN ---

        // 4. Kirim data ke view
        return view('shop', [
            'products' => $products,
            'size' => $size,
            'order' => $order,
            'f_brands' => $f_brands,
            'brands' => $brands,
            'f_categories' => $f_categories,
            'categories' => $categories,
            'min_price' => $min_price,
            'max_price' => $max_price,
            'wishlistedProductIds' => $wishlistedProductIds, // Kirim data wishlist ke view
        ]);
    }

    public function search(Request $request)
    {
        // 1. Ambil query pencarian dari request
        $query = $request->input('q');

        // 2. Jika query kosong, redirect kembali ke halaman shop
        if (!$query) {
            return redirect()->route('shop.index');
        }

        // 3. Cari produk berdasarkan nama yang cocok (LIKE)
        // Gunakan pagination dan withQueryString agar link pagination tetap membawa query pencarian
        $products = Product::where('name', 'LIKE', "%{$query}%")
            ->where('stock_status', 'instock')
            ->orderBy('created_at', 'DESC')
            ->paginate(12)
            ->withQueryString();

        // 4. Kirim data produk dan query ke view 'search'
        return view('search', [
            'products' => $products,
            'query' => $query,
        ]);
    }
    
    public function product_details($product_slug)
    {
        $product = Product::where('slug', $product_slug)->with('category')->firstOrFail();
        $related_products = Product::where('category_id', $product->category_id)
                                        ->where('slug', '!=', $product_slug)
                                        ->inRandomOrder()
                                        ->limit(8)
                                        ->get();
        $prev_product = Product::where('id', '<', $product->id)->orderBy('id', 'desc')->first();
        $next_product = Product::where('id', '>', $product->id)->orderBy('id', 'asc')->first();

        return view('details', compact('product', 'related_products', 'prev_product', 'next_product'));
    }
}
