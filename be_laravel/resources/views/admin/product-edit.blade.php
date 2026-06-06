@extends('layouts.admin')
@section('content')
    <div class="main-content-inner">
        <!-- main-content-wrap -->
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Edit Produk</h3>
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
                        <div class="text-tiny">Edit Produk</div>
                    </li>
                </ul>
            </div>
            <!-- form-edit-product -->
            <form class="tf-section-2 form-add-product" method="POST" enctype="multipart/form-data"
                action="{{ route('admin.product.update') }}">
                @csrf
                @method('PUT')
                <input type="hidden" name="id" value="{{ $product->id }}" />
                <div class="wg-box">
                    <fieldset class="name">
                        <div class="body-title mb-10">Nama Produk <span class="tf-color-1">*</span>
                        </div>
                        <input class="mb-10" type="text" placeholder="nama Produk" name="name" tabindex="0"
                            value="{{ $product->name }}" aria-required="true" required="">
                        <div class="text-tiny">Nama produk tidak boleh melebihi 100 karakter.</div>
                    </fieldset>
                    @error('name')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <fieldset class="name">
                        <div class="body-title mb-10">Link Produk <span class="tf-color-1">*</span></div>
                        <input class="mb-10" type="text" placeholder="masukkan Link Produk " name="slug"
                            tabindex="0" value="{{ $product->slug }}" aria-required="true" required="">
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
                                <select class="" name="category_id">
                                    <option>Pilih Kategori</option>
                                    @foreach ($categories as $category)
                                        <option value="{{ $category->id }}"
                                            {{ $product->category_id == $category->id ? 'selected' : '' }}>
                                            {{ $category->name }}
                                        </option>
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
                                <select class="" name="brand_id">
                                    <option>Pilih Merek</option>
                                    @foreach ($brands as $brand)
                                        <option value="{{ $brand->id }}"
                                            {{ $product->brand_id == $brand->id ? 'selected' : '' }}>{{ $brand->name }}
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
                        <textarea class="mb-10 ht-150" name="short_description" placeholder="Deskripsi Singkat" tabindex="0">{{ $product->short_description }}</textarea>
                        <div class="text-tiny">Deskripsi produk tidak boleh melebihi 100 karakter.</div>
                    </fieldset>
                    @error('short_description')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <fieldset class="description">
                        <div class="body-title mb-10">Deskripsi <span class="tf-color-1">*</span>
                        </div>
                        <textarea class="mb-10" name="description" placeholder="Deskripsi" tabindex="0" aria-required="true" required="">{{ $product->description }}</textarea>
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
                            @if ($product->image)
                                <div class="item" id="imgpreview">
                                    <img src="{{ asset('uploads/products') }}/{{ $product->image }}" class="effect8"
                                        alt="{{ $product->name }}">
                                </div>
                            @endif
                            <div id="upload-file" class="item up-load">
                                <label class="uploadfile" for="myFile">
                                    <span class="icon">
                                        <i class="icon-upload-cloud"></i>
                                    </span>
                                    <<span class="body-text">Letakkan gambar di sini <span
                                            class="tf-color">cari</span></span>
                                        <input type="file" id="myFile" name="image" accept="image/*">
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
                            @if ($product->images)
                                @foreach (explode(',', $product->images) as $img)
                                    <div class="relative inline-block image-wrapper mr-2 mb-2 item gitems">
                                        <img src="{{ asset('uploads/products') }}/{{ trim($img) }}"
                                            alt="{{ $product->images }}" class="w-24 h-24 object-cover rounded border" />

                                        <button type="button"
                                            class="absolute bg-white flex items-center justify-center text-sm shadow-md delete-image-button"
                                            style="top: 5px; right: 5px; padding: 5px 10px; color: red;"
                                            data-product-id="{{ $product->id }}" data-filename="{{ trim($img) }}"
                                            title="Delete Image">
                                            &times;
                                        </button>
                                    </div>
                                @endforeach
                            @endif
                            <div id="galUpload" class="item up-load">
                                <label class="uploadfile" for="gFile">
                                    <span class="icon">
                                        <i class="icon-upload-cloud"></i>
                                    </span>
                                    <span class="body-text">Letakkan gambar di sini <span
                                            class="tf-color">cari</span></span>
                                    <!-- input untuk memilih file, bisa diklik -->
                                    <input type="file" id="gFile" accept="image/*" multiple
                                        style="display: none;">

                                    <!-- input tersembunyi untuk menyimpan semua file (yang akan dikirim saat submit) -->
                                    <input type="file" id="allImages" name="images[]" accept="image/*" multiple
                                        style="display: none;">
                                </label>
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
                            <input class="mb-10" type="text" placeholder="masukkan Harga standar"
                                name="regular_price" tabindex="0" value="{{ $product->regular_price }}"
                                aria-required="true" required="">
                        </fieldset>
                        @error('regular_price')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                        <fieldset class="name">
                            <div class="body-title mb-10">Harga Promo <span class="tf-color-1">*</span></div>
                            <input class="mb-10" type="text" placeholder="masukkan Harga Jual" name="sale_price"
                                tabindex="0" value="{{ $product->sale_price }}" aria-required="true" required="">
                        </fieldset>
                        @error('sale_price')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                    </div>


                    <div class="cols gap22">
                        <fieldset class="name">
                            <div class="body-title mb-10">Kode Barang<span class="tf-color-1">*</span>
                            </div>
                            <input class="mb-10" type="text" placeholder="Masukkan Kode Barang" name="SKU"
                                tabindex="0" value="{{ $product->SKU }}" aria-required="true" required="">
                        </fieldset>
                        @error('SKU')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                        <fieldset class="name">
                            <div class="body-title mb-10">Jumlah <span class="tf-color-1">*</span>
                            </div>
                            <input class="mb-10" type="text" placeholder="Masukkan Jumlah" name="quantity"
                                tabindex="0" value="{{ $product->quantity }}" aria-required="true" required="">
                        </fieldset>
                        @error('quantity')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                    </div>

                    <div class="cols gap22">
                        <fieldset class="name">
                            <div class="body-title mb-10">Tanggal Kadaluarsa</div>
                            <input class="mb-10" type="date" name="exp_date" tabindex="0"
                                value="{{ $product->exp_date }}">
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
                                <select class="" name="stock_status">
                                    <option value="instock" {{ $product->stock_status == 'instock' ? 'selected' : '' }}>
                                        Tersedia</option>
                                    <option value="outofstock"
                                        {{ $product->stock_status == 'outofstock' ? 'selected' : '' }}>Stok Habis
                                    </option>
                                </select>
                            </div>
                        </fieldset>
                        @error('stock_status')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                        <fieldset class="name">
                            <div class="body-title mb-10">Produk Unggulan</div>
                            <div class="select mb-10">
                                <select class="" name="featured">
                                    <option value="0" {{ $product->featured == 0 ? 'selected' : '' }}>Tidak</option>
                                    <option value="1" {{ $product->featured == 1 ? 'selected' : '' }}>Ya</option>
                                </select>
                            </div>
                        </fieldset>
                        @error('featured')
                            <span class="alert alert-danger text-center">{{ $message }}</span>
                        @enderror
                    </div>
                    <div class="cols gap10">
                        <button class="tf-button w-full" type="submit">Perbarui Produk</button>
                    </div>
                </div>
            </form>
            <!-- /form-edit-product -->
        </div>
        <!-- /main-content-wrap -->
    </div>
