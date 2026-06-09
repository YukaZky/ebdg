<?php

namespace App\Http\Controllers;

use App\Models\Brand;
use App\Models\Category;
use App\Models\Contact;
use App\Models\Coupon;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Slide;
use App\Models\Transaction;
use App\Models\User;
use App\Models\About;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\File;
use Intervention\Image\Laravel\Facades\Image;
use Illuminate\Support\Facades\Hash;
use App\Exports\ProductsReportExport;
use Maatwebsite\Excel\Facades\Excel;
use Barryvdh\DomPDF\Facade\Pdf;


class AdminController extends BaseController
{
    public function get_brands_by_category(Request $request)
    {
        $categoryId = $request->input('category_id');

        $brands = Brand::where('category_id', $categoryId)
            ->select('id', 'name')
            ->orderBy('name', 'asc')
            ->get();

        return response()->json($brands);
    }

    public function about_edit()
    {
        $about = About::firstOrCreate(['id' => 1]);
        return view('admin.edit-about', compact('about'));
    }

    public function about_update(Request $request)
    {
        $request->validate([
            'logo_image' => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:1024',
            'poster_image' => 'nullable|image|mimes:jpeg,png,jpg,gif',
            'our_story' => 'required|string',
            'our_vision' => 'required|string',
            'our_mission' => 'required|string',
            'the_company' => 'required|string',
            'province_id' => 'nullable|string',
            'city_id' => 'nullable|string',
            'district_id' => 'nullable|string',
        ]);

        $about = About::find(1);
        $about->our_story = $request->our_story;
        $about->our_vision = $request->our_vision;
        $about->our_mission = $request->our_mission;
        $about->the_company = $request->the_company;
        $about->province_id = $request->province_id;
        $about->city_id = $request->city_id;
        $about->district_id = $request->district_id;

        if ($request->hasFile('logo_image')) {
            if ($about->logo_image && File::exists(public_path('uploads/about') . '/' . $about->logo_image)) {
                File::delete(public_path('uploads/about') . '/' . $about->logo_image);
            }
            $image = $request->file('logo_image');
            $file_extension = $image->extension();
            $file_name = 'logo-' . Carbon::now()->timestamp . '.' . $file_extension;
            $this->GenerateAboutLogoImage($image, $file_name);
            $about->logo_image = $file_name;
        }

        if ($request->hasFile('poster_image')) {
            if ($about->poster_image && File::exists(public_path('uploads/about') . '/' . $about->poster_image)) {
                File::delete(public_path('uploads/about') . '/' . $about->poster_image);
            }
            $image = $request->file('poster_image');
            $file_extension = $image->extension();
            $file_name = 'poster-' . Carbon::now()->timestamp . '.' . $file_extension;
            $this->GenerateAboutPosterImage($image, $file_name);
            $about->poster_image = $file_name;
        }

        $about->save();

        return redirect()->route('admin.about.edit')->with('status', 'Profil Usaha & Lokasi Toko berhasil diperbarui!');
    }

    public function GenerateAboutLogoImage($image, $imageName)
    {
        $destinationPath = public_path('uploads/about');
        if (!File::isDirectory($destinationPath)) {
            File::makeDirectory($destinationPath, 0755, true, true);
        }
        $image->move($destinationPath, $imageName);
    }

    public function GenerateAboutPosterImage($image, $imageName)
    {
        $destinationPath = public_path('uploads/about');
        if (!File::isDirectory($destinationPath)) {
            File::makeDirectory($destinationPath, 0755, true, true);
        }

        $img = Image::read($image->path());
        $img->cover(1200, 300, "top");
        $img->save($destinationPath . '/' . $imageName);
    }

    public function users()
    {
        $users = User::orderBy('created_at', 'DESC')->paginate(15); 
        return view('admin.user', compact('users')); 
    }

    public function user_add()
    {
        return view('admin.tambah-user');
    }

