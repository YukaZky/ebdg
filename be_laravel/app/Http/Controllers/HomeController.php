<?php

namespace App\Http\Controllers;

use App\Models\About;
use App\Models\Category;
use App\Models\Contact;
use App\Models\Product;
use App\Models\Slide;
use Illuminate\Http\Request;

class HomeController extends Controller
{
    public function index()
    {
        $slides = Slide::where('status', 1)->get()->take(3);
        $categories = Category::orderBy('name')->get();
        $bannerRandomCategories = Category::with(['products' => function ($query) {
            $query->whereNotNull('sale_price')->orderBy('sale_price', 'asc');
        }])
            ->has('products')
            ->inRandomOrder()
            ->take(2)
            ->get();

        $sproducts = Product::whereNotNull('sale_price')->where('sale_price', '<>', '')->inRandomOrder()->get()->take(8);
        $fproducts = Product::where('featured', 1)->get()->take(8);

        $maxDiscount = Product::whereNotNull('sale_price')
            ->whereColumn('sale_price', '<', 'regular_price')
            ->get()
            ->map(function ($product) {
                return $product->discount_percentage;
            })
            ->max();
        return view('index', compact('slides', 'categories', 'bannerRandomCategories', 'sproducts', 'fproducts', 'maxDiscount'));
    }

    // Metode untuk halaman kontak yang bersih
    public function contact()
    {
        return view('contact');
    }
    
    // Metode baru untuk halaman bantuan
    public function help()
    {
        return view('help.index');
    }

    public function contact_store(Request $request)
    {
        $request->validate([
            'name' => 'required|max:100',
            'email' => 'required|email',
            'phone' => 'required|numeric|digits_between:10,13',
            'comment' => 'required'
        ]);

        $contact = new Contact();
        $contact->name = $request->name;
        $contact->email = $request->email;
        $contact->phone = $request->phone;
        $contact->comment = $request->comment;
        $contact->save();

        return redirect()->back()->with('success', 'Pesanmu berhasil terkirim!');
    }

    public function search(Request $request)
    {
        $query = $request->input('query');
        $result = Product::where('name', 'LIKE', "%{$query}%")->get()->take(8);
        return response()->json($result);
    }

    public function about()
    {
        // Ambil baris pertama (dan satu-satunya) dari tabel abouts
        $about = About::first(); 
        
        // Kirim data $about ke view 'about'
        return view('about', compact('about'));
    }
    
    public function welcome()
    {
        return view('welcome');
    }

    public function showHelpCategory($category)
    {
        $viewName = 'help.' . $category;

        if (view()->exists($viewName)) {
            return view($viewName);
        }
        
        abort(404);
    }
}