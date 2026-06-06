@extends('layouts.admin')
@section('content')
    <style>
        .table-transaction>tbody>tr:nth-of-type(odd) {
            --bs-table-accent-bg: #fff !important;
        }
    </style>
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Detail Pesanan</h3>
                <ul class="breadcrumbs flex items-center flex-wrap justify-start gap10">
                    <li><a href="{{ route('admin.index') }}"><div class="text-tiny">Menu Utama</div></a></li>
                    <li><i class="icon-chevron-right"></i></li>
                    <li><div class="text-tiny">Detail Pesanan</div></li>
                </ul>
            </div>

            <div class="wg-box">
                <div class="flex items-center justify-between gap10 flex-wrap">
                    <div class="wg-filter flex-grow">
                        <h5>Detail Pesanan</h5>
                    </div>
                    <a class="tf-button style-1 w208" href="{{ route('admin.orders') }}">Kembali</a>
                </div>
                <div class="table-responsive">
                    @if (Session::has('status'))
                        <p class="alert alert-success">{{ Session::get('status') }}</p>
                    @endif
                    <table class="table table-striped table-bordered">
                        <tr>
                            <th>No Pesanan</th><td>{{ $order->id }}</td>
                            <th>No Telepon</th><td>{{ $order->phone }}</td>
                            <th>Kode Pos</th><td>{{ $order->zip }}</td>
                        </tr>
                        <tr>
                            <th>Tanggal Pemesanan</th><td>{{ $order->created_at }}</td>
                            <th>Tanggal Diantar</th><td>{{ $order->delivered_date }}</td>
                            <th>Tanggal Ditolak</th><td>{{ $order->canceled_date }}</td>
                        </tr>
                        <tr>
                            <th>Ongkos Kirim</th><td>{{ $order->ongkir }}</td>
                            <th>Jenis Pengiriman</th><td>{{ $order->mode_pengiriman }}</td>
                            <th>Tipe Pengiriman</th><td>{{ $order->jenis_pengiriman }}</td>
                        </tr>
                        <tr>
                            <th>Status Pesanan</th>
                            <td colspan="5">
                                {{-- 👇👇👇 BAGIAN INI DIPERBARUI 👇👇👇 --}}
                                @if ($order->status == 'delivered')
                                    <span class="badge bg-success">Terkirim (Diterima)</span>
                                @elseif($order->status == 'shipping')
                                    <span class="badge bg-info">Dikirim</span>
                                @elseif ($order->status == 'canceled')
                                    <span class="badge bg-danger">Ditolak</span>
                                @else
                                    <span class="badge bg-warning">Dipesan</span>
                                @endif
                                {{-- 👆👆👆 AKHIR DARI BAGIAN YANG DIPERBARUI 👆👆👆 --}}
                            </td>
                        </tr>
                    </table>
                </div>
            </div>

            {{-- ... sisa kode untuk Daftar Pesanan & Alamat Pemesan tidak perlu diubah ... --}}
            <div class="wg-box mt-5">
                <div class="flex items-center justify-between gap10 flex-wrap">
                    <div class="wg-filter flex-grow">
                        <h5>Daftar Item Pesanan</h5>
                    </div>
                </div>
                <div class="table-responsive">
                    <table class="table table-striped table-bordered">
                        <thead>
                            <tr>
                                <th>Nama Barang</th>
                                <th class="text-center">Harga</th>
                                <th class="text-center">Jumlah</th>
                                <th class="text-center">Kode Barang</th>
                                <th class="text-center">Kategori</th>
                                <th class="text-center">Merek</th>
                                <th class="text-center">Pilihan</th>
                                <th class="text-center">Status Pengembalian</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($orderItems as $item)
                                <tr>
                                    <td class="pname">
                                        <div class="image"><img src="{{ asset('uploads/products/thumbnails') }}/{{ $item->product->image }}" alt="" class="image"></div>
                                        <div class="name"><a href="{{ route('shop.product.details', ['product_slug' => $item->product->slug]) }}" target="_blank" class="body-title-2">{{ $item->product->name }}</a></div>
                                    </td>
                                    <td class="text-center">${{ $item->price }}</td>
                                    <td class="text-center">{{ $item->quantity }}</td>
                                    <td class="text-center">{{ $item->product->SKU }}</td>
                                    <td class="text-center">{{ $item->product->category->name }}</td>
                                    <td class="text-center">{{ $item->product->brand->name }}</td>
                                    <td class="text-center">{{ $item->option }}</td>
                                    <td class="text-center">{{ $item->rstatus == 0 ? 'Tidak' : 'Iya' }}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
                <div class="divider"></div>
                <div class="flex items-center justify-between flex-wrap gap10 wgp-pagination">{{ $orderItems->links('pagination::bootstrap-5') }}</div>
            </div>
            <div class="wg-box mt-5">
                <h5>Alamat Pemesan</h5>
                <div class="my-account__address-item col-md-6">
                    <div class="my-account__address-item__detail">
                        <p>Nama Penerima : {{ $order->name }}</p>
                        <p>Alamat : {{ $order->address }}</p>
                        <p>Nama Jalan : {{ $order->locality }}</p>
                        <p>Kota : {{ $order->city }}, {{ $order->country }}</p>
                        <p>Petunjuk : {{ $order->landmark }}</p>
                        <p>Kode Pos : {{ $order->zip }}</p>
                        <br>
                        <p>No Telepon : {{ $order->phone }}</p>
                    </div>
                </div>
            </div>
            <div class="wg-box mt-5">
                <h5>Transaksi</h5>
                <div class="table-responsive">
                    <table class="table table-striped table-bordered table-transaction">
                        <tbody>
                            <tr>
                                <th>Jumlah Sementara</th><td>${{ $order->subtotal }}</td>
                                <th>Pajak</th><td>${{ $order->tax }}</td>
                                <th>Diskon</th><td>${{ $order->discount }}</td>
                            </tr>
                            <tr>
                                <th>Jumlah</th><td>${{ $order->total }}</td>
                                <th>Metode Pembayaran</th><td>{{ $order->transaction->mode }}</td>
                                <th>Status</th>
                                <td>
                                    @if ($transaction->status == 'approved')
                                        <span class="badge bg-success">Disetujui (Lunas)</span>
                                    @elseif ($transaction->status == 'declined')
                                        <span class="badge bg-danger">Ditolak</span>
                                    @elseif ($transaction->status == 'refunded')
                                        <span class="badge bg-secondary">Dikembalikan</span>
                                    @else
                                        <span class="badge bg-warning">Tertunda</span>
                                    @endif
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="wg-box mt-5">
                <h5>Perbarui Status Pesanan</h5>
                <form action="{{ route('admin.order.status.update') }}" method="POST">
                    @csrf
                    @method('PUT')
                    <input type="hidden" name="order_id" value="{{ $order->id }}">
                    <div class="row">
                        <div class="col-md-3">
                            <div class="select">
                                <select name="order_status" id="order_status">
                                    {{-- 👇👇👇 BAGIAN INI DIPERBARUI 👇👇👇 --}}
                                    <option value="ordered" {{ $order->status == 'ordered' ? 'selected' : '' }}>Dipesan</option>
                                    <option value="shipping" {{ $order->status == 'shipping' ? 'selected' : '' }}>Dikirim</option>
                                    <option value="delivered" {{ $order->status == 'delivered' ? 'selected' : '' }}>Terkirim (Diterima)</option>
                                    <option value="canceled" {{ $order->status == 'canceled' ? 'selected' : '' }}>Ditolak</option>
                                    {{-- 👆👆👆 AKHIR DARI BAGIAN YANG DIPERBARUI 👆👆👆 --}}
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <button type="submit" class="btn btn-primary tf-button w208">Perbarui Status Pemesanan</button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
@endsection