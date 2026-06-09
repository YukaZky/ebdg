<?php

namespace App\Http\Controllers;

use App\Models\Brand;
use App\Models\Category;
use App\Models\Product;
use App\Models\Wishlist;
use App\Models\User; // --- TAMBAHAN UNTUK MEMANGGIL DATA PENJUAL ---
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ShopController extends Controller
{
    public function index(Request $request)
    {
        // 1. Ambil input filter dari request
        $size = $request->query('size', 12);
        $order = $request->query('order', -1);
        $f_brands = $request->query('brands');
        $f_categories = $request->query('categories');
        
        // --- TAMBAHAN MARKETPLACE: Filter berdasarkan ID Toko/Penjual ---
        $f_seller = $request->query('seller_id'); 

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
            ->with(['category', 'user']) // <-- UBAH DI SINI: Panggil relasi 'user' (penjual)
            ->when($f_brands, function ($query, $f_brands) {
                return $query->whereIn('brand_id', explode(',', $f_brands));
            })
            ->when($f_categories, function ($query, $f_categories) {
                return $query->whereIn('category_id', explode(',', $f_categories));
            })
            // --- TAMBAHAN MARKETPLACE: Jalankan filter toko jika dipilih ---
            ->when($f_seller, function ($query, $f_seller) {
                return $query->where('user_id', $f_seller);
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
        
        // --- TAMBAHAN MARKETPLACE: Ambil daftar penjual yang memiliki produk untuk opsi filter di sidebar ---
        $sellers = User::has('products')->orderBy('name', 'ASC')->get();

        // Ambil semua ID produk yang ada di wishlist pengguna dalam satu kueri
        $wishlistedProductIds = [];
        if (Auth::check()) {
            $wishlistedProductIds = Wishlist::where('user_id', Auth::id())->pluck('product_id')->toArray();
        }

        // 4. Kirim data ke view
        return view('shop', [
            'products' => $products,
            'size' => $size,
            'order' => $order,
            'f_brands' => $f_brands,
            'brands' => $brands,
            'f_categories' => $f_categories,
            'categories' => $categories,
            'f_seller' => $f_seller, // Kirim filter seller ke view
            'sellers' => $sellers,   // Kirim daftar penjual ke view
            'min_price' => $min_price,
            'max_price' => $max_price,
            'wishlistedProductIds' => $wishlistedProductIds, 
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
        $products = Product::where('name', 'LIKE', "%{$query}%")
            ->where('stock_status', 'instock')
            ->with(['category', 'user']) // <-- UBAH DI SINI: Panggil relasi penjual juga saat search
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
        // <-- UBAH DI SINI: Sertakan 'user' (penjual) saat melihat detail
        $product = Product::where('slug', $product_slug)->with(['category', 'user'])->firstOrFail();
        
        // Produk terkait berdasarkan kategori
        $related_products = Product::where('category_id', $product->category_id)
                                        ->where('slug', '!=', $product_slug)
                                        ->inRandomOrder()
                                        ->limit(8)
                                        ->get();

        // --- TAMBAHAN MARKETPLACE: Memunculkan "Produk Lain dari Toko Ini" ---
        $more_from_seller = Product::where('user_id', $product->user_id)
                                        ->where('id', '!=', $product->id)
                                        ->inRandomOrder()
                                        ->limit(4)
                                        ->get();

        $prev_product = Product::where('id', '<', $product->id)->orderBy('id', 'desc')->first();
        $next_product = Product::where('id', '>', $product->id)->orderBy('id', 'asc')->first();

        // Kirim $more_from_seller ke view details
        return view('details', compact('product', 'related_products', 'more_from_seller', 'prev_product', 'next_product'));
    }
}