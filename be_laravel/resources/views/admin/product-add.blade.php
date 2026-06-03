@extends('layouts.admin')
@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Tambah Produk</h3>
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
                        <a href="{{ route('admin.products') }}">
                            <div class="text-tiny">Produk</div>
                        </a>
                    </li>
                    <li>
                        <i class="icon-chevron-right"></i>
                    </li>
                    <li>
                        <div class="text-tiny">Tambah Produk</div>
                    </li>
                </ul>
            </div>
            <form class="tf-section-2 form-add-product" method="POST" enctype="multipart/form-data"
                action="{{ route('admin.product.store') }}" id="productForm" novalidate>
                @csrf
                <div class="wg-box">
                    <fieldset class="name">
                        <div class="body-title mb-10">Nama Produk<span class="tf-color-1">*</span>
                        </div>
                        <input class="mb-10" type="text" placeholder="Masukkan Nama Produk" name="name"
                            tabindex="0" value="{{ old('name') }}" required>
                        <div class="text-tiny">Nama produk tidak boleh melebihi 100 karakter.</div>
                    </fieldset>
                    @error('name')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <fieldset class="name">
                        <div class="body-title mb-10">Link produk <span class="tf-color-1">*</span></div>
                        <input class="mb-10" type="text" placeholder="masukkan Link Produk" name="slug"
                            tabindex="0" value="{{ old('slug') }}" required>
                        <div class="text-tiny">Link produk tidak boleh melebihi 100 karakter.</div>
                    </fieldset>
                    @error('slug')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <div class="gap22 cols">
                        <fieldset class="category">
                            <div class="body-title mb-10">Kategori <span class="tf-color-1">*</span>
                            </div>
                            <div class="select">
                                <select name="category_id" required>
                                    <option value="">Pilih Kategori</option>
                                    @foreach ($categories as $category)
                                        <option value="{{ $category->id }}"
                                            {{ old('category_id') == $category->id ? 'selected' : '' }}>
                                            {{ $category->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </fieldset>
                        @error('category_id')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                        <fieldset class="brand">
                            <div class="body-title mb-10">Merek <span class="tf-color-1">*</span>
                            </div>
                            <div class="select">
                                <select name="brand_id" required>
                                    <option value="">Pilih Merek</option>
                                    @foreach ($brands as $brand)
                                        <option value="{{ $brand->id }}"
                                            {{ old('brand_id') == $brand->id ? 'selected' : '' }}>{{ $brand->name }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>
                        </fieldset>
                        @error('brand_id')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                    </div>

                    <fieldset class="shortdescription">
                        <div class="body-title mb-10">Deskripsi Singkat</div>
                        <textarea class="mb-10 ht-150" name="short_description" placeholder="Deskripsi Singkat" tabindex="0">{{ old('short_description') }}</textarea>
                        <div class="text-tiny">Deskripsi Produk tidak boleh melebihi 100 karakter.</div>
                    </fieldset>
                    @error('short_description')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <fieldset class="description">
                        <div class="body-title mb-10">Deskripsi <span class="tf-color-1">*</span>
                        </div>
                        <textarea class="mb-10" name="description" placeholder="Deskripsi" tabindex="0" required>{{ old('description') }}</textarea>
                        <div class="text-tiny">Deskripsi produk tidak boleh melebihi 100 karakter.</div>
                    </fieldset>
                    @error('description')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror
                </div>
                <div class="wg-box">
                    <fieldset>
                        <div class="body-title">Unggah Gambar <span class="tf-color-1">*</span>
                        </div>
                        <div class="upload-image flex-grow">
                            <div class="item" id="imgpreview" style="display:none">
                                <img src="" class="effect8" alt="Preview Gambar Utama">
                            </div>
                            <div id="upload-file" class="item up-load">
                                <label class="uploadfile" for="myFile">
                                    <span class="icon">
                                        <i class="icon-upload-cloud"></i>
                                    </span>
                                    <span class="body-text">Letakkan gambar di sini <span
                                            class="tf-color">cari</span></span>
                                    <input type="file" id="myFile" name="image" accept="image/*" required>
                                </label>
                            </div>
                        </div>
                    </fieldset>
                    @error('image')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <fieldset>
                        <div class="body-title mb-10">Unggah Galeri Gambar</div>
                        <div class="upload-image mb-16">
                            <div id="galUpload" class="item up-load">
                                <label class="uploadfile" for="gFile">
                                    <span class="icon">
                                        <i class="icon-upload-cloud"></i>
                                    </span>
                                    <span class="body-text">Letakkan gambar di sini <span
                                            class="tf-color">cari</span></span>
                                </label>
                                <input type="file" id="gFile" accept="image/*" multiple style="display: none;">
                                <input type="file" id="allImages" name="images[]" accept="image/*" multiple
                                    style="display: none;">
                            </div>
                        </div>
                    </fieldset>
                    @error('images')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror
                    <div class="form-group">
                        <label for="weight_gram">Berat (gram)</label>
                        <input type="number" min="0" step="1" class="form-control" id="weight_gram"
                            name="weight_gram" value="{{ old('weight_gram', $product->weight_gram ?? 0) }}">
                    </div>

                    <div class="cols gap22">
                        <fieldset class="name">
                            <div class="body-title mb-10">Harga Jual <span class="tf-color-1">*</span></div>
                            <input class="mb-10" type="number" placeholder="Masukkan Harga Standar"
                                name="regular_price" tabindex="0" value="{{ old('regular_price') }}" required>
                        </fieldset>
                        @error('regular_price')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                        <fieldset class="name">
                            <div class="body-title mb-10">Harga Promo <span class="tf-color-1">*</span></div>
                            <input class="mb-10" type="number" placeholder="Masukkan Harga Jual" name="sale_price"
                                tabindex="0" value="{{ old('sale_price') }}" required>
                        </fieldset>
                        @error('sale_price')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                    </div>

                    <div class="cols gap22">
                        <fieldset class="name">
                            <div class="body-title mb-10">Kode Barang <span class="tf-color-1">*</span>
                            </div>
                            <input class="mb-10" type="text" placeholder="Masukkan Kode Barang " name="SKU"
                                tabindex="0" value="{{ old('SKU') }}" required>
                        </fieldset>
                        @error('SKU')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                        <fieldset class="name">
                            <div class="body-title mb-10">Jumlah <span class="tf-color-1">*</span>
                            </div>
                            <input class="mb-10" type="number" placeholder="Massukkan Jumlah" name="quantity"
                                tabindex="0" value="{{ old('quantity') }}" required>
                        </fieldset>
                        @error('quantity')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                    </div>

                    <div class="cols gap22">
                        <fieldset class="name">
                            <div class="body-title mb-10">Tanggal Kadaluarsa</div>
                            <input class="mb-10" type="date" name="exp_date" tabindex="0"
                                value="{{ old('exp_date') }}">
                        </fieldset>
                        @error('exp_date')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                        <fieldset></fieldset>
                    </div>

                    <div class="cols gap22">
                        <fieldset class="name">
                            <div class="body-title mb-10">Stok</div>
                            <div class="select mb-10">
                                <select name="stock_status">
                                    <option value="instock" {{ old('stock_status') == 'instock' ? 'selected' : '' }}>
                                        Tersedia</option>
                                    <option value="outofstock"
                                        {{ old('stock_status') == 'outofstock' ? 'selected' : '' }}>Stok Habis</option>
                                </select>
                            </div>
                        </fieldset>
                        @error('stock_status')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                        <fieldset class="name">
                            <div class="body-title mb-10">Produk Unggulan</div>
                            <div class="select mb-10">
                                <select name="featured">
                                    <option value="0" {{ old('featured') == '0' ? 'selected' : '' }}>Tidak</option>
                                    <option value="1" {{ old('featured') == '1' ? 'selected' : '' }}>Ya</option>
                                </select>
                            </div>
                        </fieldset>
                        @error('featured')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                    </div>
                    <div class="cols gap10">
                        <button class="tf-button w-full" type="submit">Tambah Produk</button>
                    </div>
                </div>
            </form>
        </div>
    </div>
@endsection

@push('scripts')
    <script>
        $(function() {
            $('#productForm').on('change', 'select[name="category_id"]', function() {
                const categoryId = $(this).val();
                const brandSelect = $('select[name="brand_id"]');

                // Kosongkan dropdown merek
                brandSelect.empty().append('<option value="">Pilih Merek</option>');

                // Jika kategori dipilih (bukan pilihan default)
                if (categoryId) {
                    // Lakukan AJAX request untuk mendapatkan merek
                    $.ajax({
                        url: "{{ route('admin.get_brands_by_category') }}",
                        type: 'GET',
                        data: {
                            category_id: categoryId
                        },
                        success: function(brands) {
                            if (brands.length > 0) {
                                // Isi dropdown merek dengan data baru
                                $.each(brands, function(key, brand) {
                                    brandSelect.append(
                                        `<option value="${brand.id}">${brand.name}</option>`
                                    );
                                });
                            }
                        },
                        error: function() {
                            console.log('Gagal mengambil data merek.');
                        }
                    });
                }
            });
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
            $('#productForm').on('submit', function(e) {
                let formIsValid = true;

                // Memeriksa setiap input, select, dan textarea yang wajib diisi
                $(this).find('input[required], select[required], textarea[required]').each(function() {
                    const fieldName = $(this).closest('fieldset').find('.body-title').text().trim()
                        .replace('*', '').trim();
                    let errorMessage = '';

                    // Validasi untuk dropdown/select
                    if ($(this).is('select') && $(this).val() === "") {
                        errorMessage = 'Anda harus memilih salah satu opsi untuk kolom "' +
                            fieldName + '".';
                        formIsValid = false;
                    }

                    // Validasi untuk input file
                    if ($(this).is(':file') && $(this).get(0).files.length === 0) {
                        errorMessage = 'Anda harus mengunggah gambar untuk kolom "' + fieldName +
                            '".';
                        formIsValid = false;
                    }

                    // Validasi untuk input dan textarea lainnya
                    if (!$(this).is('select') && !$(this).is(':file') && !$(this).val()) {
                        errorMessage = 'Kolom "' + fieldName + '" tidak boleh kosong.';
                        formIsValid = false;
                    }

                    // Jika ada pesan eror, tampilkan notifikasi dan hentikan loop
                    if (errorMessage) {
                        showErrorToast(errorMessage);
                        return false;
                    }
                });

                // --- VALIDASI TAMBAHAN ---
                // Hanya periksa jika form masih dianggap valid sejauh ini
                if (formIsValid) {
                    const shortDescription = $('textarea[name="short_description"]').val();
                    if (shortDescription.length > 100) {
                        showErrorToast('Deskripsi Singkat tidak boleh melebihi 100 karakter.');
                        formIsValid = false;
                    }
                }

                // Mencegah form untuk submit jika tidak valid
                if (!formIsValid) {
                    e.preventDefault();
                }
            });

            // --- Logika lain yang sudah ada ---
            let dataTransfer = new DataTransfer();

            $("#gFile").on("change", function(e) {
                const newFiles = Array.from(this.files);
                newFiles.forEach((file) => {
                    dataTransfer.items.add(file);
                    $(`<div class="item gitems"><img src="${URL.createObjectURL(file)}"/></div>`)
                        .insertBefore("#galUpload");
                });
                document.getElementById("allImages").files = dataTransfer.files;
                this.value = "";
            });

            $("#myFile").on("change", function() {
                const [file] = this.files;
                if (file) {
                    $("#imgpreview img").attr('src', URL.createObjectURL(file));
                    $("#imgpreview").show();
                }
            });

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
