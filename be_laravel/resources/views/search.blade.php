
@extends('layouts.app')

@section('content')
    {{-- Style ini disalin dari shop.blade.php untuk konsistensi --}}
    <style>
        .filled-heart { color: orange; }
        .product-card { border: none; background-color: transparent; text-align: left; }
        .pc__img-wrapper { position: relative; overflow: hidden; border-radius: 8px; }
        .pc__badge { position: absolute; bottom: 10px; left: 10px; background-color: #d9534f; color: white; padding: 4px 10px; font-size: 12px; font-weight: 700; border-radius: 4px; z-index: 2; }
        .pc__info { padding-top: 12px; }
        .pc__title { font-size: 1rem; font-weight: 600; margin-bottom: 4px; line-height: 1.3; }
        .pc__title a { text-decoration: none; color: #222; }
        .pc__title a:hover { text-decoration: underline; }
        .pc__category { font-size: 0.85rem; color: #6c757d; margin-bottom: 8px; text-transform: uppercase; }
        .product-card__price .price { font-size: 1rem; font-weight: 700; color: #d9534f; }
        .product-card__price .price-old { font-size: 0.9rem; font-weight: 400; color: #6c757d; margin-left: 8px; }
        .pc__btn-wl { position: static; padding-left: 10px; }
    </style>

    <div class="mb-5"></div>
    <section class="shop-main container">
        {{-- Judul Halaman Hasil Pencarian --}}
        <div class="text-center mb-4 pb-md-2">
            <h2 class="text-uppercase fw-bold">Hasil Pencarian untuk: "{{ $query }}"</h2>
            <p>{{ $products->total() }} produk ditemukan</p>
        </div>

        <div class="products-grid row row-cols-1 row-cols-md-2 row-cols-lg-3 row-cols-xl-4">
            @forelse ($products as $product)
                <div class="product-card-wrapper">
                    <div class="product-card mb-3 mb-md-4 mb-xxl-5">
                        <div class="pc__img-wrapper">
                            <a href="{{ route('shop.product.details', ['product_slug' => $product->slug]) }}">
                                <img loading="lazy"
                                    src="{{ asset('uploads/products') }}/{{ $product->image }}"
                                    width="660" height="800" alt="{{ $product->name }}"
                                    class="pc__img img-fluid">
                            </a>
                            @if ($product->sale_price > 0 && $product->regular_price > 0)
                                @php
                                    $discount = round((($product->regular_price - $product->sale_price) / $product->regular_price) * 100);
                                @endphp
                                <div class="pc__badge">{{ $discount }}% OFF</div>
                            @endif
                        </div>

                        <div class="pc__info d-flex justify-content-between align-items-start">
                            <div class="pc__info-content">
                                <h6 class="pc__title">
                                    <a href="{{ route('shop.product.details', ['product_slug' => $product->slug]) }}">{{ $product->name }}</a>
                                </h6>
                                <p class="pc__category">{{ $product->category->name }}</p>
                                <div class="product-card__price">
                                    @if ($product->sale_price > 0)
                                        <span class="money price">Rp {{ number_format($product->sale_price, 0, ',', '.') }}</span>
                                        <del class="money price-old">Rp {{ number_format($product->regular_price, 0, ',', '.') }}</del>
                                    @else
                                        <span class="money price text-dark">Rp {{ number_format($product->regular_price, 0, ',', '.') }}</span>
                                    @endif
                                </div>
                            </div>
                            <div class="pc__actions">
                                @php
                                    $inWishlist = auth()->check() && \App\Models\Wishlist::where('user_id', auth()->id())->where('product_id', $product->id)->exists();
                                @endphp
                                @if ($inWishlist)
                                    <form action="{{ route('wishlist.item.remove', ['product_id' => $product->id]) }}" method="POST">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="pc__btn-wl bg-transparent border-0 js-add-wishlist filled-heart" title="Remove from Wishlist">
                                            <svg width="16" height="16" viewBox="0 0 20 20" fill="none"><use href="#icon_heart" /></svg>
                                        </button>
                                    </form>
                                @else
                                    <form action="{{ route('wishlist.add') }}" method="POST">
                                        @csrf
                                        <input type="hidden" name="id" value="{{ $product->id }}">
                                        <button type="submit" class="pc__btn-wl bg-transparent border-0 js-add-wishlist" title="Add To Wishlist">
                                            <svg width="16" height="16" viewBox="0 0 20 20" fill="none"><use href="#icon_heart" /></svg>
                                        </button>
                                    </form>
                                @endif
                            </div>
                        </div>
                    </div>
                </div>
            @empty
                <div class="col-12 text-center">
                    <p>Mohon maaf, tidak ada produk yang ditemukan untuk pencarian Anda.</p>
                </div>
            @endforelse
        </div>

        {{-- Link Paginasi --}}
        <div class="d-flex justify-content-center mt-4">
            {{ $products->links('pagination::bootstrap-5') }}
        </div>
    </section>
@endsection