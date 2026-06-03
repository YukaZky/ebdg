<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

class ApiProductController extends Controller
{
    public function index()
    {
        // Mengambil produk terbaru beserta relasi brand dan kategori jika diperlukan
        $products = Product::with(['category', 'brand'])->orderBy('id', 'desc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar Produk Berhasil Diambil',
            'data' => $products
        ], 200);
    }

    public function show($slug)
    {
        $product = Product::with(['category', 'brand'])->where('slug', $slug)->first();

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Produk tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail Produk Berhasil Diambil',
            'data' => $product
        ], 200);
    }
}