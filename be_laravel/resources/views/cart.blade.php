@extends('layouts.app')
@section('content')
    <style>
        .text-success {
            color: #278c04 !important
        }

        .text-danger {
            color: #dc3545 !important
        }

        /* Style untuk tombol yang dinonaktifkan dari kode asli Anda */
        .btn-checkout.disabled {
            background-color: #ccc;
            border-color: #ccc;
            cursor: not-allowed;
            opacity: 0.65;
        }

        /* [BARU] Style untuk total harga pilihan agar serasi */
        .selected-totals {
            padding-top: 15px;
            border-top: 1px solid #eee;
            margin-top: 15px;
        }

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
    </style>
    <main class="pt-20">

        <section class="shop-checkout container">
            <h2 class="page-title">Keranjang</h2>
            <div class="checkout-steps">
                <a href="javascript:void(0)" class="checkout-steps__item active">
                    <span class="checkout-steps__item-number">01</span>
                    <span class="checkout-steps__item-title">
                        <span>Tas Belanja</span>
                        <em>Kelola Daftar Item Anda</em>
                    </span>
                </a>
                <a href="javascript:void(0)" class="checkout-steps__item">
                    <span class="checkout-steps__item-number">02</span>
                    <span class="checkout-steps__item-title">
                        <span>Pengiriman dan Checkout</span>
                        <em>Checkout Pesanan Anda</em>
                    </span>
                </a>
                <a href="javascript:void(0)" class="checkout-steps__item">
                    <span class="checkout-steps__item-number">03</span>
                    <span class="checkout-steps__item-title">
                        <span>Konfirmasi</span>
                        <em>Lihat dan Konfirmasi Pesanan</em>
                    </span>
                </a>
            </div>
            <div class="shopping-cart">
                @if ($items->count() > 0)
                    {{-- [MODIFIKASI] Struktur div utama tidak diubah untuk menjaga layout --}}
                    <div class="cart-table__wrapper">
                        {{-- Form HANYA membungkus tabel agar tidak merusak layout flex --}}
                        <form action="{{ route('cart.checkout.selected') }}" method="POST" id="cart-selection-form">
                            @csrf
                            <table class="cart-table">
                                <thead>
                                    <tr>
                                        <th style="width: 20px;"><input type="checkbox" id="select-all"></th>
                                        <th>Produk</th>
                                        <th></th>
                                        <th>Harga</th>
                                        <th>Jumlah</th>
                                        <th>Subtotal</th>
                                        <th></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach ($items as $item)
                                        <tr class="cart-item" data-stock="{{ $item->product->quantity }}"
                                            data-price="{{ $item->price }}" data-quantity="{{ $item->quantity }}">
                                            <td>
                                                <input type="checkbox" class="product-checkbox" name="selected_products[]"
                                                    value="{{ $item->id }}">
                                            </td>
                                            <td>
                                                <div class="shopping-cart__product-item">
                                                    <a
                                                        href="{{ route('shop.product.details', ['product_slug' => $item->product->slug]) }}">
                                                        <img loading="lazy"
                                                            src="{{ asset('uploads/products/thumbnails') }}/{{ $item->product->image }}"
                                                            width="120" height="120"
                                                            alt="{{ $item->product->name }}" />
                                                    </a>
                                                </div>
                                            </td>
                                            <td>
                                                <div class="shopping-cart__product-item__detail">
                                                    <a
                                                        href="{{ route('shop.product.details', ['product_slug' => $item->product->slug]) }}">
                                                        <h4>{{ $item->product->name }}</h4>
                                                    </a>
                                                    <ul class="shopping-cart__product-item__options">
                                                        <li>sisa stok: <span
                                                                class="stock-quantity">{{ $item->product->quantity }}</span>
                                                        </li>
                                                    </ul>
                                                </div>
                                            </td>
                                            <td>
                                                <span class="shopping-cart__product-price">Rp.
                                                    {{ number_format($item->price, 0, ',', '.') }}</span>
                                            </td>
                                            <td>
                                                <div class="qty-control position-relative">
                                                    {{-- Form di sini sudah dihapus --}}
                                                    <input type="number" name="quantity" value="{{ $item->quantity }}"
                                                        min="1" class="qty-control__number text-center action-input"
                                                        data-action="{{ route('cart.qty.update', ['id' => $item->id]) }}"
                                                        data-method="PUT">

                                                    <div class="qty-control__reduce action-btn"
                                                        data-action="{{ route('cart.qty.decrease', ['id' => $item->id]) }}"
                                                        data-method="PUT">-</div>
                                                    <div class="qty-control__increase action-btn"
                                                        data-action="{{ route('cart.qty.increase', ['id' => $item->id]) }}"
                                                        data-method="PUT">+</div>
                                                </div>
                                            </td>
                                            <td>
                                                <span class="shopping-cart__subtotal">Rp.
                                                    {{ number_format($item->subtotal, 0, ',', '.') }}</span>
                                            </td>
                                            <td>
                                                <a href="javascript:void(0)" class="remove-cart action-btn"
                                                    data-action="{{ route('cart.item.remove', ['id' => $item->id]) }}"
                                                    data-method="DELETE">

                                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"
                                                        fill="red" class="bi bi-trash" viewBox="0 0 16 16">
                                                        <path
                                                            d="M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5m2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5m3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0z" />
                                                        <path
                                                            d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1zM4.118 4 4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4zM2.5 3h11V2h-11z" />
                                                    </svg>

                                                </a>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </form> {{-- Akhir Form --}}
                        <div class="cart-table-footer">
    {{-- Form kupon dipindah ke halaman checkout --}}
    <form action="{{ route('cart.empty') }}" method="POST">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn btn-light">BERSIHKAN KERANJANG</button>
                            </form>
