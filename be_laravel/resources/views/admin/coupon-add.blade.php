@extends('layouts.admin')
@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27">
                <h3>Tambah Kupon Diskon</h3>
                <ul class="breadcrumbs flex items-center flex-wrap justify-start gap10">
                    <li>
                        <a href="{{ route('admin.index') }}">
                            <div class="text-tiny">Menu Utama</div>
                        </a>
                    </li>
                    <li>
                        <i class="icon-chevron-right"></i>
                    </li>
                    <li>
                        <a href="{{ route('admin.coupons') }}">
                            <div class="text-tiny">Kupon Diskon</div>
                        </a>
                    </li>
                    <li>
                        <i class="icon-chevron-right"></i>
                    </li>
                    <li>
                        <div class="text-tiny">Tambah Kupon diskon</div>
                    </li>
                </ul>
            </div>
            <div class="wg-box">
                <form class="form-new-product form-style-1" method="POST" action="{{ route('admin.coupon.store') }}"
                    id="couponForm" novalidate>
                    @csrf
                    <fieldset class="name">
                        <div class="body-title">Kode Kupon <span class="tf-color-1">*</span></div>
                        <input class="flex-grow" type="text" placeholder="Kode Kupon" name="code" tabindex="0"
                            value="{{ old('code') }}" required>
                    </fieldset>
                    @error('code')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror
                    <fieldset class="category">
                        <div class="body-title">Tipe Diskon <span class="tf-color-1">*</span></div>
                        <div class="select flex-grow">
                            <select name="type" required>
                                <option value="">Pilih Tipe Diskon</option>
                                <option value="fixed" {{ old('type') == 'fixed' ? 'selected' : '' }}>Potongan Harga Tetap</option>
                                <option value="percent" {{ old('type') == 'percent' ? 'selected' : '' }}>Potongan Harga Persen</option>
                            </select>
                        </div>
                    </fieldset>
                    @error('type')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror
                    <fieldset class="name">
                        <div class="body-title">Nominal <span class="tf-color-1">*</span></div>
                        <input class="flex-grow" type="number" placeholder="Nominal Potongan" name="value" tabindex="0"
                            value="{{ old('value') }}" required>
                    </fieldset>
                    @error('value')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror
                    <fieldset class="name">
                        <div class="body-title">Jumlah Kupon <span class="tf-color-1">*</span></div>
                        <input class="flex-grow" type="number" placeholder="Jumlah Kupon" name="cart_value" tabindex="0"
                            value="{{ old('cart_value') }}" required>
                    </fieldset>
                    @error('cart_value')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror
                    <fieldset class="name">
                        <div class="body-title">Tanggal Kadaluarsa Kupon <span class="tf-color-1">*</span></div>
                        <input class="flex-grow" type="date" placeholder="tanggal kadaluarsa kupon" name="expiry_date"
                            tabindex="0" value="{{ old('expiry_date') }}" required>
                    </fieldset>
                    @error('expiry_date')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <div class="bot">
                        <div></div>
                        <button class="tf-button w208" type="submit">Simpan</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
@endsection

@push('scripts')
    <script>
        $(function() {
            /**
             * Fungsi untuk menampilkan notifikasi eror dengan gaya kustom.
             * @param {string} message - Pesan eror yang akan ditampilkan.
             */
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
                        color: "#3498db",
                        border: "1px solid #3498db",
                        borderRadius: "8px"
                    }
                }).showToast();
            }

            // Mencegat event submit pada form
            $('#couponForm').on('submit', function(e) {
                let formIsValid = true;
                
                // Memeriksa setiap input dan select yang wajib diisi
                $(this).find('input[required], select[required]').each(function() {
                    const fieldName = $(this).closest('fieldset').find('.body-title').text().trim().replace('*', '').trim();
                    let errorMessage = '';

                    // Validasi untuk dropdown/select
                    if ($(this).is('select') && $(this).val() === "") {
                        errorMessage = 'Anda harus memilih salah satu opsi untuk kolom "' + fieldName + '".';
                        formIsValid = false;
                    }

                    // Validasi untuk input lainnya
                    if (!$(this).is('select') && !$(this).val()) {
                        errorMessage = 'Kolom "' + fieldName + '" tidak boleh kosong.';
                        formIsValid = false;
                    }
                    
                    // Jika ada pesan eror, tampilkan notifikasi dan hentikan loop
                    if (errorMessage) {
                        showErrorToast(errorMessage);
                        return false;
                    }
                });

                // Mencegah form untuk submit jika tidak valid
                if (!formIsValid) {
                    e.preventDefault();
                }
            });
        });
    </script>
@endpush