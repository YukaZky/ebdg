<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ApiProductController extends Controller
{
    private function attachGalleryImagesAndCover($product)
    {
        $galleryImages = DB::table('product_images')
            ->where('product_id', $product->id)
            ->orderBy('id', 'asc')
            ->get();

        $product->images = $galleryImages;
        $product->product_images = $galleryImages;

        if ((empty($product->image) || $product->image === 'null') && $galleryImages->isNotEmpty()) {
            $product->image = $galleryImages->first()->image;
        }

        return $product;
    }

    // UNTUK BERANDA (PUBLIK)
    public function index()
    {
        $products = Product::with(['category', 'brand', 'variations'])
            ->orderBy('id', 'desc')
            ->get();

        foreach ($products as $product) {
            $this->attachGalleryImagesAndCover($product);
        }

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
        $product = Product::with(['category', 'brand', 'user', 'variations'])
            ->where('slug', $slug)
            ->first();

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Produk tidak ditemukan'
            ], 404);
        }

        $this->attachGalleryImagesAndCover($product);

        return response()->json([
            'success' => true,
            'message' => 'Detail Produk Berhasil Diambil',
            'data' => $product
        ], 200);
    }
}
