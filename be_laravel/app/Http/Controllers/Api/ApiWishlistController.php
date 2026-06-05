<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Wishlist;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ApiWishlistController extends Controller
{
    public function index()
    {
        $items = Wishlist::with('product')
            ->where('user_id', Auth::id())
            ->orderBy('created_at', 'desc')
            ->get();
        return response()->json(['status' => 'success', 'data' => $items]);
    }

    public function add(Request $request)
    {
        $request->validate(['product_id' => 'required|exists:products,id']);

        Wishlist::firstOrCreate([
            'user_id' => Auth::id(),
            'product_id' => $request->product_id,
        ]);

        return response()->json([
            'status' => 'success', 
            'message' => 'Produk ditambahkan ke wishlist'
        ]);
    }

    public function remove($product_id)
    {
        Wishlist::where('user_id', Auth::id())
            ->where('product_id', $product_id)
            ->delete();

        return response()->json([
            'status' => 'success', 
            'message' => 'Produk dihapus dari wishlist'
        ]);
    }
}