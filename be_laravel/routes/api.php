<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ApiAuthController;
use App\Http\Controllers\Api\ApiProductController;
use App\Http\Controllers\Api\ApiCartController;
use App\Http\Controllers\Api\ApiCheckoutController;
use App\Http\Controllers\Api\ApiOrderController;

// Rute Publik (Tanpa Token)
Route::post('/register', [ApiAuthController::class, 'register']);
Route::post('/login', [ApiAuthController::class, 'login']);
Route::get('/products', [ApiProductController::class, 'index']);
Route::get('/products/{slug}', [ApiProductController::class, 'show']);

// Rute Terproteksi (Wajib membawa Sanctum Token dari Flutter)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [ApiAuthController::class, 'logout']);
    Route::get('/user-profile', function (Request $request) {
        return response()->json($request->user());
    });

    // RUTE KERANJANG (CART)
    Route::get('/cart', [ApiCartController::class, 'index']);
    Route::post('/cart/add', [ApiCartController::class, 'add']);
    Route::delete('/cart/remove/{id}', [ApiCartController::class, 'remove']);

    // RUTE CHECKOUT BARU
    Route::post('/checkout', [ApiCheckoutController::class, 'process']);

    // RUTE RIWAYAT PESANAN
    Route::get('/orders', [ApiOrderController::class, 'index']);
});