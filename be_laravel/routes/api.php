<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ApiAuthController;
use App\Http\Controllers\Api\ApiProductController;
use App\Http\Controllers\Api\ApiCartController;
use App\Http\Controllers\Api\ApiCheckoutController;
use App\Http\Controllers\Api\ApiOrderController;
use App\Http\Controllers\Api\ApiRajaOngkirController;
use App\Http\Controllers\Api\ApiWishlistController; // Gunakan controller khusus API

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
});