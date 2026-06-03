<?php

use App\Http\Controllers\AddressController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\CartController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\ShopController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\WishlistController;
use App\Http\Controllers\MidtransController;
use App\Http\Middleware\AuthAdmin;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;
use Surfsidemedia\Shoppingcart\Facades\Cart;
use App\Http\Controllers\GoogleController;
use App\Http\Controllers\WhatsappSettingController;
use App\Http\Controllers\RajaOngkirController;
use App\Http\Controllers\CouponController;

// routes/web.php
Route::post('/apply-coupon', [CartController::class, 'apply_coupon_code'])
    ->name('cart.apply_coupon_code');
Route::get('/kupon', [CouponController::class, 'publicIndex'])->name('home.kupon');

Route::post('/shipping/cost', [\App\Http\Controllers\CartController::class, 'calculateShipping'])
    ->name('shipping.cost');

Route::prefix('ro')->name('ro.')->group(function () {
    Route::get('/provinces', [RajaOngkirController::class, 'getProvinces'])->name('provinces');
    Route::get('/cities/{provinceId}', [RajaOngkirController::class, 'getCities'])->name('cities');
    Route::get('/districts/{cityId}', [RajaOngkirController::class, 'getDistricts'])->name('districts');
    Route::post('/check-ongkir', [RajaOngkirController::class, 'checkOngkir'])->name('check');
    Route::post('/ro/check-ongkir', [\App\Http\Controllers\RajaOngkirController::class, 'checkOngkir'])->name('ro.check');
});


Route::get('/', function () {
    return view('welcome');
});

Auth::routes();

Route::post('cart/checkout-selected', [CartController::class, 'checkoutSelected'])->name('cart.checkout.selected');

Route::get('/home', [HomeController::class, 'index'])->name('home');

Route::get('auth/google', [GoogleController::class, 'redirectToGoogle'])->name('google.login');
Route::get('google/callback', [GoogleController::class, 'handleGoogleCallback'])->name('google.callback');

Route::get('/shop/search', [ShopController::class, 'search'])->name('shop.search');

Route::get('/', [HomeController::class, 'index'])->name('home.index');
Route::get('/shop', [ShopController::class, 'index'])->name('shop.index');
Route::get('/shop/{product_slug}', [ShopController::class, 'product_details'])->name('shop.product.details');

Route::get('/cart', [CartController::class, 'index'])->name('cart.index');
Route::post('/cart/add', [CartController::class, 'add_to_cart'])->name('cart.add');
Route::put('/cart/update/{id}', [CartController::class, 'updateQty'])->name('cart.qty.update');
Route::put('/cart/increase-quantity/{id}', [CartController::class, 'increase_cart_quantity'])->name('cart.qty.increase');
Route::put('/cart/decrease-quantity/{id}', [CartController::class, 'decrease_cart_quantity'])->name('cart.qty.decrease');
Route::delete('/cart/remove/{id}', [CartController::class, 'remove_item'])->name('cart.item.remove');
Route::delete('/cart/clear', [CartController::class, 'empty_cart'])->name('cart.empty');
Route::post('/checkout/cancel-order', [App\Http\Controllers\CartController::class, 'cancelPendingOrder'])->name('cart.order.cancel')->middleware('auth');
// --- RUTE BARU DITAMBAHKAN DI SINI ---
Route::post('/buy-now', [CartController::class, 'buyNow'])->name('buy.now');
// ------------------------------------

Route::post('/cart/apply-coupon', [CartController::class, 'apply_coupon_code'])->name('cart.coupon.apply');
Route::delete('/cart/remove-coupon', [CartController::class, 'remove_coupon_code'])->name('cart.coupon.remove');

Route::get('/wishlist', [WishlistController::class, 'index'])->name('wishlist.index');
Route::post('/wishlist/add', [WishlistController::class, 'add_to_wishlist'])->name('wishlist.add');
Route::delete('/wishlist/item/remove/{product_id}', [WishlistController::class, 'remove_item'])->name('wishlist.item.remove');
Route::delete('/wishlist/clear', [WishlistController::class, 'empty_wishlist'])->name('wishlist.clear');
Route::post('/wishlist/move-to-cart/{id}', [WishlistController::class, 'move_to_cart'])->name('wishlist.move.to.cart');

Route::get('/checkout', [CartController::class, 'checkout'])->name('cart.checkout');
Route::post('/place-an-order', [CartController::class, 'place_an_order'])->name('cart.place.an.order');
Route::get('/order-confirmation', [CartController::class, 'order_confirmation'])->name('cart.order.confirmation');
Route::post('/midtrans/notification', [MidtransController::class, 'notificationHandler']);
Route::post('/payment/success', [App\Http\Controllers\CartController::class, 'paymentSuccess'])->name('payment.success');

