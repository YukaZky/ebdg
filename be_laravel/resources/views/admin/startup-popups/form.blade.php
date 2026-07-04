@extends('layouts.admin')
@section('content')
<div class="main-content-inner"><div class="main-content-wrap"><div class="wg-box">
<h3>{{ $mode === 'edit' ? 'Edit' : 'Tambah' }} Popup Pembuka Aplikasi</h3>
<form method="POST" enctype="multipart/form-data" action="{{ $mode === 'edit' ? url('/admin/' . 'startup-' . 'ads/' . $startupAd->id) : url('/admin/' . 'startup-' . 'ads') }}">
@csrf
@if ($mode === 'edit') @method('PUT') @endif
<label>Judul</label><input type="text" name="title" value="{{ old('title', $startupAd->title) }}">
<label>Subjudul</label><input type="text" name="subtitle" value="{{ old('subtitle', $startupAd->subtitle) }}">
<label>Teks Tombol</label><input type="text" name="button_text" value="{{ old('button_text', $startupAd->button_text ?: 'Belanja Sekarang') }}">
<label>Link Tujuan</label><input type="url" name="target_url" value="{{ old('target_url', $startupAd->target_url) }}">
<label>Gambar</label><input type="file" name="image" accept="image/*">
<label><input type="checkbox" name="is_active" value="1" {{ old('is_active', $startupAd->is_active) ? 'checked' : '' }}> Aktif</label>
<button type="submit" class="tf-button style-1">Simpan</button>
</form>
</div></div></div>
@endsection
