<?php

namespace App\Http\Controllers;

use App\Models\CartItem;
use App\Models\Wishlist;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class WishlistController extends Controller
{
    public function index()
    {
        $items = Wishlist::with('product')
            ->where('user_id', Auth::id())
            ->orderBy('created_at', 'desc')
            ->get();
        return view('wishlist', compact('items'));
    }

    public function add_to_wishlist(Request $request)
    {
        if (!Auth::check()) {
            return response()->json(['status' => 'error', 'message' => 'Silakan login terlebih dahulu.'], 401);
        }

        Wishlist::firstOrCreate([
            'user_id' => Auth::id(),
            'product_id' => $request->id,
        ]);

        // Hitung jumlah wishlist terbaru setelah menambahkan item
        $wishlistCount = Auth::user()->wishlists()->count();

        return response()->json([
            'status' => 'success',
            'message' => 'Produk berhasil ditambahkan ke wishlist.',
            'count' => $wishlistCount // Kirim jumlah terbaru ke JavaScript
        ]);
    }

    // Jangan lupa tambahkan "Request $request" di dalam parameter fungsi
public function remove_item(Request $request, $product_id)
{
    if (!Auth::check()) {
        // Jika ini permintaan AJAX, kirim error JSON
        if ($request->wantsJson()) {
            return response()->json(['status' => 'error', 'message' => 'Silakan login terlebih dahulu.'], 401);
        }
        // Jika tidak, redirect ke halaman login
        return redirect()->route('login')->with('error', 'Silakan login terlebih dahulu.');
    }

    // Logika penghapusan data tetap sama
    Wishlist::where('user_id', Auth::id())
        ->where('product_id', $product_id)
        ->delete();
    
    // Cek apakah permintaan ini menginginkan balasan JSON (berarti dari AJAX)
    if ($request->wantsJson()) {
        // Hitung jumlah item untuk balasan AJAX
        $newCount = Wishlist::where('user_id', Auth::id())->count();

        // Kirim balasan JSON
        return response()->json([
            'status' => 'success',
            'message' => 'Produk berhasil dihapus dari wishlist.',
            'count' => $newCount
        ]);
    }

    // Jika bukan permintaan AJAX, lakukan redirect (untuk form di halaman wishlist)
    return redirect()->back()->with('success', 'Produk berhasil dihapus dari wishlist.');
}

    public function empty_wishlist()
    {
        Wishlist::where('user_id', Auth::id())->delete();
        return redirect()->back()->with('success', 'Wishlist berhasil dikosongkan.');
    }

    public function move_to_cart($id)
    {
        $wishlistItem = Wishlist::with('product')
            ->where('user_id', Auth::id())
            ->findOrFail($id);

        CartItem::updateOrCreate(
            [
                'user_id' => Auth::id(),
                'product_id' => $wishlistItem->product_id,
            ],
            [
                'quantity' => 1,
                'price' => $wishlistItem->product->sale_price ?? $wishlistItem->product->regular_price,
            ]
        );

        $wishlistItem->delete();
        return redirect()->back()->with('success', 'Produk berhasil dipindahkan ke keranjang.');
    }
}