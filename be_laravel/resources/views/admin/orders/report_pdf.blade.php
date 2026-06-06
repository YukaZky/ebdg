<!DOCTYPE html>
<html>
<head>
    <title>Laporan Penjualan</title>
    <style>
        body { font-family: 'Helvetica', sans-serif; color: #333; font-size: 12px; }
        .page-break { page-break-after: always; }
        .container { padding: 0 1rem; }
        h1, h2 { text-align: center; }
        h1 { font-size: 20px; margin-bottom: 0; }
        h2 { font-size: 16px; font-weight: normal; margin-top: 5px; margin-bottom: 30px; }
        
        /* Gaya Tabel */
        table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
        th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
        thead th { background-color: #f2f2f2; font-weight: bold; text-align: center; }
        
        /* Ringkasan */
        .summary-table td { border: none; padding: 5px 0; }
        .summary-table .label { font-weight: bold; }
        .summary-table .value { text-align: right; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Laporan Penjualan</h1>
        <h2>Per Tanggal: {{ date('d F Y') }}</h2>

        <h3>Ringkasan Umum</h3>
        <table class="summary-table">
            <tr>
                <td class="label">Total Pendapatan (Terkirim)</td>
                <td class="value">Rp {{ number_format($dashboardDatas[0]->TotalDeliveredAmount ?? 0, 0, ',', '.') }}</td>
            </tr>
            <tr>
                <td class="label">Total Semua Pesanan</td>
                <td class="value">{{ $dashboardDatas[0]->Total ?? 0 }}</td>
            </tr>
            <tr>
                <td class="label">Total Pesanan Terkirim</td>
                <td class="value">{{ $dashboardDatas[0]->TotalDelivered ?? 0 }}</td>
            </tr>
        </table>

        <h3>Pendapatan Bulanan (Tahun {{ date('Y') }})</h3>
        <table>
            <thead>
                <tr>
                    <th>Bulan</th>
                    <th style="text-align: right;">Total Pendapatan</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($monthlyDatas as $data)
                    <tr>
                        <td>{{ $data->month_name }}</td>
                        <td style="text-align: right;">Rp {{ number_format($data->monthly_revenue, 0, ',', '.') }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="2" style="text-align: center;">Belum ada pendapatan tahun ini.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>

        <div class="page-break"></div>

        <h3>Laporan Produk Terlaris</h3>
        <table>
            <thead>
                <tr>
                    <th>No.</th>
                    <th>SKU</th>
                    <th>Nama Produk</th>
                    <th>Kadaluarsa</th>
                    <th>Jumlah Terjual</th>
                </tr>
            </thead>
            <tbody>
                @forelse($bestSellingProducts as $product)
                    <tr>
                        <td style="text-align: center;">{{ $loop->iteration }}</td>
                        <td>{{ $product->SKU }}</td>
                        <td>{{ $product->name }}</td>
                        <td style="text-align: center;">{{ $product->exp_date ? \Carbon\Carbon::parse($product->exp_date)->format('d M Y') : 'N/A' }}</td>
                        <td style="text-align: center;">{{ $product->total_quantity_sold }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" style="text-align: center;">Tidak ada data penjualan yang ditemukan.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</body>
</html>