</div>
                        <div>
                            @if (Session::has('success'))
                                <p class="text-success">{{ Session::get('success') }}</p>
                            @elseif(Session::has('error'))
                                <p class="text-danger">{{ Session::get('error') }}</p>
                            @endif
                        </div>
                    </div>
                    <div class="shopping-cart__totals-wrapper">
                        <div class="sticky-content">
                            <div class="shopping-cart__totals">
                                <h3>Total Keranjang</h3>
                                {{-- GANTI KODE LAMA ANDA DENGAN INI --}}
                                @if (Session::has('discounts') && Session::has('coupon'))
                                    <table class="cart-totals">
                                        <tbody>
                                            <tr>
                                                <th>Subtotal Awal</th>
                                                {{-- $subtotal dari controller adalah subtotal sebelum diskon --}}
                                                <td>Rp. {{ number_format($subtotal, 0, ',', '.') }}</td>
                                            </tr>
                                            <tr>
                                                <th class="text-success">Diskon ({{ Session::get('coupon')['code'] }})
                                                </th>
                                                <td class="text-success">- Rp.
                                                    {{ number_format(Session::get('discounts')['discount'], 0, ',', '.') }}
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Subtotal Setelah Diskon</th>
                                                <td>Rp.
                                                    {{ number_format(Session::get('discounts')['subtotal'], 0, ',', '.') }}
                                                </td>
                                            </tr>
                                            <tr>
                                                <th>Total Akhir</th>
                                                <td><strong>Rp.
                                                        {{ number_format(Session::get('discounts')['total'], 0, ',', '.') }}</strong>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                @else
                                    {{-- Bagian ini tetap sama seperti kode Anda sebelumnya --}}
                                    <table class="cart-totals">
                                        <tbody>
                                            <tr>
                                                <th>Subtotal</th>
                                                <td>Rp. {{ number_format($subtotal, 0, ',', '.') }}</td>
                                            </tr>
                                            <tr>
                                                <th>Total</th>
                                                <td>Rp. {{ number_format($total, 0, ',', '.') }}</td>
                                            </tr>
                                        </tbody>
                                    </table>
                                @endif

                                <div id="selected-items-total-container" class="selected-totals" style="display: none;">
                                    <h4>Total Pilihan</h4>
                                    <table class="cart-totals">
                                        <tbody>
                                            <tr>
                                                <th>Subtotal Pilihan</th>
                                                <td id="selected-subtotal">Rp 0</td>
                                            </tr>
                                            <tr>
                                                <th>Total Pembayaran</th>
                                                <td id="selected-total"><strong>Rp 0</strong></td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                            <div class="mobile_fixed-btn_wrapper">
                                <div class="button-wrapper container">
                                    <a href="{{ route('cart.checkout') }}" id="checkout-btn"
                                        class="btn btn-primary btn-checkout">CHECKOUT</a>
                                </div>
                            </div>
                        </div>
                    </div>
                @else
                    <div class="row">
                        <div class="col-md-12 text-center pt-5 bp-5">
                            <p>Tidak ada item di keranjang</p>
                            <a href="{{ route('shop.index') }}" class="btn btn-info">Belanja Sekarang</a>
                        </div>
                    </div>
                @endif
            </div>
        </section>
    </main>
    <a href="https://wa.me/{{ $whatsappNumber }}?text=Halo,%20saya%20tertarik%20dengan%20layanan%20Anda."
        class="whatsapp-float" target="_blank" rel="noopener noreferrer">
        <img src="{{ asset('images/whatsapp-icon.svg') }}" alt="Chat di WhatsApp" class="whatsapp-icon">
    </a>
@endsection

