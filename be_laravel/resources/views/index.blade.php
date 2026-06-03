@extends('layouts.app')

@section('content')
<style>
    /* CSS untuk Tombol WhatsApp */
    .whatsapp-float {
        position: fixed;
        width: 60px;
        height: 60px;
        bottom: 40px;
        right: 40px;
        background-color: #fff;
        border-radius: 50px;
        text-align: center;
        box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
        z-index: 1000;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: transform 0.3s ease-in-out;
    }

    .whatsapp-float:hover {
        transform: scale(1.1);
    }

    .whatsapp-icon {
        width: 35px;
        height: 35px;
    }

    /* Penyesuaian Tombol WhatsApp untuk Mobile */
    @media (max-width: 767px) {
        .whatsapp-float {
            width: 55px;
            height: 55px;
            bottom: 80px;
            /* Disesuaikan agar di atas footer mobile */
            right: 20px;
        }

        .whatsapp-icon {
            width: 30px;
            height: 30px;
        }
    }

    /* Default desktop */
    .slideshow .slideshow-character__img {
        max-height: 90vh;
        object-fit: contain;
    }

    /* Mobile khusus */
    @media (max-width: 768px) {
        .slideshow .slideshow-text h2 {
            font-size: 1.2rem;
            /* kecilkan judul */
            line-height: 1.3;
        }

        .slideshow .slideshow-text h6 {
            font-size: 0.8rem;
        }

        .slideshow .slideshow-text a {
            font-size: 0.8rem;
            padding: 6px 12px;
        }

        .slideshow .slideshow-character__img {
            max-height: 50vh;
        }
        .slideshow .container {
        padding: 0 15px;
    }
    .slideshow .row {
        margin: 0;
    }
    .slideshow .col-12 {
        padding: 0;
    }
    }

    .category-carousel .swiper-slide img {
        max-width: 120px;
        height: 120px;
        object-fit: cover;
        border-radius: 10px;
        margin: 0 auto 10px;
        display: block;
    }

    .category-carousel .swiper-slide .text-center {
        font-size: 1rem;
        line-height: 1.3;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }
</style>
<main>

    @if (isset($slides) && !$slides->isEmpty())
        <section class="swiper-container js-swiper-slider swiper-number-pagination slideshow" data-settings='{
                "autoplay": {
                "delay": 5000
                },
                "slidesPerView": 1,
                "effect": "fade",
                "loop": true
            }'>
            <div class="swiper-wrapper">
                @foreach ($slides as $slide)
                    <div class="swiper-slide">
                        <div class="container">
                            <div class="row align-items-center">
    <div class="col-12 col-md-6 text-center mb-4 mb-md-0">
        <img loading="lazy" src="{{ asset('uploads/slides') }}/{{ $slide->image }}"
            alt="{{ $slide->image }}"
            class="img-fluid slideshow-character__img animate animate_fade animate_btt animate_delay-9" />
        <div class="character_markup type2 mt-2 d-none d-md-block">
            <p
                class="text-uppercase font-sofia mark-grey-color animate animate_fade animate_btt animate_delay-10 mb-0">
                {{ $slide->tagline }}
            </p>
        </div>
    </div>

    <div class="col-12 col-md-6 slideshow-text text-start">
        <h6
            class="text_dash text-uppercase fw-medium animate animate_fade animate_btt animate_delay-3 mb-2">
            Produk Unggulan
        </h6>
        <h2 class="fw-normal animate animate_fade animate_btt animate_delay-5 mb-1">
            {{ $slide->title }}
        </h2>
        <h2 class="fw-bold animate animate_fade animate_btt animate_delay-5 mb-3">
            {{ $slide->subtitle }}
        </h2>
        <a href="{{ $slide->link }}"
            class="btn btn-primary px-3 py-2 animate animate_fade animate_btt animate_delay-7">
            Belanja Sekarang
        </a>
    </div>
