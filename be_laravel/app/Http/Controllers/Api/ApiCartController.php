<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CartItem;
use App\Models\Product;
use Illuminate\Http\Request;

class ApiCartController extends Controller
{
    // Mengambil data keranjang milik user yang sedang login
    public function index(Request $request)
    {
        $cartItems = CartItem::with('product')
            ->where('user_id', $request->user()->id)
            ->get();

        $total = 0;
        foreach ($cartItems as $item) {
            $total += $item->product->regular_price * $item->quantity;
        }

        return response()->json([
            'success' => true,
            'data' => $cartItems,
            'total' => $total
        ], 200);
    }

    // Menambah produk ke keranjang
    public function add(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'quantity' => 'required|integer|min:1'
        ]);

        $user = $request->user();
        
        // Cek apakah produk sudah ada di keranjang user ini
        $cartItem = CartItem::where('user_id', $user->id)
            ->where('product_id', $request->product_id)
            ->first();

        if ($cartItem) {
            // Jika ada, tambahkan quantity-nya
            $cartItem->quantity += $request->quantity;
            $cartItem->save();
        } else {
            // Jika belum, buat item baru
            CartItem::create([
                'user_id' => $user->id,
                'product_id' => $request->product_id,
                'quantity' => $request->quantity,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Produk berhasil ditambahkan ke keranjang'
        ], 200);
    }

    // Menghapus item dari keranjang
    public function remove(Request $request, $id)
    {
        $cartItem = CartItem::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if ($cartItem) {
            $cartItem->delete();
            return response()->json(['success' => true, 'message' => 'Item dihapus']);
        }

        return response()->json(['success' => false, 'message' => 'Item tidak ditemukan'], 404);
    }
}