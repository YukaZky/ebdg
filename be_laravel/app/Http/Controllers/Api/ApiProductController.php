<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
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

    public function index()
    {
        $products = Product::with(['category', 'brand', 'variations', 'store'])
            ->withCount('reviews')
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

    public function show($slug)
    {
        $product = Product::with([
                'category',
                'brand',
                'user:id,name,email',
                'store',
                'variations',
                'reviews.user:id,name',
            ])
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
