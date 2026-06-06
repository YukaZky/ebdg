@extends('layouts.admin')

@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Tambah Pengguna</h3>
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
                        <a href="{{ route('admin.users') }}">
                            <div class="text-tiny">Pengguna</div>
                        </a>
                    </li>
                    <li>
                        <i class="icon-chevron-right"></i>
                    </li>
                    <li>
                        <div class="text-tiny">Tambah Pengguna</div>
                    </li>
                </ul>
            </div>
            <div class="wg-box">
                <form class="form-new-product form-style-1" action="{{ route('admin.user.store') }}" method="POST"
                    id="userForm" novalidate>
                    @csrf
                    <fieldset class="name">
                        <div class="body-title">Nama Lengkap <span class="tf-color-1">*</span></div>
                        <input class="flex-grow" type="text" placeholder="Nama Lengkap" name="name"
                            value="{{ old('name') }}" required>
                    </fieldset>
                    @error('name')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <fieldset class="email">
                        <div class="body-title">Alamat Email <span class="tf-color-1">*</span></div>
                        <input class="flex-grow" type="email" placeholder="Email Pengguna" name="email"
                            value="{{ old('email') }}" required>
                    </fieldset>
                    @error('email')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <fieldset class="password">
                        <div class="body-title">Password <span class="tf-color-1">*</span></div>
                        <input class="flex-grow" type="password" placeholder="Password" name="password" required>
                    </fieldset>
                    @error('password')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <fieldset class="utype">
                        <div class="body-title">Tipe Pengguna <span class="tf-color-1">*</span></div>
                        <select name="utype" class="flex-grow" required>
                            <option value="">Pilih Tipe Pengguna</option>
                            <option value="USR" {{ old('utype') == 'USR' ? 'selected' : '' }}>Pelanggan </option>
                            <option value="ADM" {{ old('utype') == 'ADM' ? 'selected' : '' }}>Admin</option>
                        </select>
                    </fieldset>
                    @error('utype')
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
            $('#userForm').on('submit', function(e) {
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

                    // Validasi untuk input lainnya (text, email, password)
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