@extends('layouts.admin')
@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Manajemen Profil Usaha</h3>
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
                        <div class="text-tiny">Manajemen Profil Usaha</div>
                    </li>
                </ul>
            </div>
            
            <div class="wg-box">
                @if (session('status'))
                    <script>
                        document.addEventListener('DOMContentLoaded', function() {
                            Toastify({
                                text: "{{ session('status') }}",
                                duration: 3500,
                                close: true,
                                gravity: "top",
                                position: "right",
                                stopOnFocus: true,
                                style: {
                                    padding: "16px",
                                    fontSize: "15px",
                                    background: "#27ae60",
                                    color: "white",
                                    borderRadius: "8px"
                                }
                            }).showToast();
                        });
                    </script>
                @endif
                <form class="form-new-product form-style-1" action="{{ route('admin.about.update') }}" method="POST"
                    enctype="multipart/form-data" id="aboutForm" novalidate>
                    @csrf
                    @method('PUT')
                    
                    {{-- ======================= FIELD UPLOAD LOGO (BARU) ======================= --}}
                    <fieldset>
                        <div class="body-title">Logo Usaha</div>
                        <div class="upload-image flex-grow mt-10">
                            {{-- Kontainer Pratinjau Logo --}}
                            <div class="item" id="logoPreview" style="{{ $about->logo_image ? '' : 'display:none' }}">
                                <img src="{{ $about->logo_image ? asset('uploads/about/' . $about->logo_image) : '' }}" class="effect8" alt="Pratinjau Logo">
                            </div>
                            {{-- Tombol Upload Logo --}}
                            <div id="upload-logo-file" class="item up-load">
                                <label class="uploadfile" for="logoFile">
                                    <span class="icon">
                                        <i class="icon-upload-cloud"></i>
                                    </span>
                                    <span class="body-text">
                                        Letakkan logo di sini <span class="tf-color">cari</span>
                                        <span style="display: block; color: #888; font-size: 12px; margin-top: 5px;">
                                            Rasio 1:1, format SVG/PNG direkomendasikan
                                        </span>
                                    </span>
                                    <input type="file" id="logoFile" name="logo_image" accept="image/*">
                                </label>
                            </div>
                        </div>
                    </fieldset>
                    {{-- ======================= AKHIR FIELD UPLOAD LOGO ======================= --}}

                    <fieldset>
                        <div class="body-title">Gambar Banner</div>
                        <div class="upload-image flex-grow mt-10">
                            {{-- Kontainer Pratinjau Banner --}}
                            <div class="item" id="bannerPreview" style="{{ $about->poster_image ? '' : 'display:none' }}">
                                <img src="{{ $about->poster_image ? asset('uploads/about/' . $about->poster_image) : '' }}" class="effect8" alt="Pratinjau Poster">
                            </div>
                            {{-- Tombol Upload Banner --}}
                            <div id="upload-banner-file" class="item up-load">
                                <label class="uploadfile" for="bannerFile">
                                    <span class="icon">
                                        <i class="icon-upload-cloud"></i>
                                    </span>
                                    <span class="body-text">
                                        Letakkan banner di sini <span class="tf-color">cari</span>
                                        <span style="display: block; color: #888; font-size: 12px; margin-top: 5px;">
                                            Rasio 4:1 (Contoh: 1600 x 400px)
                                        </span>
                                    </span>
                                    <input type="file" id="bannerFile" name="poster_image" accept="image/*">
                                </label>
                            </div>
                        </div>
                    </fieldset>

                    {{-- Sisa field form lainnya tetap sama --}}
                    <fieldset class="name">
                        <div class="body-title">Cerita Kami <span class="tf-color-1">*</span></div>
                        <textarea class="flex-grow" name="our_story" rows="6" placeholder="Cerita kami..." required>{{ old('our_story', $about->our_story) }}</textarea>
                    </fieldset>
                    
                    <fieldset class="name">
                        <div class="body-title">Visi Kami <span class="tf-color-1">*</span></div>
                        <textarea class="flex-grow" name="our_vision" rows="6" placeholder="Visi kami..." required>{{ old('our_vision', $about->our_vision) }}</textarea>
                    </fieldset>
                    
                    <fieldset class="name">
                        <div class="body-title">Misi Kami <span class="tf-color-1">*</span></div>
                        <textarea class="flex-grow" name="our_mission" rows="6" placeholder="Misi kami..." required>{{ old('our_mission', $about->our_mission) }}</textarea>
                    </fieldset>

                    <fieldset class="name">
                        <div class="body-title">Tentang Perusahaan <span class="tf-color-1">*</span></div>
                        <textarea class="flex-grow" name="the_company" rows="6" placeholder="Tentang perusahaan..." required>{{ old('the_company', $about->the_company) }}</textarea>
                    </fieldset>

                    <div class="bot">
                        <div></div>
                        <button class="tf-button w208" type="submit">Simpan Perubahan</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
@endsection

@push('scripts')
    <script>
        $(function() {
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
                        background: "#e74c3c",
                        color: "white",
                        borderRadius: "8px"
                    }
                }).showToast();
            }

            $('#aboutForm').on('submit', function(e) {
                let formIsValid = true;
                
                $(this).find('textarea[required]').each(function() {
                    const fieldName = $(this).closest('fieldset').find('.body-title').text().trim().replace('*', '').trim();
                    let errorMessage = '';

                    if (!$(this).val().trim()) {
                        errorMessage = 'Kolom "' + fieldName + '" tidak boleh kosong.';
                        formIsValid = false;
                    }
                    
                    if (errorMessage) {
                        showErrorToast(errorMessage);
                        return false;
                    }
                });

                if (!formIsValid) {
                    e.preventDefault();
                }
            });


            // Logika untuk pratinjau LOGO
            $("#logoFile").on("change", function(e) {
                const [file] = this.files;
                if (file) {
                    const previewUrl = URL.createObjectURL(file);
                    $("#logoPreview img").attr('src', previewUrl);
                    $("#logoPreview").show();
                }
            });

            // Logika untuk pratinjau BANNER
            $("#bannerFile").on("change", function(e) {
                const [file] = this.files;
                if (file) {
                    const previewUrl = URL.createObjectURL(file);
                    $("#bannerPreview img").attr('src', previewUrl);
                    $("#bannerPreview").show();
                }
            });
            
             $('.alert.alert-danger').remove();
        });
    </script>
@endpush