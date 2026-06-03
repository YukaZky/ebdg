@extends('layouts.admin')

@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Pengguna Terdaftar</h3>
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
                        <div class="text-tiny">Pengguna</div>
                    </li>
                </ul>
            </div>

            <div class="wg-box">
                {{-- Bagian Filter dan Tombol Tambah --}}
                <div class="flex items-center justify-between gap10 flex-wrap">
                    <div class="wg-filter flex-grow">
                        {{-- Form Pencarian untuk Live Search --}}
                        <form class="form-search" id="searchForm">
                            <fieldset class="name">
                                <input type="text" id="searchInput" placeholder="Ketik untuk mencari pengguna..." class="" name="name"
                                    tabindex="2" value="">
                            </fieldset>
                            <div class="button-submit">
                                <button class="" type="submit"><i class="icon-search"></i></button>
                            </div>
                        </form>
                    </div>
                    <a class="tf-button style-1 w208" href="{{ route('admin.user.add') }}"><i class="icon-plus"></i>Tambah Pengguna</a>
                </div>
                
                {{-- Tabel Pengguna --}}
                <div class="wg-table table-all-user">
                    @if (Session::has('status'))
                        <p class="alert alert-success">{{ Session::get('status') }}</p>
                    @endif
                    <div class="table-responsive">
                        <table class="table table-striped table-bordered">
                            <thead>
                                <tr>
                                    <th>Id</th>
                                    <th>Nama</th>
                                    <th>Email</th>
                                    <th>Tanggal Bergabung</th>
                                    <th>Aksi</th>
                                </tr>
                            </thead>
                            <tbody id="userTableBody">
                                @forelse ($users as $user)
                                    <tr>
                                        <td>{{ $user->id }}</td>
                                        {{-- Kolom Nama dengan styling dari brands.blade.php --}}
                                        <td class="pname">
                                            <div class="image">
                                                {{-- Placeholder untuk avatar pengguna --}}
                                            </div>
                                            <div class="name">
                                                <a href="{{ route('admin.user.details', ['user_id' => $user->id]) }}" class="body-title-2">{{ $user->name }}</a>
                                            </div>
                                        </td>
                                        <td>{{ $user->email }}</td>
                                        <td>{{ $user->created_at->format('d F Y') }}</td>
                                        {{-- Kolom Aksi dengan styling dari brands.blade.php --}}
                                        <td>
                                            <div class="list-icon-function">
                                                <a href="{{ route('admin.user.details', ['user_id' => $user->id]) }}">
                                                    <div class="item text-info"> {{-- Menggunakan class asli untuk view --}}
                                                        <i class="icon-eye"></i>
                                                    </div>
                                                </a>
                                                <form action="{{ route('admin.user.destroy', ['id' => $user->id]) }}" method="POST">
                                                    @csrf
                                                    @method('DELETE')
                                                    <div class="item text-danger delete" style="cursor:pointer;">
                                                        <i class="icon-trash-2"></i>
                                                    </div>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="5" class="text-center">Tidak ada data pengguna.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                    <div class="divider"></div>
                    <div class="flex items-center justify-between flex-wrap gap10 wgp-pagination">
                        {{ $users->links('pagination::bootstrap-5') }}
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
                var userTableBody = $('#userTableBody');

                if (query.length > 0) {
                    $('.wgp-pagination').hide();
                } else {
                    $('.wgp-pagination').show();
                }

                $.ajax({
                    url: "{{ route('admin.user.search') }}",
                    type: "GET",
                    data: { 'query': query },
                    success: function(data) {
                        userTableBody.empty(); 

                        if (data.length > 0) {
                            $.each(data, function(index, user) {
                                var detailUrl = "{{ route('admin.user.details', ['user_id' => ':id']) }}".replace(':id', user.id);
                                var deleteUrl = "{{ route('admin.user.destroy', ['id' => ':id']) }}".replace(':id', user.id);
                                var joinDate = new Date(user.created_at).toLocaleDateString('id-ID', {
                                    day: 'numeric', month: 'long', year: 'numeric'
                                });

                                var row = `
                                    <tr>
                                        <td>${user.id}</td>
                                        <td class="pname">
                                            <div class="image"></div>
                                            <div class="name">
                                                <a href="${detailUrl}" class="body-title-2">${user.name}</a>
                                            </div>
                                        </td>
                                        <td>${user.email}</td>
                                        <td>${joinDate}</td>
                                        <td>
                                            <div class="list-icon-function">
                                                <a href="${detailUrl}">
                                                    <div class="item text-info"><i class="icon-eye"></i></div>
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
                                userTableBody.append(row);
                            });
                        } else {
                            userTableBody.append('<tr><td colspan="5" class="text-center">Pengguna tidak ditemukan.</td></tr>');
                        }
                    }
                });
            });

            // SCRIPT UNTUK KONFIRMASI HAPUS (DELETE)
            $(document).on('click', '.delete', function(e) {
                e.preventDefault();
                var form = $(this).closest('form');
                // Menggunakan teks dari brands.blade.php
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