@push('scripts')
    <script>
        $(function() {
            // --- FUNGSI HELPER (Tidak Berubah) ---
            function showErrorToast(message) {
                Toastify({
                    text: message,
                    duration: 3500,
                    close: true,
                    gravity: "top",
                    position: "right",
                    stopOnFocus: true,
                    style: {
                        padding: "16px",
                        fontSize: "15px",
                        background: "white",
                        color: "#e74c3c",
                        border: "1px solid #e74c3c",
                        borderRadius: "8px"
                    }
                }).showToast();
            }

            const formatRupiah = (number) => {
                return new Intl.NumberFormat('id-ID', {
                    style: 'currency',
                    currency: 'IDR',
                    minimumFractionDigits: 0
                }).format(number);
            };

            // --- FUNGSI UTAMA UNTUK UPDATE STATE (Tidak Berubah) ---
            function updateCartState() {
                let selectedSubtotal = 0;
                let isAnyItemOutOfStock = false;
                let isSelectedItemOutOfStock = false;
                const checkoutBtn = $('#checkout-btn');
                const selectedTotalContainer = $('#selected-items-total-container');

                $('.cart-item').each(function() {
                    const stock = parseInt($(this).data('stock'));
                    const isChecked = $(this).find('.product-checkbox').is(':checked');
                    if (stock <= 0) {
                        isAnyItemOutOfStock = true;
                        if (isChecked) isSelectedItemOutOfStock = true;
                    }
                    if (isChecked) {
                        const price = parseFloat($(this).data('price'));
                        // Ambil kuantitas terbaru langsung dari input field
                        const quantity = parseInt($(this).find('.qty-control__number').val());
                        selectedSubtotal += price * quantity;
                    }
                });

                const hasSelection = selectedSubtotal > 0;

                if (hasSelection) {
                    const total = selectedSubtotal;
                    $('#selected-subtotal').text(formatRupiah(selectedSubtotal));
                    $('#selected-total').html(`<strong>${formatRupiah(total)}</strong>`);
                    selectedTotalContainer.slideDown();
                } else {
                    selectedTotalContainer.slideUp();
                }

                checkoutBtn.off('click'); // Hapus listener lama untuk menghindari duplikasi

                if (hasSelection) {
                    checkoutBtn.text('CHECKOUT PILIHAN');
                    if (isSelectedItemOutOfStock) {
                        checkoutBtn.addClass('disabled').attr('href', 'javascript:void(0)');
                        checkoutBtn.on('click', (e) => {
                            e.preventDefault();
                            showErrorToast('Stok produk yang Anda pilih habis.');
                        });
                    } else {
                        checkoutBtn.removeClass('disabled').attr('href', 'javascript:void(0)');
                        checkoutBtn.on('click', (e) => {
                            e.preventDefault();
                            $('#cart-selection-form').submit();
                        });
                    }
                } else {
                    checkoutBtn.text('CHECKOUT SEMUA');
                    if (isAnyItemOutOfStock) {
                        checkoutBtn.addClass('disabled').attr('href', 'javascript:void(0)');
                        checkoutBtn.on('click', (e) => {
                            e.preventDefault();
                            showErrorToast('Stok salah satu produk habis. Harap hapus produk tersebut.');
                        });
                    } else {
                        checkoutBtn.removeClass('disabled').attr('href', '{{ route('cart.checkout') }}');
                    }
                }
            }

            // --- CHECKBOX LOGIC (Tidak Berubah) ---
            $('#select-all').on('change', function() {
                $('.product-checkbox').prop('checked', this.checked).trigger('change');
            });

            $('.product-checkbox').on('change', function() {
                if ($('.product-checkbox:checked').length === $('.product-checkbox').length) {
                    $('#select-all').prop('checked', true);
                } else {
                    $('#select-all').prop('checked', false);
                }
                updateCartState();
            });

            // --- [PERBAIKAN UTAMA] SATU EVENT HANDLER UNTUK SEMUA AKSI ---
            function handleAction(element) {
                const actionUrl = element.data('action');
                const method = element.data('method');
                const csrfToken = '{{ csrf_token() }}';
                let quantity = null;

                // Jika elemen adalah input angka, ambil nilainya
                if (element.hasClass('action-input')) {
                    quantity = element.val();
                }

                // Buat form sementara di memori menggunakan jQuery agar lebih ringkas
                const form = $('<form>', {
                    'method': 'POST',
                    'action': actionUrl
                }).hide();

                form.append($('<input>', {
                    'type': 'hidden',
                    'name': '_token',
                    'value': csrfToken
                }));
                form.append($('<input>', {
                    'type': 'hidden',
                    'name': '_method',
                    'value': method
                }));

                // Tambahkan input kuantitas jika ada (untuk update manual)
                if (quantity !== null) {
                    form.append($('<input>', {
                        'type': 'hidden',
                        'name': 'quantity',
                        'value': quantity
                    }));
                }

                $('body').append(form);
                form.submit();
            }

            // Mendaftarkan event handler ke parent statis (.cart-table)
            // Ini lebih efisien dan berfungsi untuk elemen yang dimuat dinamis
            $('.cart-table').on('click', '.action-btn', function() {
                handleAction($(this));
            });

            $('.cart-table').on('change', '.action-input', function() {
                handleAction($(this));
            });

            // --- [BARU] LOGIKA UNTUK TOMBOL VOUCHER ---
            const couponInput = $('#coupon_code');
            const applyBtn = $('#apply-voucher-btn');

            couponInput.on('input', function() {
                if ($(this).val().trim() !== '') {
                    applyBtn.prop('disabled', false);
                } else {
                    applyBtn.prop('disabled', true);
                }
            });


            // --- INISIALISASI SAAT HALAMAN DILOAD ---
            $('.cart-item').each(function() {
                if (parseInt($(this).data('stock')) <= 0) $(this).css('opacity', '0.6');
            });

            updateCartState(); // Panggil fungsi utama saat halaman dimuat
        });
    </script>
@endpush
