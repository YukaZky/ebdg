@extends('layouts.admin')
@section('content')
    <div class="main-content-inner">

        <div class="main-content-wrap">
            <div class="tf-section-2 mb-30">
                <div class="row">
                    {{-- WIDGET KOLOM KIRI --}}
                    <div class="col-md-6">
                        <div class="wg-chart-default mb-20">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap14">
                                    <div class="image ic-bg"><i class="icon-shopping-bag"></i></div>
                                    <div>
                                        <div class="body-text mb-2">Total Pesanan</div>
                                        <h4>{{ $dashboardDatas[0]->Total }}</h4>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="wg-chart-default mb-20">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap14">
                                    <div class="image ic-bg"><i class="icon-dollar-sign"></i></div>
                                    <div>
                                        <div class="body-text mb-2">Total Pendapatan (Selesai)</div>
                                        <h4>Rp {{ number_format($dashboardDatas[0]->TotalDeliveredAmount, 0, ',', '.') }}</h4>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="wg-chart-default">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap14">
                                    <div class="image ic-bg"><i class="icon-alert-octagon"></i></div>
                                    <div>
                                        <div class="body-text mb-2">Pesanan Ditolak</div>
                                        <h4>{{ $dashboardDatas[0]->TotalCanceled }}</h4>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    {{-- WIDGET KOLOM KANAN --}}
                    <div class="col-md-6">
                        <div class="wg-chart-default mb-20">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap14">
                                    <div class="image ic-bg"><i class="icon-clock"></i></div>
                                    <div>
                                        <div class="body-text mb-2">Pesanan Dipesan</div>
                                        <h4>{{ $dashboardDatas[0]->TotalOrdered }}</h4>
                                    </div>
                                </div>
                            </div>
                        </div>
                        {{-- 👇👇👇 WIDGET BARU DITAMBAHKAN 👇👇👇 --}}
                        <div class="wg-chart-default mb-20">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap14">
                                    <div class="image ic-bg"><i class="icon-truck"></i></div>
                                    <div>
                                        <div class="body-text mb-2">Pesanan Dikirim</div>
                                        <h4>{{ $dashboardDatas[0]->TotalShipping }}</h4>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="wg-chart-default">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap14">
                                    <div class="image ic-bg"><i class="icon-check-circle"></i></div>
                                    <div>
                                        <div class="body-text mb-2">Pesanan Selesai (Diterima)</div>
                                        <h4>{{ $dashboardDatas[0]->TotalDelivered }}</h4>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="wg-box mt-30">
                    <div class="flex items-center justify-between">
                        <h5>Pendapatan Bulanan</h5>
                    </div>
                    <div class="flex flex-wrap gap40">
                         <div>
                            <div class="mb-2"><div class="block-legend"><div class="dot t1"></div><div class="text-tiny">Total</div></div></div>
                            <div class="flex items-center gap10"><h4>Rp.{{ number_format($TotalAmount, 0, ',', '.') }}</h4></div>
                        </div>
                        <div>
                            <div class="mb-2"><div class="block-legend"><div class="dot t4"></div><div class="text-tiny">Dipesan</div></div></div>
                            <div class="flex items-center gap10"><h4>Rp.{{ number_format($TotalOrderedAmount, 0, ',', '.') }}</h4></div>
                        </div>
                        {{-- 👇👇👇 LEGENDA BARU DITAMBAHKAN 👇👇👇 --}}
                        <div>
                            <div class="mb-2"><div class="block-legend"><div class="dot" style="background-color: #0dcaf0;"></div><div class="text-tiny">Dikirim</div></div></div>
                            <div class="flex items-center gap10"><h4>Rp.{{ number_format($TotalShippingAmount, 0, ',', '.') }}</h4></div>
                        </div>
                        <div>
                            <div class="mb-2"><div class="block-legend"><div class="dot t2"></div><div class="text-tiny">Selesai</div></div></div>
                            <div class="flex items-center gap10"><h4>Rp.{{ number_format($TotalDeliveredAmount, 0, ',', '.') }}</h4></div>
                        </div>
                        <div>
                            <div class="mb-2"><div class="block-legend"><div class="dot t3"></div><div class="text-tiny">Ditolak</div></div></div>
                            <div class="flex items-center gap10"><h4>Rp.{{ number_format($TotalCanceledAmount, 0, ',', '.') }}</h4></div>
                        </div>
                    </div>
                    <div id="line-chart-8"></div>
                </div>

            </div>
            <div class="tf-section mb-30">

                <div class="wg-box">
                    <div class="flex items-center justify-between">
                        <h5>Daftar Pesanan Terbaru</h5>
                        <div class="dropdown default">
                            <a class="btn btn-secondary dropdown-toggle" href="{{ route('admin.orders') }}">
                                <span class="view-all">Lihat Semua</span>
                            </a>
                        </div>
                    </div>
                    <div class="wg-table table-all-user">
                        <div class="table-responsive">
                            <table class="table table-striped table-bordered">
                                <thead>
                                    <tr>
                                        <th style="width:70px">No Pesanan</th>
                                        <th class="text-center">Nama</th>
                                        <th class="text-center">Total</th>
                                        <th class="text-center">Status</th>
                                        <th class="text-center">Tanggal Pesanan</th>
                                        <th class="text-center">Total Item</th>
                                        <th class="text-center">Detail</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach ($orders as $order)
                                        <tr>
                                            <td class="text-center">{{ $order->id }}</td>
                                            <td class="text-center">{{ $order->name }}</td>
                                            <td class="text-center">Rp.{{ number_format($order->total, 0, ',', '.') }}</td>
                                            <td class="text-center">
                                                {{-- 👇👇👇 LOGIKA STATUS DISAMAKAN 👇👇👇 --}}
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
                                            <td class="text-center">{{ \Carbon\Carbon::parse($order->created_at)->format('d M Y') }}</td>
                                            <td class="text-center">{{ $order->orderItems->count() }}</td>
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
                </div>

            </div>
        </div>

    </div>
