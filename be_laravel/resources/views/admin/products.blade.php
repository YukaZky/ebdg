@extends('layouts.admin')
@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Semua Produk</h3>
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
                        <div class="text-tiny">Semua Produk</div>
                    </li>
                </ul>
            </div>

            <div class="wg-box">
                <div class="flex items-center justify-between gap10 flex-wrap">
                    <div class="wg-filter flex-grow">
                        {{-- Form Pencarian untuk Live Search --}}
                        <form class="form-search" id="searchForm">
                            <fieldset class="name">
                                <input type="text" id="searchInput" placeholder="Cari Nama, URL, atau Kode Barang..."
                                    class="" name="name" tabindex="2" value="">
                            </fieldset>
                            <div class="button-submit">
                                <button class="" type="submit"><i class="icon-search"></i></button>
                            </div>
                        </form>
                    </div>
                    <a class="tf-button style-1 w208" href="{{ route('admin.product.add') }}"><i
                            class="icon-plus"></i>Tambah Produk</a>
                </div>
                <div class="table-responsive">
                    @if (Session::has('status'))
                        <p class="alert alert-success">{{ Session::get('status') }}</p>
                    @endif
                    <table class="table table-striped table-bordered">
                        <thead>
                            <tr>
                                <th>Id</th>
                                <th>Nama</th>
                                <th>Harga</th>
                                <th>Harga Jual</th>
                                <th>Kode Barang</th>
                                <th>Kategori</th>
                                <th>Merek</th>
                                <th>Unggulan</th>
                                <th>Stok</th>
                                <th>Jumlah</th>
                                <th>Kadaluarsa</th>
                                <th>Opsi</th>
                            </tr>
                        </thead>
                        <tbody id="productTableBody">
                            @foreach ($products as $product)
                                <tr>
                                    <td>{{ $product->id }}</td>
                                    <td class="pname">
                                        <div class="image">
                                            <img src="{{ asset('uploads/products/thumbnails') }}/{{ $product->image }}"
                                                alt="{{ $product->name }}" class="image">
                                        </div>
                                        <div class="name">
                                            <a href="#" class="body-title-2">{{ $product->name }}</a>
                                            <div class="text-tiny mt-3">{{ $product->slug }}</div>
                                        </div>
                                    </td>
                                    <td>Rp {{ number_format($product->regular_price, 0, ',', '.') }}</td>
                                    <td>Rp {{ number_format($product->sale_price, 0, ',', '.') }}</td>
                                    <td>{{ $product->SKU }}</td>
                                    <td>{{ $product->category->name }}</td>
                                    <td>{{ $product->brand->name }}</td>
                                    <td>{{ $product->featured == 0 ? 'Tidak' : 'Ya' }}</td>
                                    <td>{{ $product->stock_status }}</td>
                                    <td>{{ $product->quantity }}</td>
                                    <td>{{ $product->exp_date ? \Carbon\Carbon::parse($product->exp_date)->format('d M Y') : 'N/A' }}</td>
                                    <td>
                                        <div class="list-icon-function">
                                            <a href="{{ route('admin.product.edit', ['id' => $product->id]) }}">
                                                <div class="item edit"><i class="icon-edit-3"></i></div>
                                            </a>
                                            <form action="{{ route('admin.product.delete', ['id' => $product->id]) }}"
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

                <div class="divider"></div>
                <div class="flex items-center justify-between flex-wrap gap10 wgp-pagination">
                    {{ $products->links('pagination::bootstrap-5') }}
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
                var productTableBody = $('#productTableBody');
                var thumbBaseUrl = "{{ asset('uploads/products/thumbnails') }}";

                if (query.length > 0) {
                    $('.wgp-pagination').hide();
                } else {
                    $('.wgp-pagination').show();
                }

                $.ajax({
                    url: "{{ route('admin.product.search') }}",
                    type: "GET",
                    data: {
                        'query': query
                    },
                    success: function(data) {
                        productTableBody.empty();

                        if (data.length > 0) {
                            $.each(data, function(index, product) {
                                var editUrl =
                                    "{{ route('admin.product.edit', ['id' => ':id']) }}"
                                    .replace(':id', product.id);
                                var deleteUrl =
                                    "{{ route('admin.product.delete', ['id' => ':id']) }}"
                                    .replace(':id', product.id);

                                var regularPrice = 'Rp ' + new Intl.NumberFormat(
                                    'id-ID').format(product.regular_price);
                                var salePrice = 'Rp ' + new Intl.NumberFormat('id-ID')
                                    .format(product.sale_price);
                                var featured = product.featured == 0 ? 'Tidak' : 'Ya';

                                // Memastikan category dan brand tidak null
                                var categoryName = product.category ? product.category
                                    .name : 'N/A';
                                var brandName = product.brand ? product.brand.name :
                                    'N/A';

                                var row = `
                                    <tr>
                                        <td>${product.id}</td>
                                        <td class="pname">
                                            <div class="image">
                                                <img src="${thumbBaseUrl}/${product.image}" alt="${product.name}" class="image">
                                            </div>
                                            <div class="name">
                                                <a href="#" class="body-title-2">${product.name}</a>
                                                <div class="text-tiny mt-3">${product.slug}</div>
                                            </div>
                                        </td>
                                        <td>${regularPrice}</td>
                                        <td>${salePrice}</td>
                                        <td>${product.SKU}</td>
                                        <td>${categoryName}</td>
                                        <td>${brandName}</td>
                                        <td>${featured}</td>
                                        <td>${product.stock_status}</td>
                                        <td>${product.quantity}</td>
                                        <td>${expDate}</td>
                                        <td>
                                            <div class="list-icon-function">
                                                <a href="#" target="_blank">
                                                    <div class="item eye"><i class="icon-eye"></i></div>
                                                </a>
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
                                productTableBody.append(row);
                            });
                        } else {
                            productTableBody.append(
                                '<tr><td colspan="11" class="text-center">Produk tidak ditemukan.</td></tr>'
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