</div>

                        </div>
                    </div>
                @endforeach
            </div>

            <div class="container">
                <div
                    class="slideshow-pagination slideshow-number-pagination d-flex align-items-center justify-content-center justify-content-md-start position-absolute bottom-0 mb-5">
                </div>
            </div>
        </section>
    @endif

    <div class="container mw-1620 bg-white border-radius-10">
        <div class="mb-3 mb-xl-5 pt-1 pb-4"></div>
        <section class="category-carousel container">
            <h2 class="section-title text-center mb-3 pb-xl-2 mb-xl-4">Mungkin Kamu Suka</h2>

            <div class="position-relative">
                <div class="swiper-container js-swiper-slider" data-settings='{
                        "autoplay": {
                            "delay": 5000
                        },
                        "slidesPerView": 8,
                        "slidesPerGroup": 1,
                        "effect": "none",
                        "loop": true,
                        "navigation": {
                            "nextEl": ".products-carousel__next-1",
                            "prevEl": ".products-carousel__prev-1"
                        },
                        "breakpoints": {
                            "320": {
                            "slidesPerView": 3,
                            "slidesPerGroup": 3,
                            "spaceBetween": 15
                            },
                            "768": {
                            "slidesPerView": 4,
                            "slidesPerGroup": 4,
                            "spaceBetween": 30
                            },
                            "992": {
                            "slidesPerView": 6,
                            "slidesPerGroup": 1,
                            "spaceBetween": 45,
                            "pagination": false
                            },
                            "1200": {
                            "slidesPerView": 8,
                            "slidesPerGroup": 1,
                            "spaceBetween": 60,
                            "pagination": false
                            }
                        }
                    }'>
                    <div class="swiper-wrapper">
                        @foreach ($categories as $category)
                            <div class="swiper-slide">
                                <a href="{{ route('shop.index', ['categories' => $category->id]) }}">
                                    <img loading="lazy"
                                        src="{{ asset('uploads/categories') }}/{{ $category->image }}" width="120"
                                        height="120" alt="{{ $category->name }}" />
                                    <div class="text-center">
                                        {{ $category->name }}
                                    </div>
                                </a>
                            </div>
                        @endforeach
                    </div>
                </div>
                <div
                    class="products-carousel__prev products-carousel__prev-1 position-absolute top-50 d-flex align-items-center justify-content-center">
                    <svg width="25" height="25" viewBox="0 0 25 25" xmlns="http://www.w3.org/2000/svg">
                        <use href="#icon_prev_md" />
                    </svg>
                </div>
                <div
                    class="products-carousel__next products-carousel__next-1 position-absolute top-50 d-flex align-items-center justify-content-center">
                    <svg width="25" height="25" viewBox="0 0 25 25" xmlns="http://www.w3.org/2000/svg">
                        <use href="#icon_next_md" />
                    </svg>
                </div>
            </div>
        </section>

        <div class="mb-3 mb-xl-5 pt-1 pb-4"></div>

        <section class="hot-deals container">
            <h2 class="section-title text-center mb-3 pb-xl-3 mb-xl-4">Penawaran Terbaik</h2>
            <div class="row">
                <div
                    class="col-md-6 col-lg-4 col-xl-20per d-flex align-items-center flex-column justify-content-center py-4 align-items-md-start">
                    <h2>Promo Produk</h2>
                    <h2 class="fw-bold">Diskon hingga {{ $maxDiscount ?? 0 }}% </h2>

                    <div class="position-relative d-flex align-items-center text-center pt-xxl-4 js-countdown mb-3"
                        data-date="18-3-2024" data-time="06:50">
                        <div class="day countdown-unit">
                            <span class="countdown-num d-block"></span>
                            <span class="countdown-word text-uppercase text-secondary">Days</span>
                        </div>

                        <div class="hour countdown-unit">
                            <span class="countdown-num d-block"></span>
                            <span class="countdown-word text-uppercase text-secondary">Hours</span>
                        </div>

                        <div class="min countdown-unit">
                            <span class="countdown-num d-block"></span>
                            <span class="countdown-word text-uppercase text-secondary">Mins</span>
                        </div>

                        <div class="sec countdown-unit">
                            <span class="countdown-num d-block"></span>
                            <span class="countdown-word text-uppercase text-secondary">Sec</span>
                        </div>
                    </div>

                    <a href="{{ route('shop.index') }}"
                        class="btn-link default-underline text-uppercase fw-medium mt-3">Lihat Semua</a>
                </div>
                <div class="col-md-6 col-lg-8 col-xl-80per">
                    <div class="position-relative">
                        <div class="swiper-container js-swiper-slider" data-settings='{
                                "autoplay": { "delay": 5000 },
                                "slidesPerView": 4,
                                "slidesPerGroup": 4,
                                "effect": "none",
                                "loop": false,
                                "breakpoints": {
                                    "320": { "slidesPerView": 2, "slidesPerGroup": 2, "spaceBetween": 14 },
                                    "768": { "slidesPerView": 2, "slidesPerGroup": 3, "spaceBetween": 24 },
                                    "992": { "slidesPerView": 3, "slidesPerGroup": 1, "spaceBetween": 30, "pagination": false },
                                    "1200": { "slidesPerView": 4, "slidesPerGroup": 1, "spaceBetween": 30, "pagination": false }
                                }
                            }'>
                            <div class="swiper-wrapper">
                                @foreach ($sproducts as $sproduct)
                                    <div class="swiper-slide product-card product-card_style3">
                                        <div class="pc__img-wrapper">
                                            <a
                                                href="{{ route('shop.product.details', ['product_slug' => $sproduct->slug]) }}">
                                                <img loading="lazy"
                                                    src="{{ asset('uploads/products') }}/{{ $sproduct->image }}"
                                                    width="258" height="313" alt="{{ $sproduct->name }}"
                                                    class="pc__img">
                                            </a>
                                        </div>
                                        <div class="pc__info position-relative">
                                            <h6 class="pc__title"><a
                                                    href="{{ route('shop.product.details', ['product_slug' => $sproduct->slug]) }}">{{ $sproduct->name }}</a>
                                            </h6>
                                            <div class="product-card__price d-flex flex-column align-items-start">
                                                @if ($sproduct->sale_price)
                                                    <span class="money price text-secondary" style="font-size: 1rem; color: #ff0000; font-weight: bold;">
                                                        Rp. {{ number_format($sproduct->sale_price, 0, ',', '.') }}
                                                    </span>
                                                    <span class="money price text-muted" style="text-decoration: line-through; font-size: 0.9rem;">
                                                        Rp. {{ number_format($sproduct->regular_price, 0, ',', '.') }}
                                                    </span>
                                                @else
                                                    <span class="money price text-secondary" style="font-size: 1rem; color: #ff0000; font-weight: bold;">
                                                        Rp. {{ number_format($sproduct->regular_price, 0, ',', '.') }}
                                                    </span>
                                                @endif
                                            </div>
                                        </div>
                                    </div>
                                @endforeach
                            </div>
                        </div>
                    </div>
                </div>
            </div>
    </div>
    </section>

    <div class="mb-3 mb-xl-5 pt-1 pb-4"></div>

    <section class="category-banner container">
        <div class="row">
            @foreach ($bannerRandomCategories as $category)
                @php
                    $lowestSaleProduct = $category->products
                        ->whereNotNull('sale_price')
                        ->sortBy('sale_price')
                        ->first();
                    $productImage = $category->products->first()?->image;
                @endphp
                <div class="col-md-6">
                    <div class="category-banner__item border-radius-10 mb-5">
                        @php
                            $imagePath = $productImage
                                ? public_path('uploads/products/' . $productImage)
                                : null;
                            $isPng =
                                $productImage &&
                                strtolower(pathinfo($productImage, PATHINFO_EXTENSION)) === 'png';
                        @endphp

                        <img loading="lazy" class="h-auto"
                            src="{{ $productImage ? asset('uploads/products/' . $productImage) : asset('assets/images/placeholder.jpg') }}"
                            width="690" height="665" alt="{{ $category->name }}"
                            @style(['background-color: #f2f2f2'=> $isPng]) />

                        <div class="category-banner__item-mark">
    @if ($lowestSaleProduct && $lowestSaleProduct->sale_price > 0)
        Mulai Dari Rp. {{ number_format($lowestSaleProduct->sale_price, 0, ',', '.') }}
    @else
        Lihat Penawaran
    @endif
