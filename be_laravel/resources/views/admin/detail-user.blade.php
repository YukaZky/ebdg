@extends('layouts.admin')

@section('content')
<div class="main-content-inner">
    <div class="main-content-wrap">
        <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
            <h3>Detail Pengguna: {{ $user->name }}</h3>
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
                    <a href="{{ route('admin.users') }}">
                        <div class="text-tiny">Pengguna</div>
                    </a>
                </li>
                <li>
                    <i class="icon-chevron-right"></i>
                </li>
                <li>
                    <div class="text-tiny">Detail Pengguna</div>
                </li>
            </ul>
        </div>

        <div class="wg-box mb-20">
            <div class="flex items-center justify-between gap10 flex-wrap">
                <h5 class="f-w-700">Profil Pengguna</h5>
                <a class="tf-button style-1" href="{{ route('admin.users') }}"><i class="icon-arrow-left"></i>Kembali</a>
            </div>
            <div class="wg-table">
                <div class="row">
                    <div class="col-md-3 text-center">
                        {{-- <img src="https://via.placeholder.com/150" class="img-fluid rounded-circle mb-3" alt="Avatar"> --}}
                    </div>
                    <div class="col-md-9">
                        <table class="table table-borderless">
                            <tr>
                                <th style="width: 200px;">Nama Lengkap</th>
                                <td>: {{ $user->name }}</td>
                            </tr>
                            <tr>
                                <th>Alamat Email</th>
                                <td>: {{ $user->email }}</td>
                            </tr>
                            <tr>
                                <th>Tanggal Bergabung</th>
                                <td>: {{ $user->created_at->format('d F Y, H:i') }}</td>
                            </tr>
                            <tr>
                                <th>Tipe Akun</th>
                                <td>: <span class="badge badge-{{ $user->utype === 'ADM' ? 'danger' : 'success' }}">{{ $user->utype === 'ADM' ? 'Administrator' : 'Pengguna' }}</span></td>
                            </tr>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <div class="wg-box">
            <h5 class="f-w-700 mb-20">Riwayat Pesanan</h5>
            <div class="wg-table table-all-user">
                <div class="table-responsive">
                    <table class="table table-striped table-bordered">
                        <thead>
                            <tr>
                                <th>ID Pesanan</th>
                                <th>Tanggal</th>
                                <th>Total</th>
                                <th>Status</th>
                                <th>Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($user->orders as $order)
                                <tr>
                                    <td>#{{ $order->id }}</td>
                                    <td>{{ $order->created_at->format('d F Y') }}</td>
                                    <td>Rp{{ number_format($order->total, 0, ',', '.') }}</td>
                                    <td>
                                        <span class="text-tiny-map {{ strtolower($order->status) }}">{{ ucfirst($order->status) }}</span>
                                    </td>
                                    <td>
                                        <div class="list-icon-function">
                                            <a href="{{ route('admin.order.details', ['order_id' => $order->id]) }}">
                                                <div class="item text-info">
                                                    <i class="icon-eye"></i>
                                                </div>
                                            </a>
                                        </div>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="text-center">Pengguna ini belum memiliki riwayat pesanan.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection