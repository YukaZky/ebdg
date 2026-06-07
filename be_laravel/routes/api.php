<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ApiAuthController;
use App\Http\Controllers\Api\ApiProductController;
use App\Http\Controllers\Api\ApiCartController;
use App\Http\Controllers\Api\ApiCheckoutController;
use App\Http\Controllers\Api\ApiOrderController;
use App\Http\Controllers\Api\ApiRajaOngkirController;
use App\Http\Controllers\Api\ApiWishlistController;
use App\Http\Controllers\Api\ApiAdminController; // Tambahkan controller admin API Anda

Route::post('/register', [ApiAuthController::class, 'register']);
Route::post('/login', [ApiAuthController::class, 'login']);
Route::get('/products', [ApiProductController::class, 'index']);
Route::get('/products/{slug}', [ApiProductController::class, 'show']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [ApiAuthController::class, 'logout']);
    Route::get('/user-profile', function (Request $request) {
        return response()->json($request->user());
    });

    Route::get('/cart', [ApiCartController::class, 'index']);
    Route::post('/cart/add', [ApiCartController::class, 'add']);
    Route::delete('/cart/remove/{id}', [ApiCartController::class, 'remove']);

    Route::post('/checkout', [ApiCheckoutController::class, 'process']);
    Route::get('/orders', [ApiOrderController::class, 'index']);

    // RUTE WISHLIST API
    Route::get('/wishlist', [ApiWishlistController::class, 'index']);
    Route::post('/wishlist/add', [ApiWishlistController::class, 'add']);
    Route::delete('/wishlist/remove/{product_id}', [ApiWishlistController::class, 'remove']);

    Route::get('/rajaongkir/provinces', [ApiRajaOngkirController::class, 'getProvinces']);
    Route::get('/rajaongkir/cities/{provinceId}', [ApiRajaOngkirController::class, 'getCities']);
    Route::post('/rajaongkir/cost', [ApiRajaOngkirController::class, 'checkCost']);

    // ==========================================
    // RUTE ADMIN PANEL (Toko Saya) - LENGKAP
    // ==========================================
    Route::middleware('admin')->prefix('admin')->group(function () {
        // Dashboard
        Route::get('/dashboard', [ApiAdminController::class, 'dashboardStats']);

        // CRUD Produk
        Route::get('/products', [ApiAdminController::class, 'getProducts']);
        Route::post('/products/store', [ApiAdminController::class, 'storeProduct']);
        Route::put('/products/update/{id}', [ApiAdminController::class, 'updateProduct']);
        Route::delete('/products/delete/{id}', [ApiAdminController::class, 'deleteProduct']);

        // CRUD Kategori & Brand
        Route::get('/categories', [ApiAdminController::class, 'getCategories']);
        Route::post('/categories/store', [ApiAdminController::class, 'storeCategory']);
        Route::put('/categories/update/{id}', [ApiAdminController::class, 'updateCategory']); 
        Route::delete('/categories/delete/{id}', [ApiAdminController::class, 'deleteCategory']); 

        Route::get('/brands', [ApiAdminController::class, 'getBrands']);
        Route::post('/brands/store', [ApiAdminController::class, 'storeBrand']);
        Route::put('/brands/update/{id}', [ApiAdminController::class, 'updateBrand']); 
        Route::delete('/brands/delete/{id}', [ApiAdminController::class, 'deleteBrand']); 

        // --- KELOLA KATEGORI ---
        Route::get('/admin/categories', [ApiAdminController::class, 'getCategories']); 
        Route::post('/admin/categories/store', [ApiAdminController::class, 'storeCategory']);
        Route::put('/admin/categories/update/{id}', [ApiAdminController::class, 'updateCategory']);
        Route::delete('/admin/categories/delete/{id}', [ApiAdminController::class, 'destroyCategory']);

        // --- KELOLA BRAND ---
        Route::get('/admin/brands', [ApiAdminController::class, 'getBrands']); 
        Route::post('/admin/brands/store', [ApiAdminController::class, 'storeBrand']);
        Route::put('/admin/brands/update/{id}', [ApiAdminController::class, 'updateBrand']);
        Route::delete('/admin/brands/delete/{id}', [ApiAdminController::class, 'destroyBrand']);

        // Manajemen Pesanan & Transaksi
        Route::get('/orders', [ApiAdminController::class, 'getOrders']);
        Route::get('/orders/{id}', [ApiAdminController::class, 'getOrderDetail']);
        Route::put('/orders/update-status/{id}', [ApiAdminController::class, 'updateOrderStatus']);

        // CRUD Kupon Diskon
        Route::get('/coupons', [ApiAdminController::class, 'getCoupons']);
        Route::post('/coupons/store', [ApiAdminController::class, 'storeCoupon']);
        Route::delete('/coupons/delete/{id}', [ApiAdminController::class, 'deleteCoupon']);

        // Slide Banner, Kontak & Pengaturan
        Route::get('/slides', [ApiAdminController::class, 'getSlides']);
        Route::get('/contacts', [ApiAdminController::class, 'getContacts']);
        Route::put('/contacts/read/{id}', [ApiAdminController::class, 'markContactRead']);
        Route::get('/settings/whatsapp', [ApiAdminController::class, 'getWhatsappSettings']);
        Route::put('/settings/whatsapp/update', [ApiAdminController::class, 'updateWhatsappSettings']);
    });
});