@endsection

@push('scripts')
    <script>
        (function($) {

            var tfLineChart = (function() {

                var chartBar = function() {

                    var options = {
                        series: [
                            { name: 'Total', data: [{{ $AmountM }}] }, 
                            { name: 'Dipesan', data: [{{ $OrderedAmountM }}] },
                            // 👇👇👇 DATA BARU UNTUK GRAFIK 👇👇👇
                            { name: 'Dikirim', data: [{{ $ShippingAmountM }}] }, 
                            { name: 'Selesai', data: [{{ $DeliveredAmountM }}] }, 
                            { name: 'Ditolak', data: [{{ $CanceledAmountM }}] }
                        ],
                        chart: { type: 'bar', height: 325, toolbar: { show: false, }, },
                        plotOptions: { bar: { horizontal: false, columnWidth: '10px', endingShape: 'rounded' }, },
                        dataLabels: { enabled: false },
                        legend: { show: false, },
                        // 👇👇👇 WARNA BARU UNTUK GRAFIK 👇👇👇
                        colors: ['#2377FC', '#ffc107', '#0dcaf0', '#198754', '#dc3545'],
                        stroke: { show: false, },
                        xaxis: {
                            labels: { style: { colors: '#212529', }, },
                            categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                        },
                        yaxis: { show: false, },
                        fill: { opacity: 1 },
                        tooltip: {
                            y: {
                                formatter: function(val) {
                                    return "Rp " + new Intl.NumberFormat('id-ID').format(val);
                                }
                            }
                        }
                    };

                    chart = new ApexCharts(
                        document.querySelector("#line-chart-8"),
                        options
                    );
                    if ($("#line-chart-8").length > 0) {
                        chart.render();
                    }
                };

                return {
                    load: function() {
                        chartBar();
                    },
                };
            })();

            jQuery(window).on("load", function() {
                tfLineChart.load();
            });

        })(jQuery);
    </script>
@endpush