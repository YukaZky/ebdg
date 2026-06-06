@extends('layouts.app')
@section('content')
    <style>
        .filled-heart {
            color: orange;
        }
        .product-card {
            border: none;
            background-color: transparent;
            text-align: left;
        }
        .pc__img-wrapper {
            position: relative;
            overflow: hidden;
            border-radius: 8px;
        }
        .pc__badge {
            position: absolute;
            bottom: 10px;
            left: 10px;
            background-color: #d9534f;
            color: white;
            padding: 4px 10px;
            font-size: 12px;
            font-weight: 700;
            border-radius: 4px;
            z-index: 2;
        }
        .pc__info {
            padding-top: 12px;
        }
        .pc__title {
            font-size: 1rem;
            font-weight: 600;
            margin-bottom: 4px;
            line-height: 1.3;
        }
        .pc__title a {
            text-decoration: none;
            color: #222;
        }
        .pc__title a:hover {
            text-decoration: underline;
        }
        .pc__category {
            font-size: 0.85rem;
            color: #6c757d;
            margin-bottom: 8px;
            text-transform: uppercase;
        }
        .product-card__price .price {
            font-size: 1rem;
            font-weight: 700;
            color: #d9534f;
        }
        .product-card__price .price-old {
            font-size: 0.9rem;
            font-weight: 400;
            color: #6c757d;
            margin-left: 8px;
        }
        .pc__btn-wl {
            position: static;
            padding-left: 10px;
            cursor: pointer;
        }
        .pc__btn-wl:disabled {
            cursor: not-allowed;
            opacity: 0.6;
        }

        /* Sidebar filter untuk mobile */
        @media (max-width: 991px) {
            .shop-sidebar {
                position: fixed;
                top: 0;
                left: -100%;
                width: 80%;
                max-width: 300px;
                height: 100%;
                overflow-y: auto;
                background: #fff;
                z-index: 1050;
                transition: left 0.3s ease-in-out;
                box-shadow: 2px 0 10px rgba(0,0,0,0.2);
            }
            .shop-sidebar.active {
                left: 0;
            }
            .shop-sidebar .aside-header {
                padding: 15px;
                border-bottom: 1px solid #ddd;
            }
            .btn-close-aside {
                border: none;
                background: transparent;
                font-size: 20px;
            }
        }
        
        /* CSS untuk Tombol WhatsApp */
        .whatsapp-float {
            position: fixed;
            width: 60px;
            height: 60px;
            bottom: 40px;
            right: 40px;
            background-color: #fff; /* Diganti menjadi putih agar ikon hitam terlihat */
            border-radius: 50px;
            text-align: center;
            box-shadow: 2px 2px 5px rgba(0,0,0,0.2); /* Bayangan disesuaikan */
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
                bottom: 80px; /* Menaikkan posisi tombol agar di atas footer mobile */
                right: 20px;
            }

            .whatsapp-icon {
                width: 30px;
                height: 30px;
            }
        }
    </style>

    <div class="mb-3 d-flex justify-content-between align-items-center d-lg-none px-3">
        <h5 class="mb-0">Produk</h5>
        <button class="btn btn-light border rounded-pill shadow-sm px-3 py-2 d-flex align-items-center gap-2" id="btnMobileFilter">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="currentColor" class="text-secondary" viewBox="0 0 16 16">
                <path d="M6 10.117V16l4-2.667V10.117l5.481-6.509A1 1 0 0 0 14.653 2H1.347a1 1 0 0 0-.828 1.608L6 10.117z"/>
            </svg>
            <span class="fw-semibold text-secondary">Filter</span>
        </button>
    </div>

    
    <section class="shop-main container d-flex">
        {{-- SIDEBAR FILTER --}}
        <div class="shop-sidebar side-sticky bg-body" id="shopFilter">
            <div class="aside-header d-flex d-lg-none align-items-center">
                <h3 class="text-uppercase fs-6 mb-0">Filter By</h3>
                <button class="btn-close-lg btn-close-aside ms-auto">&times;</button>
            </div>

            <div class="pt-4 pt-lg-0"></div>

            {{-- KATEGORI FILTER --}}
            <div class="accordion" id="categories-list">
                <div class="accordion-item mb-5 pb-3">
                    <h5 class="accordion-header" id="accordion-heading-1">
                        <button class="accordion-button p-0 border-0 fs-5 text-uppercase" type="button" data-bs-toggle="collapse" data-bs-target="#accordion-filter-1" aria-expanded="true" aria-controls="accordion-filter-1">
                            Kategori
                        </button>
                    </h5>
                    <div id="accordion-filter-1" class="accordion-collapse collapse show border-0" aria-labelledby="accordion-heading-1" data-bs-parent="#categories-list">
                        <div class="accordion-body px-0 pb-0 pt-3">
                            <ul class="list list-inline mb-0">
                                @foreach ($categories as $category)
                                    <li class="list-item">
                                        <span class="menu-link py-1">
                                            <input type="checkbox" name="categories" class="chk-category"
                                                value="{{ $category->id }}"
                                                @if(in_array($category->id, explode(',', $f_categories ?? ''))) checked @endif />
                                            {{ $category->name }}
                                        </span>
                                        <span class="text-right float-end">{{ $category->products_count }}</span>
                                    </li>
                                @endforeach
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            {{-- BRAND FILTER --}}
            <div class="accordion" id="brand-filters">
                <div class="accordion-item mb-4 pb-3">
                    <h5 class="accordion-header" id="accordion-heading-brand">
                        <button class="accordion-button p-0 border-0 fs-5 text-uppercase" type="button" data-bs-toggle="collapse" data-bs-target="#accordion-filter-brand" aria-expanded="true" aria-controls="accordion-filter-brand">
                            Brand
                        </button>
                    </h5>
                    <div id="accordion-filter-brand" class="accordion-collapse collapse show border-0" aria-labelledby="accordion-heading-brand" data-bs-parent="#brand-filters">
                        <div class="search-field multi-select accordion-body px-0 pb-0">
                            <ul class="list list-inline mb-0 brand-list">
                                @foreach ($brands as $brand)
                                    <li class="list-item">
                                        <span class="menu-link py-1">
                                            <input type="checkbox" name="brands" class="chk-brand"
                                                value="{{ $brand->id }}"
                                                @if(in_array($brand->id, explode(',', $f_brands ?? ''))) checked @endif />
                                            {{ $brand->name }}
                                        </span>
                                        <span class="float-end">{{ $brand->products_count }}</span>
                                    </li>
                                @endforeach
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            {{-- HARGA FILTER --}}
            <div class="accordion" id="price-filters">
                <div class="accordion-item mb-4">
                    <h5 class="accordion-header mb-2" id="accordion-heading-price">
                        <button class="accordion-button p-0 border-0 fs-5 text-uppercase" type="button" data-bs-toggle="collapse" data-bs-target="#accordion-filter-price" aria-expanded="true" aria-controls="accordion-filter-price">
                            Harga
                        </button>
                    </h5>
                    <div id="accordion-filter-price" class="accordion-collapse collapse show border-0" aria-labelledby="accordion-heading-price" data-bs-parent="#price-filters">
                        <div class="d-flex align-items-center gap-2">
                            <input type="number" id="minPriceInput" class="form-control" placeholder="Harga Min..." value="{{ $min_price }}">
                            <span class="minus">-</span>
                            <input type="number" id="maxPriceInput" class="form-control" placeholder="Harga Max..." value="{{ $max_price }}">
                        </div>
                    </div>
                </div>
            </div>
        </div>

        {{-- LIST PRODUK --}}
        <div class="shop-list flex-grow-1">
            <div class="text-center mb-4 pb-md-2 d-none d-lg-block">
                <h2 class="text-uppercase fw-bold">Produk</h2>
            </div>

            <div class="products-grid row row-cols-1 row-cols-md-2 row-cols-lg-2 row-cols-xl-3" id="products-grid">
                @forelse ($products as $product)
                    <div class="product-card-wrapper">
                        <div class="product-card mb-3 mb-md-4 mb-xxl-5">
                            <div class="pc__img-wrapper">
                                <a href="{{ route('shop.product.details', ['product_slug' => $product->slug]) }}">
                                    <img loading="lazy" src="{{ asset('uploads/products') }}/{{ $product->image }}" width="660" height="800" alt="{{ $product->name }}" class="pc__img img-fluid">
                                </a>
                                @if ($product->sale_price > 0 && $product->regular_price > 0)
                                    @php
                                        $discount = round((($product->regular_price - $product->sale_price) / $product->regular_price) * 100);
                                    @endphp
                                    <div class="pc__badge">Diskon {{ $discount }}%</div>
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
                                        $inWishlist = auth()->check() && isset($wishlistedProductIds) && in_array($product->id, $wishlistedProductIds);
                                    @endphp
                                    
                                    <form class="wishlist-form"
                                        action="{{ $inWishlist ? route('wishlist.item.remove', ['product_id' => $product->id]) : route('wishlist.add') }}"
                                        method="POST"
                                        data-add-url="{{ route('wishlist.add') }}"
                                        data-remove-url="{{ route('wishlist.item.remove', ['product_id' => $product->id]) }}">
                                        @csrf
                                        <input type="hidden" name="id" value="{{ $product->id }}">
                                        @if ($inWishlist)
                                            @method('DELETE')
                                        @endif
                                        <button type="button" class="pc__btn-wl bg-transparent border-0 js-add-wishlist {{ $inWishlist ? 'filled-heart' : '' }}"
                                            title="{{ $inWishlist ? 'Remove from Wishlist' : 'Add To Wishlist' }}">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="currentColor" style="fill: currentColor;">
                                                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
                                            </svg>
                                        </button>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                @empty
                    <div class="col-12 text-center">
                        <p>Mohon maaf, tidak ada produk yang ditemukan.</p>
                    </div>
                @endforelse
            </div>

            <div class="divider"></div>
            <div class="flex items-center justify-between flex-wrap gap10 wg-pagination">
                {{ $products->withQueryString()->links('pagination::bootstrap-5') }}
            </div>
        </div>
    </section>

    <form action="{{ route('shop.index') }}" method="GET" id="frmFilter">
        <input type="hidden" name="size" id="size" value="{{ $size }}">
        <input type="hidden" name="order" id="order" value="{{ $order }}">
        <input type="hidden" name="brands" id="hdnBrands" value="{{ $f_brands }}">
        <input type="hidden" name="categories" id="hdnCategories" value="{{ $f_categories }}">
        <input type="hidden" name="min" id="hdnMinPrice" value="{{ $min_price }}">
        <input type="hidden" name="max" id="hdnMaxPrice" value="{{ $max_price }}">
    </form>

    <!-- Tombol WhatsApp Mengambang -->
    <a href="https://wa.me/{{ $whatsappNumber }}?text=Halo,%20saya%20tertarik%20dengan%20layanan%20Anda." class="whatsapp-float" target="_blank" rel="noopener noreferrer">
        <img src="{{ asset('images/whatsapp-icon.svg') }}" alt="Chat di WhatsApp" class="whatsapp-icon">
    </a>
