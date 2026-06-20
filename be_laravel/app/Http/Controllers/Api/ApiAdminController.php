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
use App\Models\Address;
use App\Models\StoreProfile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ApiAdminController extends Controller
{
    private function syncStoreProfileFromAddress(Address $address): void
    {
        $user = auth()->user();
        if (! $user) return;

        $store = StoreProfile::firstOrCreate(
            ['user_id' => $user->id],
            [
                'name' => $user->name . ' Store',
                'slug' => Str::slug($user->name . '-' . $user->id),
                'status' => 'active',
            ]
        );

        $area = collect([$address->locality, $address->city_name, $address->province_name])
            ->filter(fn ($item) => ! empty($item) && $item !== '-')
            ->implode(', ');

        $store->address = trim($address->address . ($area ? ', ' . $area : ''));
        $store->phone = $address->phone ?: $store->phone;
        $store->province_name = $address->province_name ?: $store->province_name;
        $store->city_name = $address->city_name ?: $store->city_name;

        if ($address->latitude && $address->longitude) {
            $store->maps_url = 'https://www.google.com/maps/search/?api=1&query=' . $address->latitude . ',' . $address->longitude;
        }

        $store->save();
    }

    private function productPayload(Product $product): Product
    {
        $product->load(['category', 'brand', 'variations']);
        $product->images = DB::table('product_images')
            ->where('product_id', $product->id)
            ->orderBy('id', 'asc')
            ->get();

        return $product;
    }

    private function normalizeArrayInput($value): array
    {
        if (is_array($value)) return $value;
        if ($value === null) return [];
        return [$value];
    }

    private function arrayValue(array $items, $index, $default = null)
    {
        return array_key_exists($index, $items) ? $items[$index] : $default;
    }

    private function syncProductVariations(Request $request, Product $product): void
    {
        $names = $this->normalizeArrayInput($request->input('variation_names', []));
        $variationIds = $this->normalizeArrayInput($request->input('variation_ids', []));
        $regularPrices = $this->normalizeArrayInput($request->input('variation_regular_prices', []));
        $salePrices = $this->normalizeArrayInput($request->input('variation_sale_prices', []));
        $weights = $this->normalizeArrayInput($request->input('variation_weights', []));
        $quantities = $this->normalizeArrayInput($request->input('variation_quantities', []));

        $savedIds = [];

        foreach ($names as $index => $name) {
            $name = trim((string) $name);
            if ($name === '') continue;

            $variationId = $this->arrayValue($variationIds, $index);
            $variation = null;

            if (! empty($variationId)) {
                $variation = ProductVariation::where('product_id', $product->id)
                    ->where('id', $variationId)
                    ->first();
            }

            if (! $variation) {
                $variation = new ProductVariation();
                $variation->product_id = $product->id;
            }

            $regularPrice = $this->arrayValue($regularPrices, $index, 0);
            $salePrice = $this->arrayValue($salePrices, $index);
            $weight = $this->arrayValue($weights, $index, 0);
            $quantity = $this->arrayValue($quantities, $index, 0);

            $variation->name = $name;
            $variation->regular_price = $regularPrice !== null && $regularPrice !== '' ? $regularPrice : 0;
            $variation->sale_price = $salePrice !== null && $salePrice !== '' && $salePrice !== 'null' ? $salePrice : null;
            $variation->weight = $weight !== null && $weight !== '' ? $weight : 0;
            $variation->quantity = $quantity !== null && $quantity !== '' ? $quantity : 0;

            $varImage = $request->file("variation_images.$index");
            if ($varImage) {
                $varImageName = time() . "_var_{$product->id}_$index." . $varImage->extension();
                $varImage->move(public_path('uploads/products'), $varImageName);
                $variation->image = $varImageName;
            }

            $variation->save();
            $savedIds[] = $variation->id;
        }

        $deleteQuery = ProductVariation::where('product_id', $product->id);
        if (! empty($savedIds)) {
            $deleteQuery->whereNotIn('id', $savedIds);
        }
        $deleteQuery->delete();
    }

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

    public function getProducts()
    {
        $products = Product::with(['category', 'brand', 'variations'])
            ->where('user_id', auth()->id())
            ->latest()
            ->get();

        foreach ($products as $product) {
            $product->images = DB::table('product_images')
                ->where('product_id', $product->id)
                ->orderBy('id', 'asc')
                ->get();
        }

        return response()->json(['status' => 'success', 'data' => $products], 200);
    }

    public function getProductDetail($id)
    {
        $product = Product::where('user_id', auth()->id())->findOrFail($id);
        return response()->json(['status' => 'success', 'data' => $this->productPayload($product)], 200);
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

        $product = DB::transaction(function () use ($request) {
            $product = new Product();
            $product->user_id = auth()->id();
            $product->name = $request->name;
            $product->slug = Str::slug($request->name) . '-' . auth()->id();
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
            $this->syncProductVariations($request, $product);

            return $product;
        });

        $product = $this->productPayload($product);

        return response()->json([
            'status' => 'success',
            'message' => 'Product created successfully!',
            'variation_count' => $product->variations->count(),
            'data' => $product,
        ], 201);
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

        $product = Product::where('user_id', auth()->id())->findOrFail($id);

        DB::transaction(function () use ($request, $product) {
            $product->name = $request->name;
            $product->slug = Str::slug($request->name) . '-' . auth()->id();
            $product->short_description = $request->short_description;
            $product->description = $request->description;
            $product->regular_price = $request->regular_price;
            $product->sale_price = $request->sale_price;
            $product->SKU = $product->SKU ?: 'PRD' . time();
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
            $this->syncProductVariations($request, $product);
        });

        $product = $this->productPayload($product->fresh());

        return response()->json([
            'status' => 'success',
            'message' => 'Product updated successfully!',
            'variation_count' => $product->variations->count(),
            'data' => $product,
        ], 200);
    }

    public function deleteProduct($id)
    {
        Product::where('user_id', auth()->id())->findOrFail($id)->delete();
        return response()->json(['status' => 'success', 'message' => 'Produk berhasil dihapus'], 200);
    }

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
        $category->slug = Str::slug($request->name) . '-' . auth()->id();

        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $fileName = time() . '.' . $image->extension();
            $image->move(public_path('uploads/categories'), $fileName);
            $category->image = $fileName;
        }
        $category->save();

        return response()->json(['status' => 'success', 'message' => 'Kategori berhasil ditambahkan', 'data' => $category], 201);
    }

    public function updateCategory(Request $request, $id)
    {
        $category = Category::where('user_id', auth()->id())->findOrFail($id);
        $category->name = $request->name ?? $category->name;
        $category->slug = Str::slug($category->name) . '-' . auth()->id();

        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $fileName = time() . '.' . $image->extension();
            $image->move(public_path('uploads/categories'), $fileName);
            $category->image = $fileName;
        }
        $category->save();

        return response()->json(['status' => 'success', 'message' => 'Kategori berhasil diupdate', 'data' => $category]);
    }

    public function deleteCategory($id)
    {
        Category::where('user_id', auth()->id())->findOrFail($id)->delete();
        return response()->json(['status' => 'success'], 200);
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
        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $fileName = time() . '.' . $image->extension();
            $image->move(public_path('uploads/brands'), $fileName);
            $brand->image = $fileName;
        }
        $brand->save();
        return response()->json(['status' => 'success', 'message' => 'Brand berhasil ditambahkan', 'data' => $brand], 201);
    }

    public function updateBrand(Request $request, $id)
    {
        $brand = Brand::where('user_id', auth()->id())->findOrFail($id);
        $brand->name = $request->name ?? $brand->name;
        $brand->slug = Str::slug($brand->name);
        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $fileName = time() . '.' . $image->extension();
            $image->move(public_path('uploads/brands'), $fileName);
            $brand->image = $fileName;
        }
        $brand->save();
        return response()->json(['status' => 'success', 'message' => 'Brand berhasil diupdate', 'data' => $brand]);
    }

    public function deleteBrand($id)
    {
        Brand::where('user_id', auth()->id())->findOrFail($id)->delete();
        return response()->json(['status' => 'success'], 200);
    }

    public function getOrders()
    {
        $orders = Order::where('user_id', auth()->id())->latest()->get();
        return response()->json(['data' => $orders], 200);
    }

    public function getOrderDetail($id)
    {
        $order = Order::with('items.product')->where('user_id', auth()->id())->findOrFail($id);
        return response()->json(['data' => $order], 200);
    }

    public function updateOrderStatus(Request $request, $id)
    {
        $order = Order::where('user_id', auth()->id())->findOrFail($id);
        $order->status = $request->status;
        $order->save();
        return response()->json(['status' => 'success', 'data' => $order]);
    }

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

    public function updateWhatsappSettings(Request $request)
    {
        $setting = WhatsappSetting::first() ?? new WhatsappSetting();
        $setting->fill($request->all());
        $setting->save();

        return response()->json(['status' => 'success', 'data' => $setting], 200);
    }

    public function getStoreLocation()
    {
        $location = Address::where('user_id', auth()->id())
            ->orderBy('is_store_address', 'desc')
            ->orderBy('isdefault', 'desc')
            ->first();

        return response()->json(['success' => (bool) $location, 'data' => $location], 200);
    }

    public function saveStoreLocation(Request $request)
    {
        $request->validate(['province_id' => 'required', 'city_id' => 'required']);
        $address = Address::where('user_id', auth()->id())->where('is_store_address', true)->first() ?? new Address();
        $address->user_id = auth()->id();
        $address->name = $request->name ?? auth()->user()->name;
        $address->phone = $request->phone ?? '0';
        $address->province_id = $request->province_id;
        $address->city_id = $request->city_id;
        $address->district_id = $request->district_id ?? '0';
        $address->province_name = $request->province_name ?? '-';
        $address->city_name = $request->city_name ?? '-';
        $address->district_name = $request->kecamatan ?? '-';
        $address->address = $request->detail_address ?? '-';
        $address->locality = $request->kecamatan ?? '-';
        $address->landmark = $request->landmark ?? '-';
        $address->postal_code = $request->postal_code ?? '00000';
        $address->zip = $request->postal_code ?? '00000';
        $address->city = $request->city_name ?? '-';
        $address->state = $request->province_name ?? '-';
        $address->country = 'Indonesia';
        $address->type = 'home';
        $address->latitude = $request->latitude;
        $address->longitude = $request->longitude;
        $address->note = $request->note;
        $address->label = $request->label ?? 'Toko';
        $address->isdefault = filter_var($request->is_main, FILTER_VALIDATE_BOOLEAN);
        $address->is_store_address = true;
        Address::where('user_id', auth()->id())->update(['is_store_address' => false]);
        $address->save();
        $this->syncStoreProfileFromAddress($address);

        return response()->json(['success' => true, 'message' => 'Alamat toko berhasil disimpan.', 'data' => $address], 200);
    }

    public function getSubdistricts($cityId)
    {
        return response()->json([], 200);
    }

    public function getUserAddresses()
    {
        $addresses = Address::where('user_id', auth()->id())
            ->orderBy('is_store_address', 'desc')
            ->orderBy('isdefault', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['success' => true, 'data' => $addresses], 200);
    }

    public function saveUserAddress(Request $request)
    {
        $request->validate(['province_id' => 'required', 'city_id' => 'required']);

        $isStore = filter_var($request->is_store, FILTER_VALIDATE_BOOLEAN);
        $isMain = filter_var($request->is_main, FILTER_VALIDATE_BOOLEAN);

        if ($isMain) {
            Address::where('user_id', auth()->id())->update(['isdefault' => false]);
        }
        if ($isStore) {
            Address::where('user_id', auth()->id())->update(['is_store_address' => false]);
        }

        $address = $request->address_id
            ? Address::where('user_id', auth()->id())->findOrFail($request->address_id)
            : new Address();

        $address->user_id = auth()->id();
        $address->name = $request->name ?? auth()->user()->name;
        $address->phone = $request->phone ?? '0';
        $address->province_id = $request->province_id;
        $address->city_id = $request->city_id;
        $address->district_id = $request->district_id ?? '0';
        $address->province_name = $request->province_name ?? '-';
        $address->city_name = $request->city_name ?? '-';
        $address->district_name = $request->kecamatan ?? '-';
        $address->address = $request->detail_address ?? '-';
        $address->locality = $request->kecamatan ?? '-';
        $address->landmark = $request->landmark ?? '-';
        $address->postal_code = $request->postal_code ?? '00000';
        $address->zip = $request->postal_code ?? '00000';
        $address->city = $request->city_name ?? '-';
        $address->state = $request->province_name ?? '-';
        $address->country = 'Indonesia';
        $address->type = 'home';
        $address->latitude = $request->latitude;
        $address->longitude = $request->longitude;
        $address->note = $request->note;
        $address->label = $request->label ?? 'Rumah';
        $address->isdefault = $isMain;
        $address->is_store_address = $isStore;
        $address->save();

        if (Address::where('user_id', auth()->id())->count() == 1) {
            $address->isdefault = true;
            $address->save();
        }

        if ($address->is_store_address) {
            $this->syncStoreProfileFromAddress($address);
        }

        return response()->json(['success' => true, 'message' => 'Alamat disimpan.', 'data' => $address], 200);
    }

    public function setMainAddress($id)
    {
        $userId = auth()->id();
        Address::where('user_id', $userId)->update(['isdefault' => false]);
        $address = Address::where('user_id', $userId)->findOrFail($id);
        $address->isdefault = true;
        $address->save();
        return response()->json(['success' => true, 'message' => 'Alamat utama diubah.'], 200);
    }

    public function deleteUserAddress($id)
    {
        Address::where('user_id', auth()->id())->findOrFail($id)->delete();
        return response()->json(['success' => true, 'message' => 'Alamat dihapus.'], 200);
    }
}