</div>


                        <div class="category-banner__item-content">
                            <h3 class="mb-0">{{ $category->name }}</h3>
                            <a href="{{ url('/shop?categories=' . $category->id) }}"
                                class="btn-link default-underline text-uppercase fw-medium">Belanja Sekarang</a>
                        </div>
                    </div>
                </div>
            @endforeach
        </div>
    </section>

    <div class="mb-3 mb-xl-5 pt-1 pb-4"></div>

    <section class="products-grid container">
    <h2 class="section-title text-center mb-3 pb-xl-3 mb-xl-4">Produk Unggulan</h2>
    <div class="row">
        @foreach ($fproducts as $fproduct)
            <div class="col-6 col-md-4 col-lg-3">
                <div class="product-card product-card_style3 mb-3 mb-md-4 mb-xxl-5">
                    <div class="pc__img-wrapper">
                        <a href="{{ route('shop.product.details', ['product_slug' => $fproduct->slug]) }}">
                            <img loading="lazy" src="{{ asset('uploads/products') }}/{{ $fproduct->image }}"
                                width="330" height="400" alt="{{ $fproduct->name }}" class="pc__img">
                        </a>
                    </div>
                    <div class="pc__info position-relative">
                        <h6 class="pc__title">
                            <a href="{{ route('shop.product.details', ['product_slug' => $fproduct->slug]) }}">
                                {{ $fproduct->name }}
                            </a>
                        </h6>
                        <div class="product-card__price d-flex flex-column align-items-start">
                            @if ($fproduct->sale_price > 0 && $fproduct->sale_price < $fproduct->regular_price)
                                {{-- Harga Diskon --}}
                                <span class="money price text-secondary" 
                                      style="font-size: 1rem; color: #ff0000; font-weight: bold;">
                                    Rp. {{ number_format($fproduct->sale_price, 0, ',', '.') }}
                                </span>
                                <span class="money price text-muted" 
                                      style="text-decoration: line-through; font-size: 0.9rem;">
                                    Rp. {{ number_format($fproduct->regular_price, 0, ',', '.') }}
                                </span>
                            @else
                                {{-- Hanya Harga Normal --}}
                                <span class="money price text-secondary" 
                                      style="font-size: 1rem; color: #ff0000; font-weight: bold;">
                                    Rp. {{ number_format($fproduct->regular_price, 0, ',', '.') }}
                                </span>
                            @endif
                        </div>
                    </div>
                </div>
            </div>
        @endforeach
    </div>
</section>


    </div>
</main>
<!-- Tombol WhatsApp Mengambang -->
<a href="https://wa.me/{{ $whatsappNumber }}?text=Halo,%20saya%20tertarik%20dengan%20layanan%20Anda."
    class="whatsapp-float" target="_blank" rel="noopener noreferrer">
    <img src="{{ asset('images/whatsapp-icon.svg') }}" alt="Chat di WhatsApp" class="whatsapp-icon">
</a>
@endsection