@endsection

@push('scripts')
<script>
document.addEventListener("DOMContentLoaded", function() {

    // --- Bagian 1 & 2: Filter dan Mobile Toggle ---
    try {
        const frmFilter = document.getElementById('frmFilter');
        if (frmFilter) {
            const submitFilterForm = () => frmFilter.submit();
            const hdnBrands = document.getElementById('hdnBrands');
            document.querySelectorAll("input[name='brands']").forEach(cb => {
                cb.addEventListener('change', () => {
                    let selected = Array.from(document.querySelectorAll("input[name='brands']:checked")).map(c => c.value).join(',');
                    if (hdnBrands) hdnBrands.value = selected;
                    submitFilterForm();
                });
            });
            const hdnCategories = document.getElementById('hdnCategories');
            document.querySelectorAll("input[name='categories']").forEach(cb => {
                cb.addEventListener('change', () => {
                    let selected = Array.from(document.querySelectorAll("input[name='categories']:checked")).map(c => c.value).join(',');
                    if (hdnCategories) hdnCategories.value = selected;
                    submitFilterForm();
                });
            });
            const minPriceInput = document.getElementById('minPriceInput');
            const maxPriceInput = document.getElementById('maxPriceInput');
            if (minPriceInput && maxPriceInput) {
                const handleEnterKey = (e) => {
                    if (e.key === 'Enter') {
                        e.preventDefault();
                        if (minPriceInput.value && maxPriceInput.value) {
                            const hdnMinPrice = document.getElementById('hdnMinPrice');
                            const hdnMaxPrice = document.getElementById('hdnMaxPrice');
                            if (hdnMinPrice) hdnMinPrice.value = minPriceInput.value;
                            if (hdnMaxPrice) hdnMaxPrice.value = maxPriceInput.value;
                            submitFilterForm();
                        }
                    }
                };
                minPriceInput.addEventListener('keydown', handleEnterKey);
                maxPriceInput.addEventListener('keydown', handleEnterKey);
            }
        }
        const btnMobileFilter = document.getElementById('btnMobileFilter');
        const shopFilter = document.getElementById('shopFilter');
        const btnClose = document.querySelector('.btn-close-aside');
        if (btnMobileFilter && shopFilter && btnClose) {
            btnMobileFilter.addEventListener('click', () => shopFilter.classList.add('active'));
            btnClose.addEventListener('click', () => shopFilter.classList.remove('active'));
        }
    } catch (e) {
        console.error("Error pada script filter atau mobile:", e);
    }

    // --- Bagian 3: Logika Wishlist ---
    try {
        const handleWishlistClick = function(event) {
            event.preventDefault();

            @guest
                window.location.href = "{{ route('login') }}";
                return;
            @endguest

            const button = event.currentTarget;
            const form = button.closest('form.wishlist-form');
            if (!form) {
                console.error("Error: Tidak dapat menemukan form wishlist.");
                return;
            }
            
            const url = form.action;
            const method = form.querySelector('input[name="_method"]')?.value || 'POST';
            const formData = new FormData(form);
            
            button.disabled = true;

            fetch(url, {
                method: method,
                headers: { 
                    'Content-Type': 'application/json', 
                    'X-CSRF-TOKEN': formData.get('_token'), 
                    'Accept': 'application/json' 
                },
                body: (method !== 'GET') ? JSON.stringify({ id: formData.get('id'), _token: formData.get('_token') }) : null
            })
            .then(response => response.ok ? response.json() : Promise.reject(response))
            .then(data => {
                if (data.status === 'success') {
                    const isAdding = (method === 'POST');
                    if (isAdding) {
                        button.classList.add('filled-heart');
                        button.title = 'Remove from Wishlist';
                        form.action = form.dataset.removeUrl;
                        if (!form.querySelector('input[name="_method"]')) {
                            const methodInput = document.createElement('input');
                            methodInput.type = 'hidden';
                            methodInput.name = '_method';
                            methodInput.value = 'DELETE';
                            form.appendChild(methodInput);
                        }
                    } else { 
                        button.classList.remove('filled-heart');
                        button.title = 'Add to Wishlist';
                        form.action = form.dataset.addUrl;
                        const methodInput = form.querySelector('input[name="_method"]');
                        if (methodInput) methodInput.remove();
                    }
                    
                    const badges = document.querySelectorAll('.js-wishlist-count');
                    if(badges.length > 0 && typeof data.count !== 'undefined') {
                        badges.forEach(badge => {
                            badge.textContent = data.count > 0 ? data.count : '';
                            badge.classList.toggle('d-none', data.count === 0);
                        });
                    }
                } else {
                    alert(data.message || 'Terjadi kesalahan.');
                }
            })
            .catch(error => {
                console.error('Wishlist AJAX Error:', error);
                alert('Gagal memproses permintaan. Silakan periksa console untuk detail.');
            })
            .finally(() => {
                button.disabled = false;
            });
        };
        
        document.querySelectorAll('.js-add-wishlist').forEach(button => {
            button.addEventListener('click', handleWishlistClick);
        });

    } catch (e) {
        console.error("Error pada script wishlist:", e);
    }
});
</script>
@endpush