Route::post('/checkout/cancel-order', [App\Http\Controllers\CartController::class, 'cancelPendingOrder'])->name('cart.order.cancel')->middleware('auth');

// Rute untuk halaman Bantuan
Route::get('/help', [HomeController::class, 'help'])->name('home.help');
Route::get('/help/{category}', [App\Http\Controllers\HomeController::class, 'showHelpCategory'])->name('help.category');

// Rute untuk halaman Kontak (terpisah)
Route::get('/contact-us', [HomeController::class, 'contact'])->name('home.contact');
Route::get('/admin/contact/{id}/details', [AdminController::class, 'contact_details'])->name('admin.contact.details');
Route::post('/contact/store', [HomeController::class, 'contact_store'])->name('home.contact.store');

Route::get('/search', [HomeController::class, 'search'])->name('home.search');

Route::get('/about', [HomeController::class, 'about'])->name('home.about');
Route::get('/welcome', [HomeController::class, 'welcome'])->name('home.welcome');

Route::middleware(['auth'])->group(function () {
    Route::post('/cart/coupon', [CartController::class, 'apply_coupon_code'])->name('cart.coupon.apply');
    Route::delete('/cart/coupon/remove', [CartController::class, 'remove_coupon_code'])->name('cart.coupon.remove');
    Route::get('/account-dashboard', [UserController::class, 'index'])->name('user.index');
    Route::get('/account-orders', [UserController::class, 'orders'])->name('user.orders');
    Route::get('/account-orders/{order_id}/details', [UserController::class, 'order_details'])->name('user.order.details');
    Route::put('/account-orders/cancel-order', [UserController::class, 'order_cancel'])->name('user.order.cancel');
    Route::get('/admin/orders/search', [AdminController::class, 'search_orders'])->name('admin.order.search');

    Route::get('/address', [AddressController::class, 'index'])->name('user.address.index');
    Route::get('/address/add', [AddressController::class, 'address_add'])->name('user.address.add');
    Route::post('/address/store', [AddressController::class, 'address_store'])->name('user.address.store');
    Route::get('/address/{id}/edit', [AddressController::class, 'address_edit'])->name('user.address.edit');
    Route::put('/address/{id}/update', [AddressController::class, 'address_update'])->name('user.address.update');
    Route::delete('/address/{id}/delete', [AddressController::class, 'address_delete'])->name('user.address.delete');
});

