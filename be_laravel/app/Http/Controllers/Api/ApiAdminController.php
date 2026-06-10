<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;
use App\Models\ProductVariation; // Tambahkan import model variasi
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
    // 1. STATISTIK DASHBOARD
    public function dashboardStats()
    {
        $userId = auth()->id();

        return response()->json([
            'status' => 'success',
            'total_products' => Product::where('user_id', $userId)->count(),
            'new_orders' => Order::where('status', 'ordered')->where('user_id', $userId)->count(),
            'total_categories' => Category::where('user_id', $userId)->count(),
            'total_coupons' => Coupon::count(), // Kupon tetap global
            'total_sales' => Order::where('status', 'delivered')->where('user_id', $userId)->sum('total'),
            'unread_messages' => Contact::whereNull('read_at')->count(), // Pesan kontak tetap global
        ], 200);
    }

    // 2. MANAJEMEN PRODUK (CRUD)
    public function getProducts()
    {
        return response()->json([
            'status' => 'success', 
            // Tambahkan 'variations' ke dalam with() agar form edit bisa membacanya
            'data' => Product::with(['category', 'brand', 'variations'])->where('user_id', auth()->id())->latest()->get()
        ], 200);
    }

    public function storeProduct(Request $request)
    {
        // --- PROSES SIMPAN / UPDATE VARIASI PRODUK ---
        if ($request->has('variation_names')) {
            // JIKA UPDATE: Hapus variasi lama terlebih dahulu
            if (isset($id)) {
                \App\Models\ProductVariation::where('product_id', $product->id)->delete();
            }

            $variationNames = $request->input('variation_names');
            $variationDescriptions = $request->input('variation_descriptions');
            $variationPrices = $request->input('variation_prices');
            $variationImages = $request->file('variation_images');

            foreach ($variationNames as $index => $varName) {
                if (!empty($varName)) {
                    $variation = new \App\Models\ProductVariation();
                    $variation->product_id = $product->id;
                    $variation->name = $varName;
                    $variation->description = $variationDescriptions[$index] ?? null;
                    // Pastikan harga tersimpan, jika kosong default ke 0
                    $variation->price = isset($variationPrices[$index]) ? (float)$variationPrices[$index] : 0;

                    if (isset($variationImages[$index])) {
                        $vImage = $variationImages[$index];
                        $vFileName = time() . '-var-' . uniqid() . '.' . $vImage->extension();
                        $vImage->move(public_path('uploads/products'), $vFileName);
                        $variation->image = $vFileName;
                    }
                    $variation->save();
                }
            }
        }

        return response()->json(['status' => 'success', 'message' => 'Produk berhasil ditambahkan', 'data' => $product], 201);
    }

    public function updateProduct(Request $request, $id)
    {
        // --- PROSES SIMPAN / UPDATE VARIASI PRODUK ---
        if ($request->has('variation_names')) {
            // JIKA UPDATE: Hapus variasi lama terlebih dahulu
            if (isset($id)) {
                \App\Models\ProductVariation::where('product_id', $product->id)->delete();
            }

            $variationNames = $request->input('variation_names');
            $variationDescriptions = $request->input('variation_descriptions');
            $variationPrices = $request->input('variation_prices');
            $variationImages = $request->file('variation_images');

            foreach ($variationNames as $index => $varName) {
                if (!empty($varName)) {
                    $variation = new \App\Models\ProductVariation();
                    $variation->product_id = $product->id;
                    $variation->name = $varName;
                    $variation->description = $variationDescriptions[$index] ?? null;
                    // Pastikan harga tersimpan, jika kosong default ke 0
                    $variation->price = isset($variationPrices[$index]) ? (float)$variationPrices[$index] : 0;

                    if (isset($variationImages[$index])) {
                        $vImage = $variationImages[$index];
                        $vFileName = time() . '-var-' . uniqid() . '.' . $vImage->extension();
                        $vImage->move(public_path('uploads/products'), $vFileName);
                        $variation->image = $vFileName;
                    }
                    $variation->save();
                }
            }
        }

        return response()->json(['status' => 'success', 'message' => 'Produk berhasil diperbarui', 'data' => $product], 200);
    }

    public function deleteProduct($id)
    {
        Product::where('user_id', auth()->id())->findOrFail($id)->delete();
        return response()->json(['status' => 'success', 'message' => 'Produk berhasil dihapus'], 200);
    }

    // 3. KATEGORI & BRAND
    public function getCategories() 
    { 
        return response()->json(['data' => Category::where('user_id', auth()->id())->latest()->get()], 200); 
    }

    public function storeCategory(Request $request)
    {
        $request->validate(['name' => 'required|string']);
        $category = new Category();
        $category->user_id = auth()->id(); // Tautkan ke admin
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
        $brand->user_id = auth()->id(); // Tautkan ke admin
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

    // 4. MANAJEMEN PESANAN
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

    // 5. MANAJEMEN KUPON
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

    // 6. FITUR LAIN (SLIDE, KONTAK, SETTING WA)
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

    // 7. MANAJEMEN LOKASI TOKO (ORIGIN)
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