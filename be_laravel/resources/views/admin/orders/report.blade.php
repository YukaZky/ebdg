@extends('layouts.admin')

@section('content')
<style>
    /* Styling Umum */
    .summary-card { background-color: #fff; border-radius: 8px; padding: 1.5rem; box-shadow: 0 4px 12px rgba(0,0,0,0.05); border: 1px solid #e9ecef; }
    .summary-card .icon { font-size: 2rem; color: #adb5bd; }
    .summary-card h5 { font-size: 1rem; color: #6c757d; text-transform: uppercase; margin-bottom: 0.5rem; }
    .summary-card .amount { font-size: 2rem; font-weight: 600; color: #212529; }
    .box-title { font-size: 1.75rem; font-weight: 600; }
    .box-subtitle { font-size: 1.1rem; color: #6c757d; }
    
    /* Styling Tabel */
    .report-table th { background-color: #f8f9fa; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; vertical-align: middle; text-align: center; }
    
    /* BARU: Aturan td juga dibuat text-align: center */
    .report-table td, .report-table th { padding: 1.1rem 0.85rem; font-size: 1.1rem; vertical-align: middle; text-align: center; }
    
    .report-table td { white-space: nowrap; }
    .report-table tbody tr:hover { filter: brightness(95%); }
    
    /* BARU: Kelas khusus untuk perataan kiri pada nama produk */
    .product-name-cell {
        text-align: left !important;
        white-space: normal; /* Izinkan nama produk yang panjang untuk turun baris */
    }

    /* Styling Tombol */
    .btn-download { padding: 0.75rem 1.5rem; font-size: 1rem; font-weight: 600; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); transition: all 0.2s ease-in-out; display: inline-flex; align-items: center; gap: 0.5rem; }
    .btn-download:hover { transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.15); }
    
    /* Aturan Responsif */
    @media (max-width: 767px) { .report-table { min-width: 900px; } }
</style>

<div class="main-content-inner">
    <div class="main-content-wrap">

        <div class="row mb-4">
            <div class="col-xl-4 col-md-6 mb-4">
                <div class="summary-card h-100">
                    <div class="d-flex align-items-center">
                        <div class="flex-grow-1">
                            <h5>Total Pendapatan (Terkirim)</h5>
                            <div class="amount">Rp {{ number_format($dashboardDatas[0]->TotalDeliveredAmount ?? 0, 0, ',', '.') }}</div>
                        </div>
                        <i class="icon-dollar-sign icon"></i>
                    </div>
                </div>
            </div>
            <div class="col-xl-4 col-md-6 mb-4">
                <div class="summary-card h-100">
                    <div class="d-flex align-items-center">
                        <div class="flex-grow-1">
                            <h5>Total Pesanan</h5>
                            <div class="amount">{{ $dashboardDatas[0]->Total ?? 0 }}</div>
                        </div>
                        <i class="icon-shopping-bag icon"></i>
                    </div>
                </div>
            </div>
            <div class="col-xl-4 col-md-12 mb-4">
                <div class="summary-card h-100">
                    <div class="d-flex align-items-center">
                        <div class="flex-grow-1">
                            <h5>Pesanan Terkirim</h5>
                            <div class="amount">{{ $dashboardDatas[0]->TotalDelivered ?? 0 }}</div>
                        </div>
                        <i class="icon-truck icon"></i>
                    </div>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-12">
                <div class="box">
                    <div class="box-header">
                        <h4 class="box-title">Laporan Pendapatan Bulanan (Tahun {{ date('Y') }})</h4>
                        <p class="box-subtitle">Hanya menghitung pendapatan dari pesanan yang sudah berstatus "Terkirim (Diterima)".</p>
                    </div>
                    <div class="box-body">
                        <div class="table-responsive">
                            <table class="table align-middle report-table">
                                <thead>
                                    <tr>
                                        <th>Bulan</th>
                                        <th>Total Pendapatan</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @forelse ($monthlyDatas as $data)
                                        <tr>
                                            <td>{{ $data->month_name }}</td>
                                            <td>Rp {{ number_format($data->monthly_revenue, 0, ',', '.') }}</td>
                                        </tr>
                                    @empty
                                        <tr>
                                            <td colspan="2" class="text-center py-4">Belum ada pendapatan tahun ini.</td>
                                        </tr>
                                    @endforelse
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row mt-4">
            <div class="col-12">
                <div class="box">
                    <div class="box-header pb-4 d-flex flex-column flex-md-row align-items-md-center justify-content-between">
                        <div class="flex-grow-1 mb-3 mb-md-0">
                            <h4 class="box-title">Laporan Produk Terlaris</h4>
                            <p class="box-subtitle">Menampilkan semua produk, diurutkan dari yang paling laris hingga yang belum terjual.</p>
                        </div>
                        <div class="box-tools d-flex gap-3">
                            <a href="{{ route('admin.orders.report.excel') }}" class="btn btn-success btn-download">
                                <i class="icon-file-text"></i>
                                <span>Unduh Laporan Produk (Excel)</span>
                            </a>
                            <a href="{{ route('admin.orders.report.pdf') }}" class="btn btn-danger btn-download">
                                <i class="icon-file-text"></i>
                                <span>Unduh Semua Laporan (PDF)</span>
                            </a>
                        </div>
                    </div>
                    <div class="box-body">
                        <div class="table-responsive">
                            <table class="table align-middle report-table">
                                <thead>
                                    <tr>
                                        <th>Peringkat</th>
                                        <th>SKU</th>
                                        <th>Nama Produk</th>
                                        <th>Kadaluarsa</th>
                                        <th>Jumlah Terjual</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @forelse ($bestSellingProducts as $product)
                                        <tr class="{{ $product->total_quantity_sold > 5 ? 'table-success' : ($product->total_quantity_sold > 0 ? 'table-warning' : '') }}">
                                            <td>{{ $loop->iteration + ($bestSellingProducts->currentPage() - 1) * $bestSellingProducts->perPage() }}</td>
                                            <td>{{ $product->SKU }}</td>
                                            {{-- BARU: Menambahkan kelas agar nama produk rata kiri --}}
                                            <td class="product-name-cell">{{ $product->name }}</td>
                                            <td>{{ $product->exp_date ? \Carbon\Carbon::parse($product->exp_date)->format('d M Y') : 'N/A' }}</td>
                                            <td>
                                                <span class="badge {{ $product->total_quantity_sold > 0 ? 'bg-success' : 'bg-secondary' }}" style="font-size: 0.95rem; padding: 0.5em 0.75em;">
                                                    {{ $product->total_quantity_sold }}
                                                </span>
                                            </td>
                                        </tr>
                                    @empty
                                        <tr><td colspan="5" class="text-center py-5"><p class="text-muted">Belum ada data penjualan produk.</p></td></tr>
                                    @endforelse
                                </tbody>
                            </table>
                        </div>
                        <div class="mt-4 d-flex justify-content-end">{{ $bestSellingProducts->links() }}</div>
                    </div>
                </div>
            </div>
        </div>
        
    </div>
</div>
@endsection