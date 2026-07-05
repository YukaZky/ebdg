@extends('layouts.admin')

@section('content')
<div class="main-content-inner">
    <div class="main-content-wrap">
        <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
            <div>
                <h3>{{ $mode === 'edit' ? 'Edit' : 'Tambah' }} Iklan Pembuka</h3>
                <div class="text-tiny">Upload gambar iklan yang akan tampil saat aplikasi pertama kali dibuka.</div>
            </div>
            <a class="tf-button style-1 w208" href="{{ route('admin.startup-ads.index') }}">Kembali</a>
        </div>

        <div class="wg-box">
            @if ($errors->any())
                <div class="alert alert-danger">
                    <ul class="mb-0">
                        @foreach ($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <form method="POST" enctype="multipart/form-data" action="{{ $mode === 'edit' ? route('admin.startup-ads.update', $startupAd->id) : route('admin.startup-ads.store') }}">
                @csrf
                @if ($mode === 'edit')
                    @method('PUT')
                @endif

                <fieldset class="name mb-3">
                    <label>Gambar Iklan {{ $mode === 'create' ? '(wajib)' : '(opsional)' }}</label>
                    <input type="file" name="image" accept="image/*" {{ $mode === 'create' ? 'required' : '' }}>
                    <div class="text-tiny mt-1">Gunakan gambar JPG, JPEG, PNG, atau WEBP. Ukuran maksimal 10MB. Jika masih gagal, kompres gambar lebih kecil terlebih dahulu.</div>
                    @if ($startupAd->image)
                        <div class="mt-3">
                            <img src="{{ asset('uploads/startup-ads/' . $startupAd->image) }}" alt="Iklan Pembuka" style="width:160px;max-height:220px;object-fit:contain;border-radius:16px;border:1px solid #eee;">
                        </div>
                    @endif
                </fieldset>

                <label class="d-flex align-items-center gap-2 mb-4">
                    <input type="checkbox" name="is_active" value="1" {{ old('is_active', $startupAd->is_active) ? 'checked' : '' }}>
                    Aktifkan iklan ini
                </label>

                <button type="submit" class="tf-button style-1">Simpan</button>
            </form>
        </div>
    </div>
</div>
@endsection
