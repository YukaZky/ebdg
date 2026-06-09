<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

class ApiProductController extends Controller
{
    public function index()
    {
        // FILTER DITAMBAHKAN: Hanya ambil produk milik user/admin yang sedang login
        $products = Product::with(['category', 'brand'])
            ->where('user_id', auth()->id()) 
            ->orderBy('id', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar Produk Berhasil Diambil',
            'data' => $products
        ], 200);
    }

    public function show($slug)
    {
        // FILTER DITAMBAHKAN: Pastikan admin tidak bisa mengintip detail produk admin lain
        $product = Product::with(['category', 'brand'])
            ->where('slug', $slug)
            ->where('user_id', auth()->id())
            ->first();

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Produk tidak ditemukan atau Anda tidak memiliki akses'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail Produk Berhasil Diambil',
            'data' => $product
        ], 200);
    }
}