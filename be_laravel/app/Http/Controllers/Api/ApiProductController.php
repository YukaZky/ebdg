<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

class ApiProductController extends Controller
{
    // UNTUK BERANDA (PUBLIK)
    public function index()
    {
        // HAPUS filter user_id agar pembeli bisa melihat semua produk dari semua toko
        $products = Product::with(['category', 'brand'])
            ->orderBy('id', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar Semua Produk Berhasil Diambil',
            'data' => $products
        ], 200);
    }

    // UNTUK HALAMAN DETAIL PRODUK (PUBLIK)
    public function show($slug)
    {
        // HAPUS filter user_id agar pembeli bisa mengintip detail produk toko mana saja
        $product = Product::with(['category', 'brand', 'user']) // Ditambah relasi 'user' agar tahu siapa penjualnya
            ->where('slug', $slug)
            ->first();

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