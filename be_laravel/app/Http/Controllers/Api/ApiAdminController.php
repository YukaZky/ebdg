<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;
use App\Models\ProductVariation; 
use App\Models\Order;
use App\Models\Category;
use App\Models\Brand;
use App\Models\Coupon;
use App\Models\Slide;
use App\Models\Contact;
use App\Models\WhatsappSetting;
use App\Models\About;
use Illuminate\Support\Str;

class ApiAdminController extends Controller
{
    // ==========================================
    // 1. STATISTIK DASHBOARD
    // ==========================================
    public function dashboardStats()
    {
        $userId = auth()->id();

        return response()->json([
            'status' => 'success',
            'total_products' => Product::where('user_id', $userId)->count(),
            'new_orders' => Order::where('status', 'ordered')->where('user_id', $userId)->count(),
            'total_categories' => Category::where('user_id', $userId)->count(),
            'total_coupons' => Coupon::count(), 
            'total_sales' => Order::where('status', 'delivered')->where('user_id', $userId)->sum('total'),
            'unread_messages' => Contact::whereNull('read_at')->count(), 
        ], 200);
    }

    // ==========================================
    // 2. MANAJEMEN PRODUK (CRUD)
    // ==========================================
    public function getProducts()
    {
        $products = Product::with(['category', 'brand', 'variations'])
                    ->where('user_id', auth()->id())
                    ->latest()
                    ->get();

        foreach ($products as $product) {
            $product->images = \Illuminate\Support\Facades\DB::table('product_images')
                                ->where('product_id', $product->id)
                                ->get();
        }

        return response()->json([
            'status' => 'success', 
            'data' => $products
        ], 200);
    }

