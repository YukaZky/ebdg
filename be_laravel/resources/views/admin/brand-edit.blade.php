@extends('layouts.admin')
@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Edit Merek</h3>
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
                        <a href="{{ route('admin.brands') }}">
                            <div class="text-tiny">Merek</div>
                        </a>
                    </li>
                    <li>
                        <i class="icon-chevron-right"></i>
                    </li>
                    <li>
                        <div class="text-tiny">Ubah Merek</div>
                    </li>
                </ul>
            </div>
            <div class="wg-box">
                <form class="form-new-product form-style-1" action="{{ route('admin.brand.update') }}" method="POST"
                    enctype="multipart/form-data">
                    @csrf
                    @method('PUT')
                    {{-- Hidden input untuk mengirim ID merek yang akan diupdate --}}
                    <input type="hidden" name="id" value="{{ $brand->id }}">

                    <fieldset class="name">
                        <div class="body-title">Nama Brand <span class="tf-color-1">*</span></div>
                        <input class="flex-grow" type="text" placeholder="Nama Brand" name="name" tabindex="0"
                            value="{{ $brand->name }}" required>
                    </fieldset>
                    @error('name')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    {{-- Dropdown untuk Kategori --}}
                    <fieldset class="category">
                        <div class="body-title">Kategori <span class="tf-color-1">*</span></div>
                        <select name="category_id" class="flex-grow" required>
                            <option value="">Pilih Kategori</option>
                            @foreach ($categories as $category)
                                {{-- Menampilkan kategori yang sedang dipilih untuk merek ini --}}
                                <option value="{{ $category->id }}" @if($brand->category_id == $category->id) selected @endif>
                                    {{ $category->name }}
                                </option>
                            @endforeach
                        </select>
                    </fieldset>
                    @error('category_id')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <fieldset>
                        <div class="body-title">Unggah Gambar</div>
                        <div class="upload-image flex-grow">
                            {{-- Menampilkan gambar yang sudah ada --}}
                            <div class="item" id="imgpreview">
                                <img src="{{ asset('uploads/brands') }}/{{ $brand->image }}" class="effect8"
                                    alt="{{ $brand->name }}">
                            </div>
                            <div id="upload-file" class="item up-load">
                                <label class="uploadfile" for="myFile">
                                    <span class="icon">
                                        <i class="icon-upload-cloud"></i>
                                    </span>
                                    <span class="body-text">Ganti gambar atau <span class="tf-color">cari</span></span>
                                    {{-- Input file tidak 'required' saat edit --}}
                                    <input type="file" id="myFile" name="image" accept="image/*">
                                </label>
                            </div>
                        </div>
                    </fieldset>
                    @error('image')
                        <span class="alert alert-danger text-center">{{ $message }}</span>
                    @enderror

                    <div class="bot">
                        <div></div>
                        <button class="tf-button w208" type="submit">Perbarui</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
@endsection

@push('scripts')
    <script>
        $(function() {
            // Logika untuk pratinjau gambar saat file baru dipilih
            $("#myFile").on("change", function(e) {
                const [file] = this.files;
                if (file) {
                    $("#imgpreview img").attr('src', URL.createObjectURL(file));
                }
            });
        });
    </script>
@endpush