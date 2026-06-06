@extends('layouts.admin')
@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Daftar Pesanan</h3>
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
                        <div class="text-tiny">Pesanan</div>
                    </li>
                </ul>
            </div>

            <div class="wg-box">
                <div class="flex items-center justify-between gap10 flex-wrap">
                    <div class="wg-filter flex-grow">
                        {{-- Form Pencarian untuk Live Search --}}
                        <form class="form-search" id="searchForm">
                            <fieldset class="name">
                                <input type="text" id="searchInput"
                                    placeholder="Cari No Pesanan, Nama, atau No Telepon..." class="" name="name"
                                    tabindex="2" value="">
                            </fieldset>
                            <div class="button-submit">
                                <button class="" type="submit"><i class="icon-search"></i></button>
                            </div>
                        </form>
                    </div>
                </div>
                <div class="wg-table table-all-user">
                    <div class="table-responsive">
                        <table class="table table-striped table-bordered">
                            <thead>
                                <tr>
                                    <th style="width:70px">No Pesanan</th>
                                    <th class="text-center">Nama</th>
                                    <th class="text-center">No Telepon</th>
                                    <th class="text-center">Total</th>
                                    <th class="text-center">Status</th>
                                    <th class="text-center">Tanggal Pemesanan</th>
                                    <th class="text-center">Total Barang</th>
                                    <th class="text-center">Tgl Diterima</th>
                                    <th class="text-center">Detail</th>
                                </tr>
                            </thead>
                            <tbody id="orderTableBody">
                                @foreach ($orders as $order)
                                    <tr>
                                        <td class="text-center">{{ $order->id }}</td>
                                        <td class="text-center">{{ $order->name }}</td>
                                        <td class="text-center">{{ $order->phone }}</td>
                                        <td class="text-center">Rp {{ number_format($order->total, 0, ',', '.') }}</td>
                                        <td class="text-center">
                                            {{-- 👇👇👇 LOGIKA STATUS YANG DIPERBARUI 👇👇👇 --}}
                                            @if ($order->status == 'delivered')
                                                <span class="badge bg-success">Terkirim (Diterima)</span>
                                            @elseif($order->status == 'shipping')
                                                <span class="badge bg-info">Dikirim</span>
                                            @elseif ($order->status == 'canceled')
                                                <span class="badge bg-danger">Ditolak</span>
                                            @else
                                                <span class="badge bg-warning">Dipesan</span>
                                            @endif
                                            {{-- 👆👆👆 AKHIR DARI PERUBAHAN 👆👆👆 --}}
                                        </td>
                                        <td class="text-center">
                                            {{ \Carbon\Carbon::parse($order->created_at)->format('d F Y') }}</td>
                                        <td class="text-center">{{ $order->orderItems->count() }}</td>
                                        <td class="text-center">
                                            {{ $order->delivered_date ? \Carbon\Carbon::parse($order->delivered_date)->format('d F Y') : '-' }}
                                        </td>
                                        <td class="text-center">
                                            <a href="{{ route('admin.order.details', ['order_id' => $order->id]) }}">
                                                <div class="list-icon-function view-icon">
                                                    <div class="item eye">
                                                        <i class="icon-eye"></i>
                                                    </div>
                                                </div>
                                            </a>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="divider"></div>
                <div class="flex items-center justify-between flex-wrap gap10 wgp-pagination">
                    {{ $orders->links('pagination::bootstrap-5') }}
                </div>
            </div>
        </div>
    </div>
@endsection

@push('scripts')
    {{-- (Script live search Anda tidak perlu diubah dan akan tetap berfungsi) --}}
    <script>
        $(document).ready(function() {
            // Mencegah form pencarian melakukan submit dan refresh halaman
            $('#searchForm').on('submit', function(e) {
                e.preventDefault();
            });

            // SCRIPT UNTUK LIVE SEARCH
            $('#searchInput').on('keyup', function() {
                var query = $(this).val();
                var orderTableBody = $('#orderTableBody');

                if (query.length > 0) {
                    $('.wgp-pagination').hide();
                } else {
                    $('.wgp-pagination').show();
                }

                $.ajax({
                    url: "{{ route('admin.order.search') }}",
                    type: "GET",
                    data: {
                        'query': query
                    },
                    success: function(data) {
                        orderTableBody.empty();

                        if (data.length > 0) {
                            $.each(data, function(index, order) {
                                var detailUrl =
                                    "{{ route('admin.order.details', ['order_id' => ':id']) }}"
                                    .replace(':id', order.id);

                                // Logic untuk status badge
                                var statusBadge = '';
                                if (order.status == 'delivered') {
                                    statusBadge = '<span class="badge bg-success">Selesai (Diterima)</span>';
                                } else if (order.status == 'shipping') {
                                    statusBadge = '<span class="badge bg-info">Dikirim</span>';
                                } else if (order.status == 'canceled') {
                                    statusBadge = '<span class="badge bg-danger">Ditolak</span>';
                                } else {
                                    statusBadge = '<span class="badge bg-warning">Dipesan</span>';
                                }

                                // Formatting tanggal
                                var orderDate = new Date(order.created_at)
                                    .toLocaleDateString('id-ID', {
                                        day: 'numeric',
                                        month: 'long',
                                        year: 'numeric'
                                    });
                                var deliveredDate = order.delivered_date ? new Date(
                                    order.delivered_date).toLocaleDateString(
                                    'id-ID', {
                                        day: 'numeric',
                                        month: 'long',
                                        year: 'numeric'
                                    }) : '-';

                                // Formatting mata uang
                                var total = 'Rp ' + new Intl.NumberFormat('id-ID')
                                    .format(order.total);
                                
                                var itemCount = order.order_items ? order.order_items.length : 0;

                                var row = `
                                    <tr>
                                        <td class="text-center">${order.id}</td>
                                        <td class="text-center">${order.name}</td>
                                        <td class="text-center">${order.phone}</td>
                                        <td class="text-center">${total}</td>
                                        <td class="text-center">${statusBadge}</td>
                                        <td class="text-center">${orderDate}</td>
                                        <td class="text-center">${itemCount}</td>
                                        <td class="text-center">${deliveredDate}</td>
                                        <td class="text-center">
                                            <a href="${detailUrl}">
                                                <div class="list-icon-function view-icon">
                                                    <div class="item eye"><i class="icon-eye"></i></div>
                                                </div>
                                            </a>
                                        </td>
                                    </tr>
                                `;
                                orderTableBody.append(row);
                            });
                        } else {
                            orderTableBody.append(
                                '<tr><td colspan="11" class="text-center">Pesanan tidak ditemukan.</td></tr>'
                            );
                        }
                    }
                });
            });
        });
    </script>
@endpush