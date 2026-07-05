@extends('layouts.admin')

@section('content')
<div class="main-content-inner">
    <div class="main-content-wrap">
        <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
            <div>
                <h3>Iklan Pembuka</h3>
                <div class="text-tiny">Kelola gambar iklan yang tampil saat aplikasi pertama kali dibuka.</div>
            </div>
            <a class="tf-button style-1 w208" href="{{ route('admin.startup-ads.create') }}">
                <i class="icon-plus"></i>Tambah Iklan
            </a>
        </div>

        <div class="wg-box">
            @if (Session::has('status'))
                <p class="alert alert-success">{{ Session::get('status') }}</p>
            @endif

            <div class="table-responsive">
                <table class="table table-striped table-bordered align-middle">
                    <thead>
                        <tr>
                            <th>Gambar</th>
                            <th>Status</th>
                            <th>Opsi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse ($startupAds as $startupAd)
                            <tr>
                                <td>
                                    <img src="{{ asset('uploads/startup-ads/' . $startupAd->image) }}" alt="Iklan Pembuka" style="width:90px;height:120px;object-fit:contain;border-radius:12px;border:1px solid #eee;background:#fff;">
                                </td>
                                <td>
                                    @if ($startupAd->is_active)
                                        <span class="badge bg-success">Aktif</span>
                                    @else
                                        <span class="badge bg-secondary">Nonaktif</span>
                                    @endif
                                </td>
                                <td>
                                    <div class="list-icon-function">
                                        <a href="{{ route('admin.startup-ads.edit', $startupAd->id) }}">
                                            <div class="item edit"><i class="icon-edit-3"></i></div>
                                        </a>
                                        <form action="{{ route('admin.startup-ads.destroy', $startupAd->id) }}" method="POST">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="item text-danger delete" style="border:0;background:transparent;">
                                                <i class="icon-trash-2"></i>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="3" class="text-center">Belum ada iklan pembuka aplikasi.</td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <div class="divider"></div>
            {{ $startupAds->links('pagination::bootstrap-5') }}
        </div>
    </div>
</div>
@endsection