    public function storeProduct(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'regular_price' => 'required|numeric',
            'category_id' => 'required|exists:categories,id',
            'brand_id' => 'required|exists:brands,id',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048', 
        ]);

        $product = new Product();
        $product->user_id = auth()->id();
        $product->name = $request->name;
        $product->slug = \Illuminate\Support\Str::slug($request->name);
        $product->short_description = $request->short_description;
        $product->description = $request->description;
        $product->regular_price = $request->regular_price;
        $product->sale_price = $request->sale_price;
        $product->SKU = 'PRD' . time();
        $product->stock_status = $request->stock_status;
        $product->quantity = $request->quantity ?? '0'; 
        $product->weight = $request->weight ?? '0'; 
        $product->exp_date = $request->exp_date;
        $product->category_id = $request->category_id;
        $product->brand_id = $request->brand_id;

        if ($request->hasFile('image')) {
            $imageName = time() . '.' . $request->image->extension();
            $request->image->move(public_path('uploads/products'), $imageName);
            $product->image = $imageName;
        }

        $product->save();

        if ($request->has('variation_names')) {
            $names = $request->variation_names;
            $regularPrices = $request->variation_regular_prices ?? [];
            $salePrices = $request->variation_sale_prices ?? [];
            $weights = $request->variation_weights ?? [];
            $quantities = $request->variation_quantities ?? [];

            foreach ($names as $index => $name) {
                if (empty($name)) continue;

                $variation = new ProductVariation();
                $variation->product_id = $product->id;
                $variation->name = $name;
                $variation->regular_price = isset($regularPrices[$index]) && $regularPrices[$index] !== '' ? $regularPrices[$index] : 0;
                $variation->sale_price = isset($salePrices[$index]) && $salePrices[$index] !== '' ? $salePrices[$index] : null;
                $variation->weight = isset($weights[$index]) && $weights[$index] !== '' ? $weights[$index] : 0;
                $variation->quantity = isset($quantities[$index]) && $quantities[$index] !== '' ? $quantities[$index] : 0;

                if ($request->hasFile("variation_images.$index")) {
                    $varImage = $request->file("variation_images.$index");
                    $varImageName = time() . "_var_$index." . $varImage->extension();
                    $varImage->move(public_path('uploads/products'), $varImageName);
                    $variation->image = $varImageName;
                }
                $variation->save();
            }
        }

        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $file) {
                $galleryImageName = time() . '_' . uniqid() . '.' . $file->extension();
                $file->move(public_path('uploads/products'), $galleryImageName);

                \Illuminate\Support\Facades\DB::table('product_images')->insert([
                    'product_id' => $product->id,
                    'image' => $galleryImageName,
                ]);
            }
        }

        return response()->json(['message' => 'Product created successfully!', 'data' => $product], 201);
    }

    public function updateProduct(Request $request, $id)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'regular_price' => 'required|numeric',
            'category_id' => 'required|exists:categories,id',
            'brand_id' => 'required|exists:brands,id',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048', 
        ]);

        $product = Product::findOrFail($id);

        $product->name = $request->name;
        $product->slug = \Illuminate\Support\Str::slug($request->name);
        $product->short_description = $request->short_description;
        $product->description = $request->description;
        $product->regular_price = $request->regular_price;
        $product->sale_price = $request->sale_price;
        $product->SKU = 'PRD' . time();
        $product->stock_status = $request->stock_status;
        $product->quantity = $request->quantity ?? '0'; 
        $product->weight = $request->weight ?? '0'; 
        $product->exp_date = $request->exp_date;
        $product->category_id = $request->category_id;
        $product->brand_id = $request->brand_id;

        if ($request->hasFile('image')) {
            if ($product->image && \Illuminate\Support\Facades\File::exists(public_path('uploads/products/' . $product->image))) {
                \Illuminate\Support\Facades\File::delete(public_path('uploads/products/' . $product->image));
            }
            $imageName = time() . '.' . $request->image->extension();
            $request->image->move(public_path('uploads/products'), $imageName);
            $product->image = $imageName;
        }

        $product->save();

        if ($request->has('variation_names')) {
            $names = $request->variation_names;
            $ids = $request->variation_ids ?? [];
            $regularPrices = $request->variation_regular_prices ?? [];
            $salePrices = $request->variation_sale_prices ?? [];
            $weights = $request->variation_weights ?? [];
            $quantities = $request->variation_quantities ?? [];

            $receivedVariationIds = array_filter($ids); 

            $product->variations()->whereNotIn('id', $receivedVariationIds)->delete();

            foreach ($names as $index => $name) {
                if (empty($name)) continue;

                $variationId = $ids[$index] ?? null;

                if ($variationId) {
                    $variation = ProductVariation::find($variationId);
                } else {
                    $variation = new ProductVariation();
                    $variation->product_id = $product->id;
                }

                if ($variation) {
                    $variation->name = $name;
                    $variation->regular_price = isset($regularPrices[$index]) && $regularPrices[$index] !== '' ? $regularPrices[$index] : 0;
                    $variation->sale_price = isset($salePrices[$index]) && $salePrices[$index] !== '' ? $salePrices[$index] : null;
                    $variation->weight = isset($weights[$index]) && $weights[$index] !== '' ? $weights[$index] : 0;
                    $variation->quantity = isset($quantities[$index]) && $quantities[$index] !== '' ? $quantities[$index] : 0;

                    if ($request->hasFile("variation_images.$index")) {
                        if ($variation->image && \Illuminate\Support\Facades\File::exists(public_path('uploads/products/' . $variation->image))) {
                            \Illuminate\Support\Facades\File::delete(public_path('uploads/products/' . $variation->image));
                        }
                        $varImage = $request->file("variation_images.$index");
                        $varImageName = time() . "_var_$index." . $varImage->extension();
                        $varImage->move(public_path('uploads/products'), $varImageName);
                        $variation->image = $varImageName;
                    }

                    $variation->save();
                }
            }
        } else {
            $product->variations()->delete();
        }

        // ===============================================
        // MENGHAPUS GAMBAR GALERI LAMA YANG DI-X OLEH USER
        // ===============================================
        if ($request->has('kept_gallery_ids')) {
            $keptIds = $request->kept_gallery_ids;
            $imagesToDelete = \Illuminate\Support\Facades\DB::table('product_images')
                ->where('product_id', $product->id)
                ->whereNotIn('id', $keptIds)
                ->get();
        } else if ($request->has('kept_gallery_ids_empty')) {
            $imagesToDelete = \Illuminate\Support\Facades\DB::table('product_images')
                ->where('product_id', $product->id)
                ->get();
        } else {
            $imagesToDelete = []; 
        }

        if (!empty($imagesToDelete)) {
            foreach($imagesToDelete as $img) {
                if (\Illuminate\Support\Facades\File::exists(public_path('uploads/products/' . $img->image))) {
                    \Illuminate\Support\Facades\File::delete(public_path('uploads/products/' . $img->image));
                }
                \Illuminate\Support\Facades\DB::table('product_images')->where('id', $img->id)->delete();
            }
        }

        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $file) {
                $galleryImageName = time() . '_' . uniqid() . '.' . $file->extension();
                $file->move(public_path('uploads/products'), $galleryImageName);

                \Illuminate\Support\Facades\DB::table('product_images')->insert([
                    'product_id' => $product->id,
                    'image' => $galleryImageName,
                ]);
            }
        }

        return response()->json(['message' => 'Product updated successfully!', 'data' => $product]);
    }

    public function deleteProduct($id)
    {
        Product::where('user_id', auth()->id())->findOrFail($id)->delete();
        return response()->json(['status' => 'success', 'message' => 'Produk berhasil dihapus'], 200);
    }

    // ==========================================
    // 3. KATEGORI & BRAND
    // ==========================================
    public function getCategories() 
    { 
        return response()->json(['data' => Category::where('user_id', auth()->id())->latest()->get()], 200); 
    }

    public function storeCategory(Request $request)
    {
        $request->validate(['name' => 'required|string']);
        $category = new Category();
        $category->user_id = auth()->id();
        $category->name = $request->name;
        $category->slug = Str::slug($request->name);
        
        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $file_name = time() . '.' . $image->extension();
            $image->move(public_path('uploads/categories'), $file_name);
            $category->image = $file_name;
        }
        $category->save();

        return response()->json(['status' => 'success', 'message' => 'Kategori berhasil ditambahkan', 'data' => $category], 201);
    }

    public function updateCategory(Request $request, $id)
    {
        $category = Category::where('user_id', auth()->id())->findOrFail($id);
        $category->name = $request->name ?? $category->name;
        $category->slug = Str::slug($category->name);

        if ($request->hasFile('image')) {
            if ($category->image && file_exists(public_path('uploads/categories/' . $category->image))) {
                unlink(public_path('uploads/categories/' . $category->image));
            }
            $image = $request->file('image');
            $file_name = time() . '.' . $image->extension();
            $image->move(public_path('uploads/categories'), $file_name);
            $category->image = $file_name;
        }
        $category->save();

        return response()->json(['status' => 'success', 'message' => 'Kategori berhasil diupdate', 'data' => $category]);
    }

    public function deleteCategory($id)
    {
        $category = Category::where('user_id', auth()->id())->findOrFail($id);
        if ($category->image && file_exists(public_path('uploads/categories/' . $category->image))) {
            unlink(public_path('uploads/categories/' . $category->image));
        }
        $category->delete();
        return response()->json(['status' => 'success', 'message' => 'Kategori berhasil dihapus']);
    }

    public function getBrands() 
    { 
        return response()->json(['data' => Brand::where('user_id', auth()->id())->latest()->get()], 200); 
    }

    public function storeBrand(Request $request)
    {
        $request->validate(['name' => 'required|string']);
        $brand = new Brand();
        $brand->user_id = auth()->id();
        $brand->name = $request->name;
        $brand->slug = Str::slug($request->name);
        
        if ($request->has('category_id')) {
            $brand->category_id = $request->category_id;
        }
        
        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $file_name = time() . '.' . $image->extension();
            $image->move(public_path('uploads/brands'), $file_name);
            $brand->image = $file_name;
        }
        $brand->save();

        return response()->json(['status' => 'success', 'message' => 'Brand berhasil ditambahkan', 'data' => $brand], 201);
    }

    public function updateBrand(Request $request, $id)
    {
        $brand = Brand::where('user_id', auth()->id())->findOrFail($id);
        $brand->name = $request->name ?? $brand->name;
        $brand->slug = Str::slug($brand->name);
        
        if ($request->has('category_id')) {
            $brand->category_id = $request->category_id;
        }

        if ($request->hasFile('image')) {
            if ($brand->image && file_exists(public_path('uploads/brands/' . $brand->image))) {
                unlink(public_path('uploads/brands/' . $brand->image));
            }
            $image = $request->file('image');
            $file_name = time() . '.' . $image->extension();
            $image->move(public_path('uploads/brands'), $file_name);
            $brand->image = $file_name;
        }
        $brand->save();

        return response()->json(['status' => 'success', 'message' => 'Brand berhasil diupdate']);
    }

    public function deleteBrand($id)
    {
        $brand = Brand::where('user_id', auth()->id())->findOrFail($id);
        if ($brand->image && file_exists(public_path('uploads/brands/' . $brand->image))) {
            unlink(public_path('uploads/brands/' . $brand->image));
        }
        $brand->delete();
        return response()->json(['status' => 'success', 'message' => 'Brand berhasil dihapus']);
    }

    // ==========================================
    // 4. MANAJEMEN PESANAN
    // ==========================================
    public function getOrders()
    {
        return response()->json(['status' => 'success', 'data' => Order::where('user_id', auth()->id())->latest()->get()], 200);
    }

    public function getOrderDetail($id)
    {
        $order = Order::with(['orderItems.product', 'transaction'])->where('user_id', auth()->id())->findOrFail($id);
        return response()->json(['status' => 'success', 'data' => $order], 200);
    }

    public function updateOrderStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required']);
        $order = Order::where('user_id', auth()->id())->findOrFail($id);
        $order->status = $request->status;
        
        if($request->status == 'delivered') {
            $order->delivered_date = now();
        } elseif($request->status == 'canceled') {
            $order->canceled_date = now();
        }
        $order->save();

        return response()->json(['status' => 'success', 'message' => 'Status pesanan diperbarui'], 200);
    }

    // ==========================================
    // 5. MANAJEMEN KUPON
    // ==========================================
    public function getCoupons() 
    { 
        return response()->json(['data' => Coupon::all()], 200); 
    }
    
    public function storeCoupon(Request $request)
    {
        $coupon = Coupon::create($request->all());
        return response()->json(['status' => 'success', 'data' => $coupon], 201);
    }

    public function deleteCoupon($id)
    {
        Coupon::findOrFail($id)->delete();
        return response()->json(['status' => 'success'], 200);
    }

    // ==========================================
    // 6. FITUR LAIN (SLIDE, KONTAK, SETTING WA)
    // ==========================================
    public function getSlides() 
    { 
        return response()->json(['data' => Slide::all()], 200); 
    }
    
    public function getContacts() 
    { 
        return response()->json(['data' => Contact::latest()->get()], 200); 
    }
    
    public function markContactRead($id) 
    {
        $contact = Contact::findOrFail($id);
        $contact->read_at = now();
        $contact->save();
        return response()->json(['status' => 'success']);
    }
    
    public function getWhatsappSettings() 
    { 
        return response()->json(['data' => WhatsappSetting::first()], 200); 
    }

    // ==========================================
    // 7. MANAJEMEN LOKASI TOKO (ORIGIN)
    // ==========================================
    public function getStoreLocation()
    {
        $about = About::firstOrCreate(['user_id' => auth()->id()]);
        return response()->json([
            'status' => 'success',
            'data' => [
                'province_id' => $about->province_id,
                'city_id' => $about->city_id,
            ]
        ], 200);
    }

    public function saveStoreLocation(Request $request)
    {
        $request->validate([
            'province_id' => 'required',
            'city_id' => 'required',
        ]);

        $about = About::firstOrCreate(['user_id' => auth()->id()]);
        $about->province_id = $request->province_id;
        $about->city_id = $request->city_id;
        $about->district_id = null; // Reset jika lokasi berubah
        $about->save();

        return response()->json(['status' => 'success', 'message' => 'Lokasi toko berhasil diperbarui'], 200);
    }
}