@extends('layouts.admin')
@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Tambah Kategori</h3>
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
                        <a href="{{ route('admin.categories') }}">
                            <div class="text-tiny">Kategori</div>
                        </a>
                    </li>
                    <li>
                        <i class="icon-chevron-right"></i>
                    </li>
                    <li>
                        <div class="text-tiny">Kategori Baru</div>
                    </li>
                </ul>
            </div>
            <div class="wg-box">
                <form class="form-new-product form-style-1" action="{{ route('admin.category.store') }}" method="POST"
                    enctype="multipart/form-data" id="categoryForm" novalidate>
                    @csrf
                    <fieldset class="name">
                        <div class="body-title">Nama Kategori <span class="tf-color-1">*</span></div>
                        <input class="flex-grow" type="text" placeholder="Nama Kategori" name="name" tabindex="0"
                            value="{{ old('name') }}" required>
                    </fieldset>
                    @error('name')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror
                    <fieldset class="name">
                        <div class="body-title">Link Kategori <span class="tf-color-1">*</span></div>
                        <input class="flex-grow" type="text" placeholder="Link Kategori" name="slug" tabindex="0"
                            value="{{ old('slug') }}" required>
                    </fieldset>
                    @error('slug')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror
                    <fieldset>
                        <div class="body-title">Unggah Gambar <span class="tf-color-1">*</span>
                        </div>
                        <div class="upload-image flex-grow">
                            <div class="item" id="imgpreview" style="display:none">
                                <img src="" class="effect8" alt="Preview Gambar Kategori">
                            </div>
                            <div id="upload-file" class="item up-load">
                                <label class="uploadfile" for="myFile">
                                    <span class="icon">
                                        <i class="icon-upload-cloud"></i>
                                    </span>
                                    <span class="body-text">Letakkan gambar di sini <span class="tf-color">cari</span></span>
                                    <input type="file" id="myFile" name="image" accept="image/*" required>
                                </label>
                            </div>
                        </div>
                    </fieldset>
                    @error('image')
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
            $('#categoryForm').on('submit', function(e) {
                let formIsValid = true;
                
                // Memeriksa setiap input yang wajib diisi
                $(this).find('input[required]').each(function() {
                    const fieldName = $(this).closest('fieldset').find('.body-title').text().trim().replace('*', '').trim();
                    let errorMessage = '';

                    // Validasi untuk input file
                    if ($(this).is(':file') && $(this).get(0).files.length === 0) {
                        errorMessage = 'Anda harus mengunggah gambar untuk kolom "' + fieldName + '".';
                        formIsValid = false;
                    }

                    // Validasi untuk input teks
                    if ($(this).is('input[type="text"]') && !$(this).val()) {
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

            // Logika untuk pratinjau gambar
            $("#myFile").on("change", function(e) {
                const [file] = this.files;
                if (file) {
                    $("#imgpreview img").attr('src', URL.createObjectURL(file));
                    $("#imgpreview").show();
                }
            });

            // Logika untuk membuat slug otomatis
            $("input[name='name']").on("change", function() {
                $("input[name='slug']").val(StringToSlug($(this).val()));
            });

            function StringToSlug(Text) {
                return Text.toLowerCase()
                    .replace(/[^\w ]+/g, "")
                    .replace(/ +/g, "-");
            }
        });
    </script>
@endpush