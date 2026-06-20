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
use App\Http\Controllers\Api\ApiAdminController;
use App\Http\Controllers\Api\ApiMarketplaceController;
use App\Http\Controllers\Api\ApiUserProfileController;
use App\Http\Controllers\MidtransController;
use App\Http\Controllers\Api\ApiPaymentMethodController;

Route::post('/register', [ApiAuthController::class, 'register']);
Route::post('/login', [ApiAuthController::class, 'login']);

Route::get('/products', [ApiProductController::class, 'index']);
Route::get('/products/{slug}', [ApiProductController::class, 'show']);
Route::get('/stores/{slug}', [ApiMarketplaceController::class, 'storeDetail']);
Route::get('/products/{productId}/reviews', [ApiMarketplaceController::class, 'productReviews']);
Route::post('/midtrans/notification', [MidtransController::class, 'notificationHandler']);
Route::get('/payment-methods', [ApiPaymentMethodController::class, 'index']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [ApiAuthController::class, 'logout']);
    Route::get('/user-profile', function (Request $request) {
        return response()->json($request->user());
    });
    Route::put('/user-profile', [ApiUserProfileController::class, 'updateAccount']);
    Route::post('/user-profile/photo', [ApiUserProfileController::class, 'updatePhoto']);

    Route::get('/cart', [ApiCartController::class, 'index']);
    Route::post('/cart/add', [ApiCartController::class, 'add']);
    Route::delete('/cart/remove/{id}', [ApiCartController::class, 'remove']);

    Route::post('/checkout', [ApiCheckoutController::class, 'checkout']);
    Route::get('/orders', [ApiOrderController::class, 'index']);

    Route::get('/marketplace/my-store', [ApiMarketplaceController::class, 'myStore']);
    Route::post('/marketplace/my-store', [ApiMarketplaceController::class, 'saveStore']);
    Route::get('/marketplace/seller-orders', [ApiMarketplaceController::class, 'sellerOrders']);
    Route::put('/marketplace/seller-orders/{id}/status', [ApiMarketplaceController::class, 'updateSellerOrderStatus']);
    Route::post('/marketplace/reviews', [ApiMarketplaceController::class, 'addReview']);
    Route::get('/marketplace/chats', [ApiMarketplaceController::class, 'conversations']);
    Route::post('/marketplace/chats/start', [ApiMarketplaceController::class, 'startConversation']);
    Route::get('/marketplace/chats/{conversationId}/messages', [ApiMarketplaceController::class, 'messages']);
    Route::post('/marketplace/chats/{conversationId}/messages', [ApiMarketplaceController::class, 'sendMessage']);

    Route::get('/wishlist', [ApiWishlistController::class, 'index']);
    Route::post('/wishlist/add', [ApiWishlistController::class, 'add']);
    Route::delete('/wishlist/remove/{product_id}', [ApiWishlistController::class, 'remove']);

    Route::get('/rajaongkir/provinces', [ApiRajaOngkirController::class, 'getProvinces']);
    Route::get('/rajaongkir/cities/{provinceId}', [ApiRajaOngkirController::class, 'getCities']);
    Route::get('/rajaongkir/subdistricts/{cityId}', [ApiRajaOngkirController::class, 'getSubdistricts']);
    Route::post('/rajaongkir/cost', [ApiRajaOngkirController::class, 'checkCost']);

    Route::get('/admin/store-location', [ApiAdminController::class, 'getStoreLocation']);
    Route::post('/admin/store-location', [ApiAdminController::class, 'saveStoreLocation']);

    Route::get('/user/addresses', [ApiAdminController::class, 'getUserAddresses']);
    Route::post('/user/addresses', [ApiAdminController::class, 'saveUserAddress']);
    Route::put('/user/addresses/{id}/set-main', [ApiAdminController::class, 'setMainAddress']);
    Route::delete('/user/addresses/{id}', [ApiAdminController::class, 'deleteUserAddress']);
    Route::get('/order/{id}/status', [\App\Http\Controllers\Api\ApiCheckoutController::class, 'checkStatus']);

    Route::middleware('admin')->prefix('admin')->group(function () {
        Route::get('/dashboard', [ApiAdminController::class, 'dashboardStats']);
        Route::get('/products', [ApiAdminController::class, 'getProducts']);
        Route::post('/products/store', [ApiAdminController::class, 'storeProduct']);
        Route::get('/products/{id}', [ApiAdminController::class, 'getProductDetail']);
        Route::put('/products/update/{id}', [ApiAdminController::class, 'updateProduct']);
        Route::post('/products/update/{id}', [ApiAdminController::class, 'updateProduct']);
        Route::delete('/products/delete/{id}', [ApiAdminController::class, 'deleteProduct']);

        Route::get('/categories', [ApiAdminController::class, 'getCategories']);
        Route::post('/categories/store', [ApiAdminController::class, 'storeCategory']);
        Route::put('/categories/update/{id}', [ApiAdminController::class, 'updateCategory']);
        Route::delete('/categories/delete/{id}', [ApiAdminController::class, 'deleteCategory']);

        Route::get('/brands', [ApiAdminController::class, 'getBrands']);
        Route::post('/brands/store', [ApiAdminController::class, 'storeBrand']);
        Route::put('/brands/update/{id}', [ApiAdminController::class, 'updateBrand']);
        Route::delete('/brands/delete/{id}', [ApiAdminController::class, 'deleteBrand']);

        Route::get('/orders', [ApiAdminController::class, 'getOrders']);
        Route::get('/orders/{id}', [ApiAdminController::class, 'getOrderDetail']);
        Route::put('/orders/update-status/{id}', [ApiAdminController::class, 'updateOrderStatus']);

        Route::get('/coupons', [ApiAdminController::class, 'getCoupons']);
        Route::post('/coupons/store', [ApiAdminController::class, 'storeCoupon']);
        Route::delete('/coupons/delete/{id}', [ApiAdminController::class, 'deleteCoupon']);

        Route::get('/slides', [ApiAdminController::class, 'getSlides']);
        Route::get('/contacts', [ApiAdminController::class, 'getContacts']);
        Route::put('/contacts/read/{id}', [ApiAdminController::class, 'markContactRead']);
        Route::get('/settings/whatsapp', [ApiAdminController::class, 'getWhatsappSettings']);
        Route::put('/settings/whatsapp/update', [ApiAdminController::class, 'updateWhatsappSettings']);
    });
});
