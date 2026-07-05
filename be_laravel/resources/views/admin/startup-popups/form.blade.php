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

            <form id="startup-ad-form" method="POST" enctype="multipart/form-data" action="{{ $mode === 'edit' ? route('admin.startup-ads.update', $startupAd->id) : route('admin.startup-ads.store') }}">
                @csrf
                @if ($mode === 'edit')
                    @method('PUT')
                @endif

                <fieldset class="name mb-3">
                    <label>Gambar Iklan {{ $mode === 'create' ? '(wajib)' : '(opsional)' }}</label>
                    <input id="startup-ad-image" type="file" name="image" accept="image/png,image/jpeg,image/webp">
                    <div class="text-tiny mt-1">Gunakan PNG, JPG, JPEG, atau WEBP. Gambar besar akan diperkecil otomatis sebelum disimpan.</div>
                    <div id="startup-ad-image-note" class="text-tiny mt-1" style="color:#2563eb;"></div>
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

                <button id="startup-ad-submit" type="submit" class="tf-button style-1">Simpan</button>
            </form>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
(function () {
    const form = document.getElementById('startup-ad-form');
    const input = document.getElementById('startup-ad-image');
    const button = document.getElementById('startup-ad-submit');
    const note = document.getElementById('startup-ad-image-note');

    if (!form || !input) return;

    function setFile(file) {
        const dataTransfer = new DataTransfer();
        dataTransfer.items.add(file);
        input.files = dataTransfer.files;
    }

    function readImage(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = function (event) {
                const img = new Image();
                img.onload = () => resolve(img);
                img.onerror = reject;
                img.src = event.target.result;
            };
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    function canvasToBlob(canvas, quality) {
        return new Promise((resolve) => {
            canvas.toBlob((blob) => resolve(blob), 'image/webp', quality);
        });
    }

    async function compressImage(file) {
        if (!file || !file.type.startsWith('image/')) return file;
        if (file.size <= 1700 * 1024) return file;

        const img = await readImage(file);
        const maxSide = 1100;
        const scale = Math.min(1, maxSide / Math.max(img.width, img.height));
        const width = Math.max(1, Math.round(img.width * scale));
        const height = Math.max(1, Math.round(img.height * scale));

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, width, height);
        ctx.drawImage(img, 0, 0, width, height);

        let quality = 0.9;
        let blob = await canvasToBlob(canvas, quality);
        while (blob && blob.size > 1700 * 1024 && quality > 0.55) {
            quality -= 0.08;
            blob = await canvasToBlob(canvas, quality);
        }

        if (!blob || blob.size >= file.size) return file;
        return new File([blob], 'startup-ad-' + Date.now() + '.webp', { type: 'image/webp' });
    }

    input.addEventListener('change', async function () {
        const file = input.files && input.files[0] ? input.files[0] : null;
        if (!file) return;

        const originalSize = file.size;
        note.textContent = 'Menyiapkan gambar...';
        input.disabled = true;
        button.disabled = true;

        try {
            const optimized = await compressImage(file);
            setFile(optimized);
            const beforeKb = Math.round(originalSize / 1024);
            const afterKb = Math.round(optimized.size / 1024);
            note.textContent = optimized.size < originalSize
                ? 'Gambar otomatis diperkecil: ' + beforeKb + ' KB menjadi ' + afterKb + ' KB.'
                : 'Gambar siap diupload: ' + afterKb + ' KB.';
        } catch (error) {
            note.textContent = 'Gambar tetap dipakai tanpa kompresi otomatis.';
        } finally {
            input.disabled = false;
            button.disabled = false;
        }
    });
})();
</script>
@endpush