@endsection

@push('scripts')
    <script>
        $(function() {
            let dataTransfer = new DataTransfer(); // untuk menyimpan file secara dinamis

            $("#gFile").on("change", function(e) {
                const newFiles = Array.from(this.files);

                newFiles.forEach((file) => {
                    dataTransfer.items.add(file); // tambahkan file ke dataTransfer

                    // preview gambar
                    $(`<div class="item gitems"><img src="${URL.createObjectURL(file)}"/></div>`)
                        .insertBefore("#galUpload");
                });

                // set file list hasil gabungan ke input hidden
                document.getElementById("allImages").files = dataTransfer.files;

                // reset input utama supaya bisa pilih file yang sama lagi
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

            $('select[name="category_id"]').on('change', function() {
                const categoryId = $(this).val();
                const brandSelect = $('select[name="brand_id"]');

                // Simpan ID merek yang sedang dipilih (jika ada) untuk pembandingan
                const currentSelectedBrandId = "{{ $product->brand_id }}";

                // Kosongkan daftar merek yang lama dan tambahkan opsi default
                brandSelect.empty().append('<option value="">Pilih Merek</option>');

                // Hanya jalankan jika sebuah kategori dipilih
                if (categoryId) {
                    // Lakukan request ke server untuk mengambil merek yang sesuai
                    $.ajax({
                        url: "{{ route('admin.get_brands_by_category') }}",
                        type: 'GET',
                        data: {
                            category_id: categoryId
                        },
                        success: function(brands) {
                            if (brands.length > 0) {
                                // Loop melalui data merek yang diterima dari server
                                $.each(brands, function(key, brand) {
                                    // Buat tag <option> baru untuk setiap merek
                                    let option = $(
                                        `<option value="${brand.id}">${brand.name}</option>`
                                        );

                                    // Jika ID merek dari server sama dengan ID merek produk,
                                    // tandai sebagai 'selected'
                                    if (brand.id == currentSelectedBrandId) {
                                        option.attr('selected', 'selected');
                                    }

                                    brandSelect.append(option);
                                });
                            }
                        }
                    });
                }
            });

            // 2. PENTING: Pemicu (trigger) saat halaman pertama kali dimuat
            // Kode ini akan menjalankan fungsi di atas secara otomatis saat halaman edit terbuka,
            // memastikan dropdown merek sudah terisi dengan benar sesuai kategori produk.
            if ($('select[name="category_id"]').val()) {
                $('select[name="category_id"]').trigger('change');
            }
        });
    </script>
    <script>
        $('.delete-image-button').on('click', function(e) {
            e.preventDefault();

            const button = $(this);
            const productId = button.data('product-id');
            const filename = button.data('filename');

            swal({
                title: "Are you sure?",
                text: "You want to delete this image?",
                icon: "warning",
                buttons: ["No", "Yes"],
                dangerMode: true,
            }).then(function(result) {
                if (result) {
                    $.ajax({
                        url: "{{ route('admin.product.deleteImage.ajax') }}",
                        type: 'DELETE',
                        data: {
                            _token: '{{ csrf_token() }}',
                            product_id: productId,
                            filename: filename
                        },
                        success: function(response) {
                            if (response.success) {
                                button.closest('.image-wrapper').fadeOut(300, function() {
                                    $(this).remove();
                                });
                                swal("Deleted!", "Image has been deleted.", "success");
                            } else {
                                swal("Oops!", "Failed to delete image.", "error");
                            }
                        },
                        error: function() {
                            swal("Error!", "An error occurred while deleting the image.",
                                "error");
                        }
                    });
                }
            });
        });
    </script>
@endpush
