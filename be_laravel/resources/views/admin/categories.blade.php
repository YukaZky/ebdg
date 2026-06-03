@extends('layouts.admin')
@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Kategori</h3>
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
                        <div class="text-tiny">Kategori</div>
                    </li>
                </ul>
            </div>

            <div class="wg-box">
                <div class="flex items-center justify-between gap10 flex-wrap">
                    <div class="wg-filter flex-grow">
                       {{-- Form Pencarian untuk Live Search --}}
                       <form class="form-search" id="searchForm">
                            <fieldset class="name">
                                <input type="text" id="searchInput" placeholder="Ketik untuk mencari kategori..." class="" name="name"
                                    tabindex="2" value="">
                            </fieldset>
                            <div class="button-submit">
                                <button class="" type="submit"><i class="icon-search"></i></button>
                            </div>
                        </form>
                    </div>
                    <a class="tf-button style-1 w208" href="{{ route('admin.category.add') }}"><i class="icon-plus"></i> Tambah Kategori</a>
                </div>
                <div class="wg-table table-all-user">
                    @if (Session::has('status'))
                        <p class="alert alert-success">{{ Session::get('status') }}</p>
                    @endif
                    <div class="table-responsive">
                        <table class="table table-striped table-bordered">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Nama</th>
                                    <th>URL Kategori</th>
                                    <th>Total Merek</th>
                                    <th>Opsi</th>
                                </tr>
                            </thead>
                            {{-- ID ditambahkan di sini untuk target JavaScript --}}
                            <tbody id="categoryTableBody">
                                @foreach ($categories as $category)
                                    <tr>
                                        <td>{{ $category->id }}</td>
                                        <td class="pname">
                                            <div class="image">
                                                <img src="{{ asset('/uploads/categories') }}/{{ $category->image }}"
                                                    alt="{{ $category->name }}" class="image">
                                            </div>
                                            <div class="name">
                                                <a href="#" class="body-title-2">{{ $category->name }}</a>
                                            </div>
                                        </td>
                                        <td>{{ $category->slug }}</td>
                                        <td>{{ $category->brands->count() }}</td>
                                        <td>
                                            <div class="list-icon-function">
                                                <a href="{{ route('admin.category.edit', ['id' => $category->id]) }}">
                                                    <div class="item edit">
                                                        <i class="icon-edit-3"></i>
                                                    </div>
                                                </a>
                                                <form
                                                    action="{{ route('admin.category.delete', ['id' => $category->id]) }}"
                                                    method="POST">
                                                    @csrf
                                                    @method('DELETE')
                                                    {{-- Class 'delete' digunakan oleh javascript untuk konfirmasi --}}
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
                        {{ $categories->links('pagination::bootstrap-5') }}
                    </div>
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
                var categoryTableBody = $('#categoryTableBody');
                var assetBaseUrl = "{{ asset('/uploads/categories') }}";

                if (query.length > 0) {
                    $('.wgp-pagination').hide();
                } else {
                    $('.wgp-pagination').show();
                }

                $.ajax({
                    url: "{{ route('admin.category.search') }}",
                    type: "GET",
                    data: { 'query': query },
                    success: function(data) {
                        categoryTableBody.empty();

                        if (data.length > 0) {
                            $.each(data, function(index, category) {
                                var editUrl = "{{ route('admin.category.edit', ['id' => ':id']) }}".replace(':id', category.id);
                                var deleteUrl = "{{ route('admin.category.delete', ['id' => ':id']) }}".replace(':id', category.id);
                                
                                // Jika Anda belum mengatur withCount('brands') di controller,
                                // 'brands_count' mungkin tidak ada. Ganti dengan '0' atau sesuaikan.
                                var brandCount = category.brands_count !== undefined ? category.brands_count : 0;

                                var row = `
                                    <tr>
                                        <td>${category.id}</td>
                                        <td class="pname">
                                            <div class="image">
                                                <img src="${assetBaseUrl}/${category.image}" alt="${category.name}" class="image">
                                            </div>
                                            <div class="name">
                                                <a href="#" class="body-title-2">${category.name}</a>
                                            </div>
                                        </td>
                                        <td>${category.slug}</td>
                                        <td>${brandCount}</td>
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
                                categoryTableBody.append(row);
                            });
                        } else {
                            categoryTableBody.append('<tr><td colspan="5" class="text-center">Kategori tidak ditemukan.</td></tr>');
                        }
                    }
                });
            });

            // SCRIPT UNTUK KONFIRMASI HAPUS (DELETE)
            // Menggunakan event delegation agar berfungsi pada baris yang dibuat oleh AJAX
            $(document).on('click', '.delete', function(e) {
                e.preventDefault();
                var form = $(this).closest('form');
                swal({
                        title: "Apakah Anda Yakin?",
                        text: "Anda yakin ingin menghapus data ini?",
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