Route::middleware(['auth', AuthAdmin::class])->group(function () {
    Route::get('/admin', [AdminController::class, 'index'])->name('admin.index');
    Route::get('/admin/brands', [AdminController::class, 'brands'])->name('admin.brands');
    Route::get('/admin/brand/add', [AdminController::class, 'brand_add'])->name('admin.brand.add');
    Route::post('/admin/brand/store', [AdminController::class, 'brand_store'])->name('admin.brand.store');
    Route::get('/admin/brand/{id}/edit', [AdminController::class, 'brand_edit'])->name('admin.brand.edit');
    Route::put('/admin/brand/update', [AdminController::class, 'brand_update'])->name('admin.brand.update');
    Route::delete('/admin/brand/{id}/delete', [AdminController::class, 'brand_delete'])->name('admin.brand.delete');
    Route::get('/admin/brands/search', [AdminController::class, 'search_brands'])->name('admin.brand.search');

    Route::get('/admin/categories', [AdminController::class, 'categories'])->name('admin.categories');
    Route::get('/admin/category/add', [AdminController::class, 'add_category'])->name('admin.category.add');
    Route::post('/admin/category/store', [AdminController::class, 'category_store'])->name('admin.category.store');
    Route::get('/admin/category/{id}/edit', [AdminController::class, 'category_edit'])->name('admin.category.edit');
    Route::put('/admin/category/update', [AdminController::class, 'category_update'])->name('admin.category.update');
    Route::delete('/admin/category/{id}/delete', [AdminController::class, 'category_delete'])->name('admin.category.delete');
    Route::get('/admin/categories/search', [AdminController::class, 'search_category'])->name('admin.category.search');

    Route::get('/admin/products', [AdminController::class, 'products'])->name('admin.products');
    Route::get('/admin/product/add', [AdminController::class, 'product_add'])->name('admin.product.add');
    Route::post('/admin/product/store', [AdminController::class, 'product_store'])->name('admin.product.store');
    Route::get('/admin/product/{id}/edit', [AdminController::class, 'product_edit'])->name('admin.product.edit');
    Route::put('/admin/product/update', [AdminController::class, 'product_update'])->name('admin.product.update');
    Route::delete('/admin/product/{id}/delete', [AdminController::class, 'product_delete'])->name('admin.product.delete');
    Route::delete('/admin/product/delete-image', [AdminController::class, 'deleteProductImageAjax'])->name('admin.product.deleteImage.ajax');
    Route::get('/admin/products/search', [AdminController::class, 'search_products'])->name('admin.product.search');
    Route::get('/admin/get-brands-by-category', [AdminController::class, 'get_brands_by_category'])->name('admin.get_brands_by_category');

    Route::get('/admin/coupons', [AdminController::class, 'coupons'])->name('admin.coupons');
    Route::get('/admin/coupon/add', [AdminController::class, 'coupon_add'])->name('admin.coupon.add');
    Route::post('/admin/coupon/store', [AdminController::class, 'coupon_store'])->name('admin.coupon.store');
    Route::get('/admin/coupon/{id}/edit', [AdminController::class, 'coupon_edit'])->name('admin.coupon.edit');
    Route::put('/admin/coupon/update', [AdminController::class, 'coupon_update'])->name('admin.coupon.update');
    Route::delete('/admin/coupon/{id}/delete', [AdminController::class, 'coupon_delete'])->name('admin.coupon.delete');
    Route::get('/admin/coupons/search', [AdminController::class, 'search_coupons'])->name('admin.coupon.search');

    Route::get('/admin/orders', [AdminController::class, 'orders'])->name('admin.orders');
    Route::get('/admin/orders/report', [AdminController::class, 'orderReport'])->name('admin.orders.report');
    Route::get('/admin/orders/report/excel', [AdminController::class, 'exportExcel'])->name('admin.orders.report.excel');
    Route::get('/admin/orders/report/pdf', [AdminController::class, 'exportPdf'])->name('admin.orders.report.pdf');
    Route::get('/admin/order/{order_id}/details', [AdminController::class, 'order_details'])->name('admin.order.details');
    Route::put('/admin/order/update-status', [AdminController::class, 'update_order_status'])->name('admin.order.status.update');

    Route::get('/admin/slide', [AdminController::class, 'slides'])->name('admin.slides');
    Route::get('/admin/slide/add', [AdminController::class, 'slide_add'])->name('admin.slide.add');
    Route::post('/admin/slide/store', [AdminController::class, 'slide_store'])->name('admin.slide.store');
    Route::get('/admin/slide/{id}/edit', [AdminController::class, 'slide_edit'])->name('admin.slide.edit');
    Route::put('/admin/slide/update', [AdminController::class, 'slide_update'])->name('admin.slide.update');
    Route::delete('/admin/slide/{id}/delete', [AdminController::class, 'slide_delete'])->name('admin.slide.delete');

    Route::get('/admin/contact', [AdminController::class, 'contacts'])->name('admin.contacts');
    Route::delete('/admin/contact/{id}/delete', [AdminController::class, 'contact_delete'])->name('admin.contact.delete');

    Route::get('/admin/search', [AdminController::class, 'search'])->name('admin.search');

    Route::get('/admin/users', [AdminController::class, 'users'])->name('admin.users');
    Route::get('/admin/user/{user_id}/details', [AdminController::class, 'user_details'])->name('admin.user.details');
    Route::get('/admin/user/add', [AdminController::class, 'user_add'])->name('admin.user.add');
    Route::post('/admin/user/store', [AdminController::class, 'user_store'])->name('admin.user.store');
    Route::delete('/admin/user/delete/{id}', [AdminController::class, 'user_destroy'])->name('admin.user.destroy');
    Route::get('/admin/users/search', [AdminController::class, 'search_users'])->name('admin.user.search');
    Route::get('/admin/contacts/search', [AdminController::class, 'search_contacts'])->name('admin.contact.search');

    Route::get('/admin/about/edit', [AdminController::class, 'about_edit'])->name('admin.about.edit');
    Route::put('/admin/about/update', [AdminController::class, 'about_update'])->name('admin.about.update');

    // --- RUTE PENGATURAN WHATSAPP ---
    Route::get('/admin/whatsapp-settings', [WhatsappSettingController::class, 'edit'])->name('admin.whatsapp.edit');
    Route::put('/admin/whatsapp-settings', [WhatsappSettingController::class, 'update'])->name('admin.whatsapp.update');
});

Route::middleware(['auth'])->prefix('user')->name('user.')->group(function () {
    // Menampilkan halaman detail akun
    Route::get('/details', [UserController::class, 'details'])->name('details');

    // Memproses pembaruan profil (nama)
    Route::patch('/profile', [UserController::class, 'updateProfile'])->name('profile.update');

    // Memproses pembaruan kata sandi
    Route::put('/password', [UserController::class, 'updatePassword'])->name('password.update');

    // Anda bisa menambahkan route lain yang berhubungan dengan user di sini
    // seperti route untuk alamat, pesanan, dll.
});