    public function user_store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'utype' => 'required|in:ADM,USR', 
        ]);

        $user = new User();
        $user->name = $request->name;
        $user->email = $request->email;
        $user->password = Hash::make($request->password); 
        $user->utype = $request->utype;
        $user->save();

        return redirect()->route('admin.users')->with('status', 'Pengguna baru berhasil ditambahkan!');
    }

    public function user_details($user_id)
    {
        $user = User::with('orders')->find($user_id);

        if (!$user) {
            return redirect()->route('admin.users')->with('error', 'Pengguna tidak ditemukan.');
        }

        return view('admin.detail-user', compact('user'));
    }

    public function user_destroy($id)
    {
        $user = User::findOrFail($id);
        $user->delete();
        return redirect()->route('admin.users')->with('status', 'Pengguna berhasil dihapus!');
    }

    public function search_users(Request $request)
    {
        $query = $request->input('query');
        $users = User::where('name', 'LIKE', "%{$query}%")
            ->orWhere('email', 'LIKE', "%{$query}%")
            ->get();
        return response()->json($users);
    }

    public function search_category(Request $request)
    {
        $query = $request->input('query');
        $users = Category::where('name', 'LIKE', "%{$query}%")
            ->orWhere('slug', 'LIKE', "%{$query}%")
            ->get();
        return response()->json($users);
    }

    public function search_brands(Request $request)
    {
        $query = $request->input('query');
        $brands = Brand::where('name', 'LIKE', "%{$query}%")
            ->orWhere('slug', 'LIKE', "%{$query}%")
            ->get();
        return response()->json($brands);
    }

    public function search_contacts(Request $request)
    {
        $query = $request->input('query');
        $contacts = Contact::where('name', 'LIKE', "%{$query}%")
            ->orWhere('email', 'LIKE', "%{$query}%")
            ->orWhere('phone', 'LIKE', "%{$query}%")
            ->orWhere('comment', 'LIKE', "%{$query}%")
            ->get();
        return response()->json($contacts);
    }

    public function search_coupons(Request $request)
    {
        $query = $request->input('query');
        $coupons = Coupon::where('code', 'LIKE', "%{$query}%")
            ->get();
        return response()->json($coupons);
    }

    public function search_orders(Request $request)
    {
        $query = $request->input('query');
        $orders = Order::with('orderItems')
            ->where('id', 'LIKE', "%{$query}%")
            ->orWhere('name', 'LIKE', "%{$query}%")
            ->orWhere('phone', 'LIKE', "%{$query}%")
            ->get();
        return response()->json($orders);
    }

    public function search_products(Request $request)
    {
        $query = $request->input('query');
        $products = Product::with(['category', 'brand'])
            ->where('name', 'LIKE', "%{$query}%")
            ->orWhere('slug', 'LIKE', "%{$query}%")
            ->orWhere('SKU', 'LIKE', "%{$query}%")
            ->get();
        return response()->json($products);
    }

    public function index()
    {
        $orders = Order::orderBy('created_at', 'DESC')->get()->take(10);

        $dashboardDatas = DB::select("Select 
            sum(total) As TotalAmount,
            sum(if(status='ordered', total,0)) As TotalOrderedAmount,
            sum(if(status='shipping', total,0)) As TotalShippingAmount,
            sum(if(status='delivered', total,0)) As TotalDeliveredAmount,
            sum(if(status='canceled', total,0)) As TotalCanceledAmount,
            Count(*) As Total,
            sum(if(status='ordered', 1,0)) As TotalOrdered,
            sum(if(status='shipping', 1,0)) As TotalShipping,
            sum(if(status='delivered', 1,0)) As TotalDelivered,
            sum(if(status='canceled', 1,0)) As TotalCanceled
            From Orders");

        $monthlyDatas = DB::select("SELECT M.id As MonthNo, M.name As MonthName,
            IFNULL(D.TotalAmount,0) As TotalAmount,
            IFNULL(D.TotalOrderedAmount,0) As TotalOrderedAmount,
            IFNULL(D.TotalShippingAmount,0) As TotalShippingAmount,
            IFNULL(D.TotalDeliveredAmount,0) As TotalDeliveredAmount,
            IFNULL(D.TotalCanceledAmount,0) As TotalCanceledAmount 
            FROM month_names M
            LEFT JOIN (
                Select 
                    DATE_FORMAT(created_at, '%b') As MonthName,
                    MONTH(created_at) As MonthNo,
                    sum(total) As TotalAmount,
                    sum(if(status='ordered',total,0)) As TotalOrderedAmount,
                    sum(if(status='shipping',total,0)) As TotalShippingAmount,
                    sum(if(status='delivered',total,0)) As TotalDeliveredAmount,
                    sum(if(status='canceled',total,0)) As TotalCanceledAmount
                FROM Orders WHERE YEAR(created_at)=YEAR(NOW()) 
                GROUP BY YEAR(created_at), MONTH(created_at), DATE_FORMAT(created_at, '%b')
                Order By MONTH(created_at)
            ) D On D.MonthNo=M.id");

        $AmountM = implode(',', collect($monthlyDatas)->pluck('TotalAmount')->toArray());
        $OrderedAmountM = implode(',', collect($monthlyDatas)->pluck('TotalOrderedAmount')->toArray());
        $ShippingAmountM = implode(',', collect($monthlyDatas)->pluck('TotalShippingAmount')->toArray()); 
        $DeliveredAmountM = implode(',', collect($monthlyDatas)->pluck('TotalDeliveredAmount')->toArray());
        $CanceledAmountM = implode(',', collect($monthlyDatas)->pluck('TotalCanceledAmount')->toArray());

        $TotalAmount = collect($monthlyDatas)->sum('TotalAmount');
        $TotalOrderedAmount = collect($monthlyDatas)->sum('TotalOrderedAmount');
        $TotalShippingAmount = collect($monthlyDatas)->sum('TotalShippingAmount'); 
        $TotalDeliveredAmount = collect($monthlyDatas)->sum('TotalDeliveredAmount');
        $TotalCanceledAmount = collect($monthlyDatas)->sum('TotalCanceledAmount');

        return view('admin.index', compact(
            'orders', 'dashboardDatas', 'AmountM', 'OrderedAmountM', 'ShippingAmountM', 'DeliveredAmountM', 'CanceledAmountM', 
            'TotalAmount', 'TotalOrderedAmount', 'TotalShippingAmount', 'TotalDeliveredAmount', 'TotalCanceledAmount'
        ));
    }

    public function brands()
    {
        $brands = Brand::withCount('products')->orderBy('id', 'desc')->paginate(10);
        return view('admin.brands', compact('brands'));
    }

    public function brand_add()
    {
        $categories = Category::orderBy('name', 'asc')->get();
        return view('admin.brand-add', compact('categories'));
    }

    public function brand_store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'category_id' => 'required|exists:categories,id',
            'image' => 'required|image|mimes:jpeg,png,jpg,gif'
        ], [
            'name.required' => 'Nama merek tidak boleh kosong.',
            'category_id.required' => 'Anda harus memilih kategori.',
            'image.required' => 'Gambar merek wajib diunggah.',
            'image.image' => 'File yang diunggah harus berupa gambar.',
            'image.mimes' => 'Format gambar harus jpeg, png, jpg, atau gif.',
            'image.max' => 'Ukuran gambar maksimal adalah 2MB.',
        ]);

        $imageName = null;
        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $imageName = time() . '.' . $image->getClientOriginalExtension();
            $image->move(public_path('uploads/brands'), $imageName);
        }

        Brand::create([
            'user_id' => auth()->id(),
            'name' => $request->name,
            'slug' => Str::slug($request->name, '-'), 
            'category_id' => $request->category_id,
            'image' => $imageName
        ]);

        return redirect()->route('admin.brands')->with('success', 'Merek baru berhasil ditambahkan!');
    }

    public function brand_edit($id)
    {
        $brand = Brand::findOrFail($id);
        $categories = Category::orderBy('name', 'asc')->get();
        return view('admin.brand-edit', compact('brand', 'categories'));
    }

    public function brand_update(Request $request)
    {
        $request->validate([
            'id' => 'required|exists:brands,id',
            'name' => 'required|string|max:255',
            'category_id' => 'required|exists:categories,id',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif' 
        ], [
            'name.required' => 'Nama merek tidak boleh kosong.',
            'category_id.required' => 'Anda harus memilih kategori.',
            'image.image' => 'File yang diunggah harus berupa gambar.',
            'image.mimes' => 'Format gambar harus jpeg, png, jpg, atau gif.',
            'image.max' => 'Ukuran gambar maksimal adalah 2MB.',
        ]);

        $brand = Brand::findOrFail($request->id);

        $imageName = $brand->image;
        if ($request->hasFile('image')) {
            $oldImagePath = public_path('uploads/brands/' . $brand->image);
            if (File::exists($oldImagePath)) {
                File::delete($oldImagePath);
            }

            $image = $request->file('image');
            $imageName = time() . '.' . $image->getClientOriginalExtension();
            $image->move(public_path('uploads/brands'), $imageName);
        }

        $brand->update([
            'name' => $request->name,
            'slug' => Str::slug($request->name, '-'),
            'category_id' => $request->category_id,
            'image' => $imageName
        ]);

        return redirect()->route('admin.brands')->with('success', 'Data merek berhasil diperbarui!');
    }

    public function GenerateBrandThumbnailsImage($image, $imageName)
    {
        $destinationPath = public_path('uploads/brands');
        $img = Image::read($image->path());
        $img->cover(800, 800, "top");
        $img->resize(800, 800, function ($contraint) {
            $contraint->aspectRatio();
        })->save($destinationPath . '/' . $imageName);
    }

    public function brand_delete($id)
    {
        $brand = Brand::find($id);
        if (File::exists(public_path('uploads/brands') . '/' . $brand->image)) {
            File::delete(public_path('uploads/brands') . '/' . $brand->image);
        }
        $brand->delete();
        return redirect()->route('admin.brands')->with('status', 'Brand berhasil dihapus!');
    }

    public function categories()
    {
        $categories = Category::orderBy('id', 'DESC')->paginate(10);
        return view('admin.categories', compact('categories'));
    }

    public function add_category()
    {
        return view('admin.category-add');
    }

    public function category_store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'slug' => 'required|unique:categories,slug',
            'image' => 'mimes:png,jpg,jpeg',
        ]);

        $category = new Category();
        $category->name = $request->name;
        $category->slug = Str::slug($request->name);
        $image = $request->file('image');
        $file_extention = $request->file('image')->extension();
        $file_name = Carbon::now()->timestamp . '.' . $file_extention;
        $this->GenerateCategoryThumbnailsImage($image, $file_name);
        $category->image = $file_name;
        $category->save();
        return redirect()->route('admin.categories')->with('status', 'Kategori berhasil ditambahkan!');
    }

    public function category_edit($id)
    {
        $category = Category::find($id);
        return view('admin.category-edit', compact('category'));
    }

    public function category_update(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'slug' => 'required|unique:categories,slug,' . $request->id,
            'image' => 'mimes:png,jpg,jpeg',
        ]);

        $category = Category::find($request->id);
        $category->name = $request->name;
        $category->slug = Str::slug($request->name);
        if ($request->hasFile('image')) {
            if (File::exists(public_path('uploads/categories') . '/' . $category->image)) {
                File::delete(public_path('uploads/categories') . '/' . $category->image);
            }
            $image = $request->file('image');
            $file_extention = $request->file('image')->extension();
            $file_name = Carbon::now()->timestamp . '.' . $file_extention;
            $this->GenerateCategoryThumbnailsImage($image, $file_name);
            $category->image = $file_name;
        }
        $category->save();
        return redirect()->route('admin.categories')->with('status', 'Kategori berhasil diupdate!');
    }

    public function GenerateCategoryThumbnailsImage($image, $imageName)
    {
        $destinationPath = public_path('uploads/categories');
        $img = Image::read($image->path());
        $img->cover(800, 800, "top");
        $img->resize(800, 800, function ($contraint) {
            $contraint->aspectRatio();
        })->save($destinationPath . '/' . $imageName);
    }

    public function category_delete($id)
    {
        $category = Category::find($id);
        if (File::exists(public_path('uploads/categories') . '/' . $category->image)) {
            File::delete(public_path('uploads/categories') . '/' . $category->image);
        }
        $category->delete();
        return redirect()->route('admin.categories')->with('status', 'Kategori berhasil dihapus!');
    }

    public function products()
    {
        $products = Product::orderBy('created_at', 'DESC')->paginate(10);
        return view('admin.products', compact('products'));
    }

    public function product_add()
    {
        $categories = Category::select('id', 'name')->orderBy('name')->get();
        $brands = Brand::select('id', 'name')->orderBy('name')->get();
        return view('admin.product-add', compact('categories', 'brands'));
    }

    public function product_store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'slug' => 'required|unique:products,slug',
            'short_description' => 'nullable|string',
            'description' => 'required',
            'regular_price' => 'required',
            'sale_price' => 'required',
            'SKU' => 'required',
            'stock_status' => 'required',
            'featured' => 'required',
            'quantity' => 'required',
            'image' => 'required|mimes:png,jpg,jpeg',
            'category_id' => 'required',
            'brand_id' => 'required',
            'weight_gram' => ['required', 'integer', 'min:0'],
            'exp_date' => 'nullable|date',
        ]);

        $product = new Product();
        $product->name = $request->name;
        $product->slug = Str::slug($request->name);
        $product->short_description = $request->short_description ?: null;
        $product->description = $request->description;
        $product->regular_price = $request->regular_price;
        $product->sale_price = $request->sale_price;
        $product->SKU = $request->SKU;
        $product->stock_status = $request->stock_status;
        $product->featured = $request->featured;
        $product->quantity = $request->quantity;
        $product->category_id = $request->category_id;
        $product->brand_id = $request->brand_id;
        $product->exp_date = $request->exp_date; 

        $current_timestamp = Carbon::now()->timestamp;

        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $imageName = $current_timestamp . '.' . $image->extension();
            $this->GenerateProductThumbnailsImage($image, $imageName);
            $product->image = $imageName;
        }

        $gallery_arr = array();
        $gallery_images = "";
        $counter = 1;

        if ($request->hasFile('images')) {
            $allowedFileExtension = ['png', 'jpg', 'jpeg'];
            $files = $request->file('images');
            foreach ($files as $file) {
                $gextension = $file->getClientOriginalExtension();
                $gcheck = in_array($gextension, $allowedFileExtension);
                if ($gcheck) {
                    $gfileName = $current_timestamp . "-" . $counter . "." . $gextension;
                    $this->GenerateProductThumbnailsImage($file, $gfileName);
                    array_push($gallery_arr, $gfileName);
                    $counter = $counter + 1;
                }
            }
            $gallery_images = implode(',', $gallery_arr);
        }
        $product->images = $gallery_images;
        $product->brand_id     = $request->brand_id;
        $product->weight_gram  = (int) $request->weight_gram;
        $product->save();
        return redirect()->route('admin.products')->with('status', 'Produk berhasil ditambahkan!');
    }

    public function GenerateProductThumbnailsImage($image, $imageName)
    {
        $destinationPathThumbnails = public_path('uploads/products/thumbnails');
        $destinationPath = public_path('uploads/products');
        $img = Image::read($image->path());
        $img->cover(800, 800, "top");
        $img->resize(800, 800, function ($contraint) {
            $contraint->aspectRatio();
        })->save($destinationPath . '/' . $imageName);

        $img->resize(104, 104, function ($contraint) {
            $contraint->aspectRatio();
        })->save($destinationPathThumbnails . '/' . $imageName);
    }

    public function product_edit($id)
    {
        $product = Product::find($id);
        $categories = Category::select('id', 'name')->orderBy('name')->get();
        $brands = Brand::where('category_id', $product->category_id)->select('id', 'name')->orderBy('name')->get();
        return view('admin.product-edit', compact('product', 'categories', 'brands'));
    }

    public function product_update(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'slug' => 'required|unique:products,slug,' . $request->id,
            'short_description' => 'nullable|string',
            'description' => 'required',
            'regular_price' => 'required',
            'sale_price' => 'required',
            'SKU' => 'required',
            'stock_status' => 'required',
            'featured' => 'required',
            'quantity' => 'required',
            'image' => 'mimes:png,jpg,jpeg',
            'category_id' => 'required',
            'brand_id' => 'required',
            'weight_gram' => ['required', 'integer', 'min:0'],
            'exp_date' => 'nullable|date',
        ]);

        $product = Product::find($request->id);
        $product->name = $request->name;
        $product->slug = Str::slug($request->name);
        $product->short_description = $request->short_description ?: null;
        $product->description = $request->description;
        $product->regular_price = $request->regular_price;
        $product->sale_price = $request->sale_price;
        $product->SKU = $request->SKU;
        $product->stock_status = $request->stock_status;
        $product->featured = $request->featured;
        $product->quantity = $request->quantity;
        $product->category_id = $request->category_id;
        $product->brand_id = $request->brand_id;
        $product->exp_date = $request->exp_date;

        $current_timestamp = Carbon::now()->timestamp;

        if ($request->hasFile('image')) {
            if (File::exists(public_path('uploads/products') . '/' . $product->image)) {
                File::delete(public_path('uploads/products') . '/' . $product->image);
            }
            if (File::exists(public_path('uploads/products/thumbnails') . '/' . $product->image)) {
                File::delete(public_path('uploads/products/thumbnails') . '/' . $product->image);
            }
            $image = $request->file('image');
            $imageName = $current_timestamp . '.' . $image->extension();
            $this->GenerateProductThumbnailsImage($image, $imageName);
            $product->image = $imageName;
        }

        $gallery_arr = array();
        $gallery_images = "";
        $counter = 1;

        if ($request->hasFile('images')) {
            foreach (explode(',', $product->images) as $ofile) {
                if (File::exists(public_path('uploads/products') . '/' . $ofile)) {
                    File::delete(public_path('uploads/products') . '/' . $ofile);
                }
                if (File::exists(public_path('uploads/products/thumbnails') . '/' . $ofile)) {
                    File::delete(public_path('uploads/products/thumbnails') . '/' . $ofile);
                }
            }
            $allowedFileExtension = ['png', 'jpg', 'jpeg'];
            $files = $request->file('images');
            foreach ($files as $file) {
                $gextension = $file->getClientOriginalExtension();
                $gcheck = in_array($gextension, $allowedFileExtension);
                if ($gcheck) {
                    $gfileName = $current_timestamp . "-" . $counter . "." . $gextension;
                    $this->GenerateProductThumbnailsImage($file, $gfileName);
                    array_push($gallery_arr, $gfileName);
                    $counter = $counter + 1;
                }
            }
            $gallery_images = implode(',', $gallery_arr);
            $product->images = $gallery_images;
        }
        $product->brand_id     = $request->brand_id;
        $product->weight_gram  = (int) $request->weight_gram;
        $product->save();
        return redirect()->route('admin.products')->with('status', 'Produk berhasil diupdate!');
    }

    public function deleteProductImageAjax(Request $request)
    {
        $request->validate([
            'product_id' => 'required|integer|exists:products,id',
            'filename' => 'required|string'
        ]);

        $product = Product::findOrFail($request->product_id);
        $filename = trim($request->filename);

        $imagePath = public_path('uploads/products/' . $filename);
        $thumbPath = public_path('uploads/products/thumbnails/' . $filename);

        if (File::exists($imagePath)) File::delete($imagePath);
        if (File::exists($thumbPath)) File::delete($thumbPath);

        $gallery = array_filter(explode(',', $product->images), fn($item) => trim($item) !== $filename);
        $product->images = implode(',', $gallery);
        $product->save();

        return response()->json(['success' => true, 'message' => 'Image deleted']);
    }

    public function product_delete($id)
    {
        $product = Product::find($id);
        if (File::exists(public_path('uploads/products') . '/' . $product->image)) {
            File::delete(public_path('uploads/products') . '/' . $product->image);
        }
        if (File::exists(public_path('uploads/products/thumbnails') . '/' . $product->image)) {
            File::delete(public_path('uploads/products/thumbnails') . '/' . $product->image);
        }
        foreach (explode(',', $product->images) as $ofile) {
            if (File::exists(public_path('uploads/products') . '/' . $ofile)) {
                File::delete(public_path('uploads/products') . '/' . $ofile);
            }
            if (File::exists(public_path('uploads/products/thumbnails') . '/' . $ofile)) {
                File::delete(public_path('uploads/products/thumbnails') . '/' . $ofile);
            }
        }
        $product->delete();
        return redirect()->route('admin.products')->with('status', 'Produk berhasil dihapus!');
    }

    public function coupons()
    {
        $coupons = Coupon::orderBy('expiry_date', 'DESC')->paginate(12);
        return view('admin.coupons', compact('coupons'));
    }

    public function coupon_add()
    {
        return view('admin.coupon-add');
    }

    public function coupon_store(Request $request)
    {
        $request->validate([
            'code' => 'required',
            'type' => 'required',
            'value' => 'required|numeric',
            'cart_value' => 'required|numeric',
            'expiry_date' => 'required|date'
        ]);
        $coupon = new Coupon();
        $coupon->code = $request->code;
        $coupon->type = $request->type;
        $coupon->value = $request->value;
        $coupon->cart_value = $request->cart_value;
        $coupon->expiry_date = $request->expiry_date;
        $coupon->save();
        return redirect()->route('admin.coupons')->with('status', 'Kupon berhasil ditambahkan!');
    }

    public function coupon_edit($id)
    {
        $coupon = Coupon::find($id);
        return view('admin.coupon-edit', compact('coupon'));
    }

    public function coupon_update(Request $request)
    {
        $request->validate([
            'code' => 'required',
            'type' => 'required',
            'value' => 'required|numeric',
            'cart_value' => 'required|numeric',
            'expiry_date' => 'required|date'
        ]);
        $coupon = Coupon::find($request->id);
        $coupon->code = $request->code;
        $coupon->type = $request->type;
        $coupon->value = $request->value;
        $coupon->cart_value = $request->cart_value;
        $coupon->expiry_date = $request->expiry_date;
        $coupon->save();
        return redirect()->route('admin.coupons')->with('status', 'Kupon berhasil diubah!');
    }

    public function coupon_delete($id)
    {
        $coupon = Coupon::find($id);
        $coupon->delete();
        return redirect()->route('admin.coupons')->with('status', 'Kupon berhasil dihapus!');
    }

    public function orders()
    {
        $orders = Order::orderBy('created_at', 'DESC')->paginate(12);
        return view('admin.orders', compact('orders'));
    }

    public function orderReport()
    {
        $dashboardDatas = DB::select("Select sum(total) As TotalAmount,
                                 sum(if(status='ordered', total,0)) As TotalOrderedAmount,
                                 sum(if(status='delivered', total,0)) As TotalDeliveredAmount,
                                 sum(if(status='canceled', total,0)) As TotalCanceledAmount,
                                 Count(*) As Total,
                                 sum(if(status='ordered', 1,0)) As TotalOrdered,
                                 sum(if(status='delivered', 1,0)) As TotalDelivered,
                                 sum(if(status='canceled', 1,0)) As TotalCanceled
                                 From Orders");

        $monthlyDatas = DB::table('orders')
            ->select(
                DB::raw('MONTH(created_at) as month_num'),
                DB::raw('DATE_FORMAT(created_at, "%M") as month_name'),
                DB::raw('SUM(CASE WHEN status = "delivered" THEN total ELSE 0 END) as monthly_revenue')
            )
            ->whereYear('created_at', date('Y'))
            ->groupBy('month_num', 'month_name')
            ->orderBy('month_num', 'asc')
            ->get();

        $bestSellingProducts = DB::table('products')
            ->leftJoin('order_items', 'products.id', '=', 'order_items.product_id')
            ->leftJoin('orders', 'order_items.order_id', '=', 'orders.id')
            ->select(
                'products.SKU',
                'products.name',
                'products.exp_date',
                DB::raw('COALESCE(SUM(CASE WHEN orders.status = "delivered" THEN order_items.quantity ELSE 0 END), 0) as total_quantity_sold')
            )
            ->groupBy('products.id', 'products.SKU', 'products.name', 'products.exp_date')
            ->orderByDesc('total_quantity_sold')
            ->orderBy('products.name', 'asc')
            ->paginate(20);

        return view('admin.orders.report', compact(
            'bestSellingProducts',
            'dashboardDatas',
            'monthlyDatas'
        ));
    }

    public function exportExcel()
    {
        return Excel::download(new ProductsReportExport, 'laporan-produk-terlaris.xlsx');
    }

    public function exportPdf()
    {
        $dashboardDatas = DB::select("Select sum(total) As TotalAmount,
                                 sum(if(status='ordered', total,0)) As TotalOrderedAmount,
                                 sum(if(status='delivered', total,0)) As TotalDeliveredAmount,
                                 sum(if(status='canceled', total,0)) As TotalCanceledAmount,
                                 Count(*) As Total,
                                 sum(if(status='ordered', 1,0)) As TotalOrdered,
                                 sum(if(status='delivered', 1,0)) As TotalDelivered,
                                 sum(if(status='canceled', 1,0)) As TotalCanceled
                                 From Orders");
        
        $monthlyDatas = DB::table('orders')
            ->select(
                DB::raw('MONTH(created_at) as month_num'),
                DB::raw('DATE_FORMAT(created_at, "%M") as month_name'),
                DB::raw('SUM(CASE WHEN status = "delivered" THEN total ELSE 0 END) as monthly_revenue')
            )
            ->whereYear('created_at', date('Y'))
            ->groupBy('month_num', 'month_name')
            ->orderBy('month_num', 'asc')
            ->get();
            
        $bestSellingProducts = DB::table('products')
            ->leftJoin('order_items', 'products.id', '=', 'order_items.product_id')
            ->leftJoin('orders', 'order_items.order_id', '=', 'orders.id')
            ->select(
                'products.SKU',
                'products.name',
                'products.exp_date',
                DB::raw('COALESCE(SUM(CASE WHEN orders.status = "delivered" THEN order_items.quantity ELSE 0 END), 0) as total_quantity_sold')
            )
            ->groupBy('products.id', 'products.SKU', 'products.name', 'products.exp_date')
            ->orderByDesc('total_quantity_sold')
            ->orderBy('products.name', 'asc')
            ->get();

        $pdf = Pdf::loadView('admin.orders.report_pdf', compact('bestSellingProducts', 'dashboardDatas', 'monthlyDatas'));
        return $pdf->download('laporan-penjualan.pdf');
    }

    public function order_details($order_id)
    {
        $order = Order::find($order_id);
        $orderItems = OrderItem::where('order_id', $order_id)->orderBy('id')->paginate(12);
        $transaction = Transaction::where('order_id', $order_id)->first();
        return view('admin.order-details', compact('order', 'orderItems', 'transaction'));
    }

    public function update_order_status(Request $request)
    {
        $order = Order::find($request->order_id);
        $order->status = $request->order_status;
        if ($request->order_status == 'delivered') {
            $order->delivered_date = Carbon::now();
        } else if ($request->order_status == 'canceled') {
            $order->canceled_date = Carbon::now();
        }
        $order->save();

        if ($request->order_status == 'delivered') {
            $transaction = Transaction::where('order_id', $request->order_id)->first();
            $transaction->status = 'approved';
            $transaction->save();
        }
        return back()->with('status', 'Status berhasil diubah!');
    }

    public function slides()
    {
        $slides = Slide::orderBy('id', 'DESC')->paginate(12);
        return view('admin.slides', compact('slides'));
    }

    public function slide_add()
    {
        return view('admin.slide-add');
    }

    public function slide_store(Request $request)
    {
        $request->validate([
            'tagline' => 'required',
            'title' => 'required',
            'subtitle' => 'required',
            'link' => 'required',
            'status' => 'required',
            'image' => 'required|mimes:png,jpg,jpeg'
        ]);

        $slide = new Slide();
        $slide->tagline = $request->tagline;
        $slide->title = $request->title;
        $slide->subtitle = $request->subtitle;
        $slide->link = $request->link;
        $slide->status = $request->status;

        $image = $request->file('image');
        $file_extention = $request->file('image')->extension();
        $file_name = Carbon::now()->timestamp . '.' . $file_extention;
        $this->GenerateSlideThumbnailsImage($image, $file_name);
        $slide->image = $file_name;
        $slide->save();
        return redirect()->route('admin.slides')->with('status', 'Slide berhasil ditambahkan!');
    }

    public function GenerateSlideThumbnailsImage($image, $imageName)
    {
        $destinationPath = public_path('uploads/slides');
        $img = Image::read($image->path());
        $img->cover(800, 800, "top");
        $img->resize(800, 800, function ($contraint) {
            $contraint->aspectRatio();
        })->save($destinationPath . '/' . $imageName);
    }

    public function slide_edit($id)
    {
        $slide = Slide::find($id);
        return view('admin.slide-edit', compact('slide'));
    }

    public function slide_update(Request $request)
    {
        $request->validate([
            'tagline' => 'required',
            'title' => 'required',
            'subtitle' => 'required',
            'link' => 'required',
            'status' => 'required',
            'image' => 'required|mimes:png,jpg,jpeg'
        ]);

        $slide = Slide::find($request->id);
        $slide->tagline = $request->tagline;
        $slide->title = $request->title;
        $slide->subtitle = $request->subtitle;
        $slide->link = $request->link;
        $slide->status = $request->status;

        if ($request->hasFile('image')) {
            if (File::exists(public_path('uploads/slides') . '/' . $slide->image)) {
                File::delete(public_path('uploads/slides') . '/' . $slide->image);
            }
            $image = $request->file('image');
            $file_extention = $request->file('image')->extension();
            $file_name = Carbon::now()->timestamp . '.' . $file_extention;
            $this->GenerateSlideThumbnailsImage($image, $file_name);
            $slide->image = $file_name;
        }
        $slide->save();
        return redirect()->route('admin.slides')->with('status', 'Slide berhasil diupdate!');
    }

    public function slide_delete($id)
    {
        $slide = Slide::find($id);
        if (File::exists(public_path('uploads/slides') . '/' . $slide->image)) {
            File::delete(public_path('uploads/slides') . '/' . $slide->image);
        }
        $slide->delete();
        return redirect()->route('admin.slides')->with('status', 'Slide berhasil dihapus!');
    }

    public function contacts()
    {
        $contacts = Contact::orderBy('created_at', 'DESC')->paginate(10);
        $totalContacts = Contact::count();

        return view('admin.contacts', compact('contacts', 'totalContacts'));
    }

    public function contact_details($id)
    {
        $contact = Contact::findOrFail($id);
        return view('admin.detail-contacts', compact('contact'));
    }

    public function contact_delete($id)
    {
        $contact = Contact::find($id);
        $contact->delete();
        return redirect()->route('admin.contacts')->with('status', 'Pesan berhasil dihapus!');
    }

    public function search(Request $request)
    {
        $query = $request->input('query');
        $results = Product::where('name', 'LIKE', "%{$query}%")->get()->take(8);
        return response()->json($results);
    }
}