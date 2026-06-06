@extends('layouts.admin')
@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Kupon Diskon</h3>
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
                        <div class="text-tiny">Kupon Diskon</div>
                    </li>
                </ul>
            </div>

            <div class="wg-box">
                <div class="flex items-center justify-between gap10 flex-wrap">
                    <div class="wg-filter flex-grow">
                        {{-- Form Pencarian untuk Live Search --}}
                        <form class="form-search" id="searchForm">
                            <fieldset class="name">
                                <input type="text" id="searchInput" placeholder="Ketik untuk mencari kode kupon..."
                                    class="" name="name" tabindex="2" value="">
                            </fieldset>
                            <div class="button-submit">
                                <button class="" type="submit"><i class="icon-search"></i></button>
                            </div>
                        </form>
                    </div>
                    <a class="tf-button style-1 w208" href="{{ route('admin.coupon.add') }}"><i class="icon-plus"></i>
                        Tambah Kupon Diskon</a>
                </div>
                <div class="wg-table table-all-user">
                    <div class="table-responsive">
                        @if (Session::has('status'))
                            <p class="alert alert-success">{{ Session::get('status') }}</p>
                        @endif
                        <table class="table table-striped table-bordered">
                            <thead>
                                <tr>
                                    <th>Id</th>
                                    <th>Kode Kupon</th>
                                    <th>Tipe Kupon</th>
                                    <th>Nominal Kupon</th>
                                    <th>Jumlah Kupon</th>
                                    <th>Tgl Kadaluarsa</th>
                                    <th>Opsi</th>
                                </tr>
                            </thead>
                            <tbody id="couponTableBody">
                                @foreach ($coupons as $coupon)
                                    <tr>
                                        <td>{{ $coupon->id }}</td>
                                        <td>{{ $coupon->code }}</td>
                                        <td>{{ $coupon->type }}</td>
                                        {{-- Format nominal kupon --}}
                                        <td>
                                            @if ($coupon->type == 'fixed')
                                                Rp {{ number_format($coupon->value, 0, ',', '.') }}
                                            @else
                                                {{ $coupon->value }}%
                                            @endif
                                        </td>
                                        <td> {{ number_format($coupon->cart_value, 0, ',', '.') }}</td>
                                        <td>{{ \Carbon\Carbon::parse($coupon->expiry_date)->format('d F Y') }}</td>
                                        <td>
                                            <div class="list-icon-function">
                                                <a href="{{ route('admin.coupon.edit', ['id' => $coupon->id]) }}">
                                                    <div class="item edit">
                                                        <i class="icon-edit-3"></i>
                                                    </div>
                                                </a>
                                                <form action="{{ route('admin.coupon.delete', ['id' => $coupon->id]) }}"
                                                    method="POST">
                                                    @csrf
                                                    @method('DELETE')
                                                    <div class="item text-danger delete" style="cursor:pointer;">
                                                        <i class="icon-trash-2"></i>
                                                    </div>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="divider"></div>
                <div class="flex items-center justify-between flex-wrap gap10 wgp-pagination">
                    {{ $coupons->links('pagination::bootstrap-5') }}
                </div>
            </div>
        </div>
    </div>
@endsection

@push('scripts')
    <script>
        $(document).ready(function() {
            // Mencegah form pencarian melakukan submit dan refresh halaman
            $('#searchForm').on('submit', function(e) {
                e.preventDefault();
            });

            // SCRIPT UNTUK LIVE SEARCH
            $('#searchInput').on('keyup', function() {
                var query = $(this).val();
                var couponTableBody = $('#couponTableBody');

                if (query.length > 0) {
                    $('.wgp-pagination').hide();
                } else {
                    $('.wgp-pagination').show();
                }

                $.ajax({
                    url: "{{ route('admin.coupon.search') }}",
                    type: "GET",
                    data: {
                        'query': query
                    },
                    success: function(data) {
                        couponTableBody.empty();

                        if (data.length > 0) {
                            $.each(data, function(index, coupon) {
                                var editUrl =
                                    "{{ route('admin.coupon.edit', ['id' => ':id']) }}"
                                    .replace(':id', coupon.id);
                                var deleteUrl =
                                    "{{ route('admin.coupon.delete', ['id' => ':id']) }}"
                                    .replace(':id', coupon.id);

                                // Format tanggal
                                var expiryDate = new Date(coupon.expiry_date)
                                    .toLocaleDateString('id-ID', {
                                        day: 'numeric',
                                        month: 'long',
                                        year: 'numeric'
                                    });

                                // Format nominal dan nilai keranjang
                                var valueFormatted = coupon.type === 'fixed' ?
                                    'Rp ' + new Intl.NumberFormat('id-ID').format(coupon
                                        .value) :
                                    coupon.value + '%';
                                var cartValueFormatted = 'Rp ' + new Intl.NumberFormat(
                                    'id-ID').format(coupon.cart_value);

                                var row = `
                                    <tr>
                                        <td>${coupon.id}</td>
                                        <td>${coupon.code}</td>
                                        <td>${coupon.type}</td>
                                        <td>${valueFormatted}</td>
                                        <td>${cartValueFormatted}</td>
                                        <td>${expiryDate}</td>
                                        <td>
                                            <div class="list-icon-function">
                                                <a href="${editUrl}">
                                                    <div class="item edit"><i class="icon-edit-3"></i></div>
                                                </a>
                                                <form action="${deleteUrl}" method="POST">
                                                    @csrf
                                                    @method('DELETE')
                                                    <div class="item text-danger delete" style="cursor:pointer;">
                                                        <i class="icon-trash-2"></i>
                                                    </div>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                `;
                                couponTableBody.append(row);
                            });
                        } else {
                            couponTableBody.append(
                                '<tr><td colspan="7" class="text-center">Kupon tidak ditemukan.</td></tr>'
                                );
                        }
                    }
                });
            });

            // SCRIPT UNTUK KONFIRMASI HAPUS (DELETE)
            $(document).on('click', '.delete', function(e) {
                e.preventDefault();
                var form = $(this).closest('form');
                swal({
                        title: "Apakah Anda Yakin?",
                        text: "Anda Yakin Menghapus Baris Ini?",
                        type: "warning",
                        buttons: ["Tidak", "Ya"],
                        dangerMode: true
                    })
                    .then(function(result) {
                        if (result) {
                            form.submit();
                        }
                    });
            });
        });
    </script>
@endpush
