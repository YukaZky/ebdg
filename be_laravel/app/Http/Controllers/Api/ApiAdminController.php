<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;
use App\Models\Order;
use App\Models\Category;
use App\Models\Brand;
use App\Models\Coupon;
use App\Models\Slide;
use App\Models\Contact;
use App\Models\WhatsappSetting;
use Illuminate\Support\Str;

class ApiAdminController extends Controller
{
    // 1. STATISTIK DASHBOARD
    public function dashboardStats()
    {
        return response()->json([
            'status' => 'success',
            'total_products' => Product::count(),
            'new_orders' => Order::where('status', 'ordered')->count(),
            'total_categories' => Category::count(),
            'total_coupons' => Coupon::count(),
            'total_sales' => Order::where('status', 'delivered')->sum('total'),
            'unread_messages' => Contact::whereNull('read_at')->count(),
        ], 200);
    }

    // 2. MANAJEMEN PRODUK (CRUD)
    public function getProducts()
    {
        return response()->json(['status' => 'success', 'data' => Product::with(['category', 'brand'])->latest()->get()], 200);
    }

    public function storeProduct(Request $request)
    {
        $product = new Product();
        $product->name = $request->name;
        $product->slug = Str::slug($request->name) . '-' . time();
        $product->short_description = $request->short_description;
        $product->description = $request->description;
        $product->regular_price = $request->regular_price;
        $product->sale_price = $request->sale_price ?? null;
        $product->SKU = $request->SKU ?? ('SKU-' . Str::upper(Str::random(6)));
        $product->stock_status = $request->stock_status;
        $product->quantity = $request->quantity;
        $product->category_id = $request->category_id;
        $product->brand_id = $request->brand_id;
        $product->weight = $request->weight ?? 0;
        $product->exp_date = $request->exp_date ?? null;

        // Upload Gambar Utama
        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $file_name = time() . '.' . $image->extension();
            $image->move(public_path('uploads/products'), $file_name);
            $product->image = $file_name;
        }

        // Upload Galeri Gambar
        if ($request->hasFile('images')) {
            $gallery_arr = [];
            foreach ($request->file('images') as $file) {
                $gfile_name = time() . '-' . uniqid() . '.' . $file->extension();
                $file->move(public_path('uploads/products'), $gfile_name);
                array_push($gallery_arr, $gfile_name);
            }
            $product->images = implode(',', $gallery_arr);
        }

        $product->save();

        return response()->json(['status' => 'success', 'message' => 'Produk berhasil ditambahkan', 'data' => $product], 201);
    }

    public function updateProduct(Request $request, $id)
    {
        $product = Product::findOrFail($id);
        
        $product->name = $request->name;
        $product->short_description = $request->short_description;
        $product->description = $request->description;
        $product->regular_price = $request->regular_price;
        $product->sale_price = $request->sale_price ?? null;
        $product->stock_status = $request->stock_status;
        $product->quantity = $request->quantity;
        $product->category_id = $request->category_id;
        $product->brand_id = $request->brand_id;
        $product->weight = $request->weight ?? 0;
        $product->exp_date = $request->exp_date ?? null;

        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $file_name = time() . '.' . $image->extension();
            $image->move(public_path('uploads/products'), $file_name);
            $product->image = $file_name;
        }

        if ($request->hasFile('images')) {
            $gallery_arr = [];
            foreach ($request->file('images') as $file) {
                $gfile_name = time() . '-' . uniqid() . '.' . $file->extension();
                $file->move(public_path('uploads/products'), $gfile_name);
                array_push($gallery_arr, $gfile_name);
            }
            $product->images = implode(',', $gallery_arr);
        }

        $product->save();

        return response()->json(['status' => 'success', 'message' => 'Produk berhasil diperbarui', 'data' => $product], 200);
    }

    public function deleteProduct($id)
    {
        Product::findOrFail($id)->delete();
        return response()->json(['status' => 'success', 'message' => 'Produk berhasil dihapus'], 200);
    }

    // ==========================================
    // 3. KATEGORI & BRAND
    // ==========================================
    public function getCategories() 
    { 
        return response()->json(['data' => Category::latest()->get()], 200); 
    }

    public function storeCategory(Request $request)
    {
        $request->validate(['name' => 'required|string']);
        $category = new Category();
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
        $category = Category::findOrFail($id);
        $category->name = $request->name ?? $category->name;
        $category->slug = Str::slug($category->name);

        if ($request->hasFile('image')) {
            // Hapus gambar lama dari folder public/uploads/categories
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
        $category = Category::findOrFail($id);
        // Hapus gambar dari folder public/uploads/categories sebelum data dihapus
        if ($category->image && file_exists(public_path('uploads/categories/' . $category->image))) {
            unlink(public_path('uploads/categories/' . $category->image));
        }
        $category->delete();
        return response()->json(['status' => 'success', 'message' => 'Kategori berhasil dihapus']);
    }

    public function getBrands() 
    { 
        return response()->json(['data' => Brand::latest()->get()], 200); 
    }

    public function storeBrand(Request $request)
    {
        $request->validate(['name' => 'required|string']);
        $brand = new Brand();
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
        $brand = Brand::findOrFail($id);
        $brand->name = $request->name ?? $brand->name;
        $brand->slug = Str::slug($brand->name);
        
        if ($request->has('category_id')) {
            $brand->category_id = $request->category_id;
        }

        if ($request->hasFile('image')) {
            // Hapus gambar lama dari folder public/uploads/brands
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
        $brand = Brand::findOrFail($id);
        // Hapus gambar dari folder public/uploads/brands sebelum data dihapus
        if ($brand->image && file_exists(public_path('uploads/brands/' . $brand->image))) {
            unlink(public_path('uploads/brands/' . $brand->image));
        }
        $brand->delete();
        return response()->json(['status' => 'success', 'message' => 'Brand berhasil dihapus']);
    }

    // 4. MANAJEMEN PESANAN
    public function getOrders()
    {
        return response()->json(['status' => 'success', 'data' => Order::latest()->get()], 200);
    }

    public function getOrderDetail($id)
    {
        $order = Order::with(['orderItems.product', 'transaction'])->findOrFail($id);
        return response()->json(['status' => 'success', 'data' => $order], 200);
    }

    public function updateOrderStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required']);
        $order = Order::findOrFail($id);
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
    public function getCoupons() { return response()->json(['data' => Coupon::all()], 200); }
    
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

    // 6. FITUR PEMANDANGAN LAIN (SLIDE, KONTAK, SETTING WA)
    public function getSlides() { return response()->json(['data' => Slide::all()], 200); }
    public function getContacts() { return response()->json(['data' => Contact::latest()->get()], 200); }
    public function markContactRead($id) {
        $contact = Contact::findOrFail($id);
        $contact->read_at = now();
        $contact->save();
        return response()->json(['status' => 'success']);
    }
    public function getWhatsappSettings() { return response()->json(['data' => WhatsappSetting::first()], 200); }
}