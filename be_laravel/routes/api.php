<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use App\Models\Address;
use App\Models\About;
use App\Models\StoreProfile;
use App\Http\Controllers\Api\ApiAuthController;
use App\Http\Controllers\Api\ApiProductController;
use App\Http\Controllers\Api\ApiCartController;
use App\Http\Controllers\Api\ApiCheckoutController;
use App\Http\Controllers\Api\ApiOrderController;
use App\Http\Controllers\Api\ApiRajaOngkirController;
use App\Http\Controllers\Api\ApiWishlistController;
use App\Http\Controllers\Api\ApiAdminController;
use App\Http\Controllers\Api\ApiMarketplaceController;
use App\Http\Controllers\Api\ApiMarketplaceChatController;
use App\Http\Controllers\Api\ApiUserProfileController;
use App\Http\Controllers\Api\ApiMediaController;
use App\Http\Controllers\Api\ApiProductVariationImageController;
use App\Http\Controllers\MidtransController;
use App\Http\Controllers\Api\ApiPaymentMethodController;

Route::post('/register', [ApiAuthController::class, 'register']);
Route::post('/login', [ApiAuthController::class, 'login']);

Route::get('/products', [ApiProductController::class, 'index']);
Route::get('/products/{slug}', [ApiProductController::class, 'show']);
Route::get('/product-image/{filename}', [ApiMediaController::class, 'productImage']);
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
    Route::post('/checkout/finalize', [ApiCheckoutController::class, 'finalize']);
    Route::get('/orders/{id}', [ApiCheckoutController::class, 'show']);
    Route::post('/orders/{id}/payment-method', [ApiCheckoutController::class, 'setPaymentMethod']);
    Route::post('/orders/{id}/reset-payment', [ApiCheckoutController::class, 'resetPayment']);
    Route::post('/orders/{id}/complete-checkout', [ApiCheckoutController::class, 'completeCheckout']);
    Route::post('/orders/{id}/cancel', [\App\Http\Controllers\Api\ApiOrderCancelController::class, 'cancel']);
    Route::get('/orders', [ApiOrderController::class, 'index']);

    Route::get('/marketplace/my-store', [ApiMarketplaceController::class, 'myStore']);
    Route::post('/marketplace/my-store', [ApiMarketplaceController::class, 'saveStore']);
    Route::get('/marketplace/seller-orders', [ApiMarketplaceController::class, 'sellerOrders']);
    Route::put('/marketplace/seller-orders/{id}/status', [ApiMarketplaceController::class, 'updateSellerOrderStatus']);
    Route::post('/marketplace/reviews', [ApiMarketplaceController::class, 'addReview']);
    Route::get('/marketplace/chats', [ApiMarketplaceChatController::class, 'conversations']);
    Route::post('/marketplace/chats/start', [ApiMarketplaceChatController::class, 'startConversation']);
    Route::get('/marketplace/chats/{conversationId}/messages', [ApiMarketplaceChatController::class, 'messages']);
    Route::post('/marketplace/chats/{conversationId}/messages', [ApiMarketplaceChatController::class, 'sendMessage']);

    Route::get('/wishlist', [ApiWishlistController::class, 'index']);
    Route::post('/wishlist/add', [ApiWishlistController::class, 'add']);
    Route::delete('/wishlist/remove/{product_id}', [ApiWishlistController::class, 'remove']);

    Route::get('/rajaongkir/provinces', [ApiRajaOngkirController::class, 'getProvinces']);
    Route::get('/rajaongkir/cities/{provinceId}', [ApiRajaOngkirController::class, 'getCities']);
    Route::get('/rajaongkir/subdistricts/{cityId}', [ApiRajaOngkirController::class, 'getSubdistricts']);
    Route::post('/rajaongkir/cost', [ApiRajaOngkirController::class, 'checkCost']);

    Route::get('/admin/store-location', function () {
        $location = Address::where('user_id', auth()->id())
            ->where('is_store_address', true)
            ->latest()
            ->first();

        return response()->json(['success' => (bool) $location, 'data' => $location], 200);
    });

    Route::post('/admin/store-location', function (Request $request) {
        $request->validate([
            'province_id' => 'required',
            'city_id' => 'required',
            'district_id' => 'required',
        ]);

        $address = DB::transaction(function () use ($request) {
            $address = $request->filled('address_id')
                ? Address::where('user_id', auth()->id())->findOrFail($request->address_id)
                : (Address::where('user_id', auth()->id())->where('is_store_address', true)->first() ?: new Address());

            Address::where('user_id', auth()->id())
                ->when($address->exists, fn ($q) => $q->where('id', '!=', $address->id))
                ->update(['is_store_address' => false]);

            $address->user_id = auth()->id();
            $address->name = trim((string) ($request->name ?? auth()->user()->name));
            $address->phone = trim((string) ($request->phone ?? '0'));
            $address->province_id = $request->province_id;
            $address->city_id = $request->city_id;
            $address->district_id = $request->district_id;
            $address->province_name = $request->province_name ?? '-';
            $address->city_name = $request->city_name ?? '-';
            $address->district_name = $request->kecamatan ?? $request->district_name ?? '-';
            $address->address = $request->detail_address ?? $request->address ?? '-';
            $address->locality = $request->kecamatan ?? $request->district_name ?? '-';
            $address->landmark = $request->landmark ?? '-';
            $address->postal_code = $request->postal_code ?? '00000';
            $address->zip = $request->postal_code ?? '00000';
            $address->city = $address->city_name;
            $address->state = $address->province_name;
            $address->country = 'Indonesia';
            $address->type = 'store';
            $address->latitude = $request->latitude;
            $address->longitude = $request->longitude;
            $address->note = $request->note;
            $address->label = 'Toko';
            $address->isdefault = false;
            $address->is_store_address = true;
            $address->save();

            $store = StoreProfile::firstOrCreate(
                ['user_id' => auth()->id()],
                [
                    'name' => auth()->user()->name . ' Store',
                    'slug' => Str::slug(auth()->user()->name . '-' . auth()->id()),
                    'status' => 'active',
                ]
            );
            $area = collect([$address->locality, $address->city_name, $address->province_name])
                ->filter(fn ($item) => ! empty($item) && $item !== '-')
                ->implode(', ');
            $store->address = trim($address->address . ($area ? ', ' . $area : ''));
            $store->phone = $address->phone ?: $store->phone;
            $store->province_name = $address->province_name ?: $store->province_name;
            $store->city_name = $address->city_name ?: $store->city_name;
            if ($address->latitude && $address->longitude) {
                $store->maps_url = 'https://www.google.com/maps/search/?api=1&query=' . $address->latitude . ',' . $address->longitude;
            }
            $store->save();

            $about = About::first() ?: new About();
            $usesKomerce = str_contains(config('rajaongkir.base_url', ''), 'komerce');
            $about->province_id = $address->province_id;
            $about->city_id = $usesKomerce ? $address->district_id : $address->city_id;
            $about->district_id = $address->district_id;
            $about->save();

            return $address->fresh();
        });

        return response()->json(['success' => true, 'message' => 'Alamat toko berhasil disimpan dan dipakai sebagai origin ongkir.', 'data' => $address], 200);
    });

    Route::get('/user/addresses', function (Request $request) {
        $includeStore = filter_var($request->query('include_store', false), FILTER_VALIDATE_BOOLEAN);
        $query = Address::where('user_id', auth()->id());
        if (! $includeStore) {
            $query->where(function ($q) {
                $q->whereNull('is_store_address')->orWhere('is_store_address', false);
            });
        }

        $addresses = $query
            ->orderBy('isdefault', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['success' => true, 'data' => $addresses], 200);
    });

    Route::post('/user/addresses', function (Request $request) {
        $request->validate([
            'province_id' => 'required',
            'city_id' => 'required',
            'district_id' => 'required',
        ]);

        $isStore = filter_var($request->input('is_store'), FILTER_VALIDATE_BOOLEAN) || filter_var($request->input('is_store_address'), FILTER_VALIDATE_BOOLEAN);
        if ($isStore) {
            $address = DB::transaction(function () use ($request) {
                $address = $request->filled('address_id')
                    ? Address::where('user_id', auth()->id())->findOrFail($request->address_id)
                    : (Address::where('user_id', auth()->id())->where('is_store_address', true)->first() ?: new Address());

                Address::where('user_id', auth()->id())
                    ->when($address->exists, fn ($q) => $q->where('id', '!=', $address->id))
                    ->update(['is_store_address' => false]);

                $address->user_id = auth()->id();
                $address->name = trim((string) ($request->name ?? auth()->user()->name));
                $address->phone = trim((string) ($request->phone ?? '0'));
                $address->province_id = $request->province_id;
                $address->city_id = $request->city_id;
                $address->district_id = $request->district_id;
                $address->province_name = $request->province_name ?? '-';
                $address->city_name = $request->city_name ?? '-';
                $address->district_name = $request->kecamatan ?? $request->district_name ?? '-';
                $address->address = $request->detail_address ?? $request->address ?? '-';
                $address->locality = $request->kecamatan ?? $request->district_name ?? '-';
                $address->landmark = $request->landmark ?? '-';
                $address->postal_code = $request->postal_code ?? '00000';
                $address->zip = $request->postal_code ?? '00000';
                $address->city = $address->city_name;
                $address->state = $address->province_name;
                $address->country = 'Indonesia';
                $address->type = 'store';
                $address->latitude = $request->latitude;
                $address->longitude = $request->longitude;
                $address->note = $request->note;
                $address->label = 'Toko';
                $address->isdefault = false;
                $address->is_store_address = true;
                $address->save();

                $about = About::first() ?: new About();
                $usesKomerce = str_contains(config('rajaongkir.base_url', ''), 'komerce');
                $about->province_id = $address->province_id;
                $about->city_id = $usesKomerce ? $address->district_id : $address->city_id;
                $about->district_id = $address->district_id;
                $about->save();

                return $address->fresh();
            });

            return response()->json(['success' => true, 'message' => 'Alamat toko berhasil disimpan.', 'data' => $address], 200);
        }

        $isMain = filter_var($request->input('is_main'), FILTER_VALIDATE_BOOLEAN) || filter_var($request->input('isdefault'), FILTER_VALIDATE_BOOLEAN);

        $address = DB::transaction(function () use ($request, $isMain) {
            if ($isMain) {
                Address::where('user_id', auth()->id())
                    ->where(function ($q) {
                        $q->whereNull('is_store_address')->orWhere('is_store_address', false);
                    })
                    ->update(['isdefault' => false]);
            }

            $address = $request->filled('address_id')
                ? Address::where('user_id', auth()->id())->findOrFail($request->address_id)
                : new Address();

            $address->user_id = auth()->id();
            $address->name = trim((string) ($request->name ?? auth()->user()->name));
            $address->phone = trim((string) ($request->phone ?? '0'));
            $address->province_id = $request->province_id;
            $address->city_id = $request->city_id;
            $address->district_id = $request->district_id;
            $address->province_name = $request->province_name ?? '-';
            $address->city_name = $request->city_name ?? '-';
            $address->district_name = $request->kecamatan ?? $request->district_name ?? '-';
            $address->address = $request->detail_address ?? $request->address ?? '-';
            $address->locality = $request->kecamatan ?? $request->district_name ?? '-';
            $address->landmark = $request->landmark ?? '-';
            $address->postal_code = $request->postal_code ?? '00000';
            $address->zip = $request->postal_code ?? '00000';
            $address->city = $address->city_name;
            $address->state = $address->province_name;
            $address->country = 'Indonesia';
            $address->type = 'home';
            $address->latitude = $request->latitude;
            $address->longitude = $request->longitude;
            $address->note = $request->note;
            $address->label = $request->label ?? 'Rumah';
            $address->isdefault = $isMain;
            $address->is_store_address = false;
            $address->save();

            $normalAddressCount = Address::where('user_id', auth()->id())
                ->where(function ($q) {
                    $q->whereNull('is_store_address')->orWhere('is_store_address', false);
                })
                ->count();

            if ($normalAddressCount === 1) {
                $address->isdefault = true;
                $address->save();
            }

            return $address->fresh();
        });

        return response()->json(['success' => true, 'message' => 'Alamat disimpan.', 'data' => $address], 200);
    });

    Route::put('/user/addresses/{id}/set-main', function ($id) {
        $address = Address::where('user_id', auth()->id())
            ->where(function ($q) {
                $q->whereNull('is_store_address')->orWhere('is_store_address', false);
            })
            ->findOrFail($id);

        Address::where('user_id', auth()->id())
            ->where(function ($q) {
                $q->whereNull('is_store_address')->orWhere('is_store_address', false);
            })
            ->update(['isdefault' => false]);

        $address->isdefault = true;
        $address->save();
        return response()->json(['success' => true, 'message' => 'Alamat utama diubah.'], 200);
    });

    Route::delete('/user/addresses/{id}', function ($id) {
        $address = Address::where('user_id', auth()->id())->findOrFail($id);
        $wasMain = (bool) $address->isdefault;
        $wasStore = (bool) $address->is_store_address;
        $address->delete();

        if ($wasMain && ! $wasStore) {
            $replacement = Address::where('user_id', auth()->id())
                ->where(function ($q) {
                    $q->whereNull('is_store_address')->orWhere('is_store_address', false);
                })
                ->latest()
                ->first();
            if ($replacement) {
                $replacement->isdefault = true;
                $replacement->save();
            }
        }

        return response()->json(['success' => true, 'message' => 'Alamat dihapus'], 200);
    });
    Route::get('/order/{id}/status', [ApiCheckoutController::class, 'checkStatus']);

    Route::middleware('admin')->prefix('admin')->group(function () {
        Route::get('/dashboard', [ApiAdminController::class, 'dashboardStats']);
        Route::get('/products', [ApiAdminController::class, 'getProducts']);
        Route::post('/products/store', [ApiAdminController::class, 'storeProduct']);
        Route::get('/products/{id}', [ApiAdminController::class, 'getProductDetail']);
        Route::put('/products/update/{id}', [ApiAdminController::class, 'updateProduct']);
        Route::post('/products/update/{id}', [ApiAdminController::class, 'updateProduct']);
        Route::delete('/products/delete/{id}', [ApiAdminController::class, 'deleteProduct']);
        Route::post('/product-variations/{id}/image', [ApiProductVariationImageController::class, 'update']);

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
