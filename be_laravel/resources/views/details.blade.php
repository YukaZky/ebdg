@extends('layouts.app')
@section('content')
    <style>
        /* Gaya untuk Nama Produk */
        .product-single__name {
            font-size: 2.25rem; /* Ukuran font diperbesar untuk penekanan */
            font-weight: 600;   /* Sedikit lebih tebal */
            margin-bottom: 1rem; /* Jarak bawah yang konsisten */
        }

        /* Gaya untuk Deskripsi Singkat di bawah nama */
        .product-single__short-desc-top {
            margin-bottom: 1.5rem; /* Jarak bawah setelah deskripsi singkat */
        }

        /* Gaya untuk Harga */
        .product-single__price .current-price {
            color: #dc3545;
            font-size: 1.75rem; /* Sedikit diperbesar */
            font-weight: 600;
        }

        .product-single__price .old-price {
            font-size: 1.2rem; /* Sedikit diperbesar agar lebih terbaca */
            margin-left: 0.5rem;
        }
        
        .discount-badge {
            background-color: #fce4e4;
            color: #dc3545;
            padding: 5px 10px; /* Padding disesuaikan */
            border-radius: 4px;
            font-size: 0.9em;
            font-weight: 600;
            margin-left: 12px;
        }

        /* Gaya untuk Kotak Kuantitas */
        .qty-selector {
            display: flex; /* Menggunakan flex untuk alignment internal */
            align-items: center;
            justify-content: space-between;
            border: 1px solid #e5e5e5;
            border-radius: 4px;
            width: 140px; /* Lebar disesuaikan */
            height: 50px; /* Tinggi disamakan dengan tombol */
        }
        .qty-selector .qty-btn {
            background: none;
            border: none;
            cursor: pointer;
            padding: 0 18px;
            font-size: 1.5rem;
            color: #777;
            height: 100%; /* Memastikan tombol +/- mengisi tinggi kotak */
        }
        .qty-selector .qty-input {
            border: none;
            text-align: center;
            width: 100%;
            font-size: 1.1rem;
            font-weight: 600;
            padding: 0;
            -moz-appearance: textfield;
        }
        .qty-selector .qty-input::-webkit-outer-spin-button,
        .qty-selector .qty-input::-webkit-inner-spin-button {
            -webkit-appearance: none;
            margin: 0;
        }

        /* Gaya Umum untuk Tombol Aksi */
        .btn-action-custom {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 0.75rem 1.5rem;
            font-weight: 600;
            transition: all 0.2s ease;
            text-decoration: none;
            height: 50px; /* Tinggi tombol disamakan dengan kotak kuantitas */
            flex-grow: 1; /* Membuat tombol mengisi sisa ruang */
        }

        /* Tombol "Masukkan Keranjang" & "Lihat Keranjang" */
        .btn-addtocart-custom, .btn-viewcart-custom {
            background-color: #ffffffff; /* Latar belakang diubah menjadi merah muda */
            border: 1px solid #000000;
            color: #000000;
        }
        .btn-addtocart-custom:hover, .btn-viewcart-custom:hover {
            background-color: #ffffffff; /* Warna hover sedikit lebih gelap */
            color: #000000;
        }

        /* Tombol "Beli Sekarang" */
        .btn-buynow-custom {
            background-color: #000000;
            border: 1px solid #000000;
            color: #ffffffff;
        }
        .btn-buynow-custom:hover {
            background-color: #000000;
            border-color: #000000;
            color: #ffffffff;
        }
        
        /* Gaya untuk Meta Info (SKU, Kategori, Stok) */
        .product-single__meta-info .meta-item {
            margin-bottom: 0.5rem;
        }
        .product-single__meta-info .meta-item label {
            font-weight: 600; /* Membuat label menjadi tebal */
            color: #555;
            margin-right: 8px;
        }
    </style>
    <main class="pt-4"> 
        <section class="product-single container">
            <div class="row">
                {{-- Bagian gambar kini menggunakan 5 dari 12 kolom --}}
                <div class="col-lg-5">
                    <div class="product-single__media" data-media-type="horizontal-thumbnail">
                        <div class="product-single__image">
                            <div class="swiper-container">
                                <div class="swiper-wrapper">
                                    <div class="swiper-slide product-single__image-item">
                                        <img loading="lazy" class="h-auto" src="{{ asset('uploads/products') }}/{{ $product->image }}" width="674" height="674" alt="{{ $product->name }}" />
                                        <a data-fancybox="gallery" href="{{ asset('uploads/products') }}/{{ $product->image }}" data-bs-toggle="tooltip" data-bs-placement="left" title="Zoom"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg"><use href="#icon_zoom" /></svg></a>
                                    </div>
                                    @if($product->images)
                                        @foreach (explode(',', $product->images) as $gimg)
                                            @if (trim($gimg) != '')
                                                <div class="swiper-slide product-single__image-item">
                                                    <img loading="lazy" class="h-auto" src="{{ asset('uploads/products') }}/{{ trim($gimg) }}" width="674" height="674" alt="{{ $product->name }} gallery image" />
                                                    <a data-fancybox="gallery" href="{{ asset('uploads/products') }}/{{ trim($gimg) }}" data-bs-toggle="tooltip" data-bs-placement="left" title="Zoom"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg"><use href="#icon_zoom" /></svg></a>
                                                </div>
                                            @endif
                                        @endforeach
                                    @endif
                                </div>
                                <div class="swiper-button-prev"><svg width="7" height="11" viewBox="0 0 7 11" xmlns="http://www.w3.org/2000/svg"><use href="#icon_prev_sm" /></svg></div>
                                <div class="swiper-button-next"><svg width="7" height="11" viewBox="0 0 7 11" xmlns="http://www.w3.org/2000/svg"><use href="#icon_next_sm" /></svg></div>
                            </div>
                        </div>
                        <div class="product-single__thumbnail">
                            <div class="swiper-container">
                                <div class="swiper-wrapper">
                                    <div class="swiper-slide product-single__image-item"><img loading="lazy" class="h-auto" src="{{ asset('uploads/products') }}/{{ $product->image }}" width="104" height="104" alt="{{ $product->name }}" /></div>
                                    @if($product->images)
                                        @foreach (explode(',', $product->images) as $gimg)
                                             @if (trim($gimg) != '')
                                                <div class="swiper-slide product-single__image-item"><img loading="lazy" class="h-auto" src="{{ asset('uploads/products') }}/{{ trim($gimg) }}" width="104" height="104" alt="{{ $product->name }} gallery thumbnail" /></div>
                                            @endif
                                        @endforeach
                                    @endif
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                {{-- Bagian detail produk kini menggunakan 7 dari 12 kolom --}}
                <div class="col-lg-7">
                    <h1 class="product-single__name">{{ $product->name }}</h1>
                    
                    <div class="product-single__short-desc-top">
                        <p>{!! $product->short_description !!}</p>
                    </div>

                    <div class="product-single__price d-flex align-items-center mb-4">
                        @if ($product->sale_price > 0)
                            <span class="current-price">Rp. {{ number_format($product->sale_price) }}</span>
                            <span class="old-price text-muted"><del>Rp. {{ number_format($product->regular_price) }}</del></span>
                             @php
                                $discount = round((($product->regular_price - $product->sale_price) / $product->regular_price) * 100);
                            @endphp
                            <span class="discount-badge">Diskon {{ $discount }}%</span>
                        @else
                            <span class="current-price">Rp. {{ number_format($product->regular_price) }}</span>
                        @endif
                    </div>
                    
                    @if ($product->quantity > 0)
                        @php
                            $inCart = auth()->check() && \App\Models\CartItem::where('user_id', auth()->id())->where('product_id', $product->id)->exists();
                        @endphp

                        @if ($inCart)
                            {{-- Tampilan SETELAH produk ada di keranjang --}}
                            <div class="mb-4">
                                <p>Produk ini sudah ada di keranjang Anda.</p>
                            </div>
                            <div class="d-flex gap-2">
                                <a href="{{ route('cart.index') }}" class="btn btn-viewcart-custom btn-action-custom flex-grow-1">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-cart-check" viewBox="0 0 16 16">
                                        <path d="M11.354 6.354a.5.5 0 0 0-.708-.708L8 8.293 6.854 7.146a.5.5 0 1 0-.708.708l1.5 1.5a.5.5 0 0 0 .708 0l3-3z"/>
                                        <path d="M.5 1a.5.5 0 0 0 0 1h1.11l.401 1.607 1.498 7.985A.5.5 0 0 0 4 12h1a2 2 0 1 0 0 4 2 2 0 0 0 0-4h7a2 2 0 1 0 0 4 2 2 0 0 0 0-4h1a.5.5 0 0 0 .491-.408l1.5-8A.5.5 0 0 0 14.5 3H2.89l-.405-1.621A.5.5 0 0 0 2 1H.5zm3.915 10L3.102 4h10.796l-1.313 7h-8.17zM6 14a1 1 0 1 1-2 0 1 1 0 0 1 2 0zm7 0a1 1 0 1 1-2 0 1 1 0 0 1 2 0z"/>
                                    </svg>
                                    Lihat Keranjang
                                </a>
                                <a href="{{ route('cart.checkout') }}" class="btn btn-buynow-custom btn-action-custom flex-grow-1">Beli Sekarang</a>
                            </div>
                        @else
                            {{-- Tampilan SEBELUM produk ada di keranjang --}}
                            <form name="addtocart-form" method="post" action="{{ route('cart.add') }}">
                                @csrf
                                <input type="hidden" name="id" value="{{ $product->id }}" />
                                
                                <div class="mb-3">
                                    <div class="qty-selector">
                                        <button type="button" class="qty-btn qty-decrease">-</button>
                                        <input type="number" class="qty-input" name="quantity" value="1" min="1" max="{{ $product->quantity }}">
                                        <button type="button" class="qty-btn qty-increase">+</button>
                                    </div>
                                </div>
                            
                                <div class="d-flex gap-2">
                                    <button type="submit" class="btn btn-addtocart-custom btn-action-custom">
                                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-cart" viewBox="0 0 16 16">
                                            <path d="M0 1.5A.5.5 0 0 1 .5 1H2a.5.5 0 0 1 .485.379L2.89 3H14.5a.5.5 0 0 1 .491.592l-1.5 8A.5.5 0 0 1 13 12H4a.5.5 0 0 1-.491-.408L2.01 3.607 1.61 2H.5a.5.5 0 0 1-.5-.5zM3.102 4l1.313 7h8.17l1.313-7H3.102zM5 12a2 2 0 1 0 0 4 2 2 0 0 0 0-4zm7 0a2 2 0 1 0 0 4 2 2 0 0 0 0-4zm-7 1a1 1 0 1 1 0 2 1 1 0 0 1 0-2zm7 0a1 1 0 1 1 0 2 1 1 0 0 1 0-2z"/>
                                        </svg>
                                        Masukkan Keranjang
                                    </button>
                                    
                                    {{-- Tombol ini akan menimpa 'action' dari form dan mengirimkannya ke route 'buy.now' --}}
                                    <button type="submit" class="btn btn-buynow-custom btn-action-custom" formaction="{{ route('buy.now') }}">
                                        Beli Sekarang
                                    </button>
                                </div>
                            </form>
                        @endif
                    @else
                        <button class="btn w-100" disabled style="background-color: #ccc; border-color: #ccc; cursor: not-allowed;">
                            Stok Habis
                        </button>
                    @endif

                    <div class="product-single__meta-info mt-4">
                        <div class="meta-item">
                            <label>SKU:</label>
                            <span>{{ $product->SKU }}</span>
                        </div>
                        <div class="meta-item">
                            <label>KATEGORI:</label>
                            <span>{{ $product->category->name }}</span>
                        </div>
                        <div class="meta-item">
                            <label>STOK:</label>
                            <span>{{ $product->quantity }}</span>
                        </div>
                    </div>

                    {{-- JUDUL DESKRIPSI DITAMBAHKAN DI SINI --}}
                    <h4 class="mt-4 fw-bold">Deskripsi :</h4>
                    <div class="product-single__description">
                        {!! $product->description !!}
                    </div>
                </div>
            </div>

            {{-- BAGIAN REVIEW DIHAPUS --}}

        </section>
        
        @if($related_products->count() > 0)
        <section class="products-carousel container pt-5">
            <h2 class="h3 text-uppercase mb-4 pb-xl-2 mb-xl-4"><strong>Produk </strong>Serupa</h2>
            <div id="related_products" class="position-relative">
                <div class="swiper-container js-swiper-slider" data-settings='{"autoplay": false, "slidesPerView": 4, "slidesPerGroup": 4, "loop": true, "pagination": {"el": "#related_products .products-pagination", "type": "bullets", "clickable": true}, "navigation": {"nextEl": "#related_products .products-carousel__next", "prevEl": "#related_products .products-carousel__prev"}, "breakpoints": {"320": {"slidesPerView": 2, "slidesPerGroup": 2, "spaceBetween": 14}, "768": {"slidesPerView": 3, "slidesPerGroup": 3, "spaceBetween": 24}, "992": {"slidesPerView": 4, "slidesPerGroup": 4, "spaceBetween": 30}}}'>
                    <div class="swiper-wrapper">
                        @foreach ($related_products as $rproduct)
                            <div class="swiper-slide product-card">
                                <div class="pc__img-wrapper"><a href="{{ route('shop.product.details', ['product_slug' => $rproduct->slug]) }}"><img loading="lazy" src="{{ asset('uploads/products') }}/{{ $rproduct->image }}" width="330" height="400" alt="{{ $rproduct->name }}" class="pc__img"></a></div>
                                <div class="pc__info position-relative">
                                    <h6 class="pc__title"><a href="{{ route('shop.product.details', ['product_slug' => $rproduct->slug]) }}">{{ $rproduct->name }}</a></h6>
                                    <div class="product-card__price d-flex">
                                        <span class="money price">
                                            @if ($rproduct->sale_price > 0)
                                                <del>Rp. {{ number_format($rproduct->regular_price) }}</del>
                                                <span class="text-danger">Rp. {{ number_format($rproduct->sale_price) }}</span>
                                            @else
                                                Rp. {{ number_format($rproduct->regular_price) }}
                                            @endif
                                        </span>
                                    </div>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
                <div class="products-carousel__prev position-absolute top-50 d-flex align-items-center justify-content-center"><svg width="25" height="25" viewBox="0 0 25 25" xmlns="http://www.w3.org/2000/svg"><use href="#icon_prev_md" /></svg></div>
                <div class="products-carousel__next position-absolute top-50 d-flex align-items-center justify-content-center"><svg width="25" height="25" viewBox="0 0 25 25" xmlns="http://www.w3.org/2000/svg"><use href="#icon_next_md" /></svg></div>
                <div class="products-pagination mt-4 mb-5 d-flex align-items-center justify-content-center"></div>
            </div>
        </section>
        @endif
    </main>
@endsection

@push('scripts')
<script>
    // Script untuk membuat tombol +/- pada kuantitas berfungsi
    document.addEventListener('DOMContentLoaded', function() {
        const qtySelector = document.querySelector('.qty-selector');
        if (qtySelector) {
            const decreaseBtn = qtySelector.querySelector('.qty-decrease');
            const increaseBtn = qtySelector.querySelector('.qty-increase');
            const input = qtySelector.querySelector('.qty-input');
            const min = parseInt(input.getAttribute('min'));
            const max = parseInt(input.getAttribute('max'));

            increaseBtn.addEventListener('click', function() {
                let currentValue = parseInt(input.value);
                if (currentValue < max) {
                    input.value = currentValue + 1;
                }
            });

            decreaseBtn.addEventListener('click', function() {
                let currentValue = parseInt(input.value);
                if (currentValue > min) {
                    input.value = currentValue - 1;
                }
            });
        }
    });
</script>
@endpush