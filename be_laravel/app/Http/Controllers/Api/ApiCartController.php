<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CartItem;
use App\Models\Product;
use Illuminate\Http\Request;

class ApiCartController extends Controller
{
    public function index(Request $request)
    {
        $cartItems = CartItem::with('product')
            ->where('user_id', $request->user()->id)
            ->get();

        $total = 0;
        foreach ($cartItems as $item) {
            $total += $item->product->regular_price * $item->quantity;
        }

        return response()->json(['success' => true, 'data' => $cartItems, 'total' => $total], 200);
    }

    public function add(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'quantity' => 'required|integer|min:1'
        ]);

        $user = $request->user();
        
        // 1. Ambil Data Produk (Untuk mendapatkan harga)
        $product = Product::findOrFail($request->product_id);
        
        $cartItem = CartItem::where('user_id', $user->id)
            ->where('product_id', $request->product_id)
            ->first();

        if ($cartItem) {
            $cartItem->quantity += $request->quantity;
            $cartItem->save();
        } else {
            CartItem::create([
                'user_id' => $user->id,
                'product_id' => $request->product_id,
                'quantity' => $request->quantity,
                // 2. PENAMBAHAN SOLUSI ERROR 500
                'price' => $product->regular_price, 
            ]);
        }

        return response()->json(['success' => true, 'message' => 'Produk berhasil ditambahkan ke keranjang'], 200);
    }

    public function remove(Request $request, $id)
    {
        $cartItem = CartItem::where('user_id', $request->user()->id)->where('id', $id)->first();
        if ($cartItem) {
            $cartItem->delete();
            return response()->json(['success' => true, 'message' => 'Item dihapus']);
        }
        return response()->json(['success' => false, 'message' => 'Item tidak ditemukan'], 404);
    }
}