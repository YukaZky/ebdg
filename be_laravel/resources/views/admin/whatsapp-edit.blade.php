@extends('layouts.admin')

@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Pengaturan WhatsApp</h3>
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
                        <div class="text-tiny">Pengaturan WhatsApp</div>
                    </li>
                </ul>
            </div>

            <div class="wg-box">
                {{-- Tampilkan pesan sukses jika ada --}}
                @if (session('success'))
                    <div class="alert alert-success" role="alert">
                        {{ session('success') }}
                    </div>
                @endif

                <form class="form-new-product form-style-1" action="{{ route('admin.whatsapp.update') }}" method="POST">
                    @csrf
                    @method('PUT')

                    <fieldset class="name">
                        <div class="body-title">Nomor WhatsApp <span class="tf-color-1">*</span></div>
                        <input class="flex-grow" type="text" placeholder="Contoh: 62895xxxxxxxxx" name="whatsapp_number"
                            value="{{ old('whatsapp_number', $whatsappSetting->value) }}" required>
                    </fieldset>
                    <div class="text-tiny mb-3" style="padding-left: 15px; margin-top: -10px;">
                        Masukkan nomor WhatsApp diawali dengan kode negara (misal: 62) dan tanpa tanda '+' atau spasi.
                    </div>
                    @error('whatsapp_number')
                        <div class="alert alert-danger text-center">{{ $message }}</div>
                    @enderror

                    <div class="bot">
                        <div></div>
                        <button class="tf-button w208" type="submit">Simpan Perubahan</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
@endsection

