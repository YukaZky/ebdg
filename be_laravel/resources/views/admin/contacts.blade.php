@extends('layouts.admin')

@section('content')
    <div class="main-content-inner">
        <div class="main-content-wrap">
            <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
                <h3>Semua Pesan</h3>
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
                        <div class="text-tiny">Semua Pesan</div>
                    </li>
                </ul>
            </div>

            <div class="wg-box">
                <div class="flex items-center justify-between gap10 flex-wrap">
                    <div class="wg-filter flex-grow">
                        {{-- Form Pencarian untuk Live Search --}}
                        <form class="form-search" id="searchForm">
                            <fieldset class="name">
                                <input type="text" id="searchInput" placeholder="Ketik untuk mencari pesan..." class="" name="name"
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
                        @if (Session::has('status'))
                            <p class="alert alert-success">{{ Session::get('status') }}</p>
                        @endif
                        <table class="table table-striped table-bordered">
                            <thead>
                                <tr>
                                    <th>Id</th>
                                    <th>Nama</th>
                                    <th>Email</th>
                                    <th>Nomor Telepon</th>
                                    <th>Pesan</th>
                                    <th>Tanggal</th>
                                    <th>Opsi</th>
                                </tr>
                            </thead>
                            <tbody id="contactTableBody">
                                @foreach ($contacts as $contact)
                                    <tr>
                                        <td>{{ $contact->id }}</td>
                                        <td>{{ $contact->name }}</td>
                                        <td>{{ $contact->email }}</td>
                                        <td>{{ $contact->phone }}</td>
                                        <td>{{ Str::limit($contact->comment, 50) }}</td>
                                        <td>{{ $contact->created_at->format('d F Y H:i') }}</td>
                                        <td>
                                            <div class="list-icon-function">
                                                {{-- PERUBAHAN 1: Tambah Ikon Mata di sini --}}
                                                <a href="{{ route('admin.contact.details', ['id' => $contact->id]) }}">
                                                    <div class="item text-info"><i class="icon-eye"></i></div>
                                                </a>
                                                <form action="{{ route('admin.contact.delete', ['id' => $contact->id]) }}" method="POST">
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
                    {{ $contacts->links('pagination::bootstrap-5') }}
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
                var contactTableBody = $('#contactTableBody');

                if (query.length > 0) {
                    $('.wgp-pagination').hide();
                } else {
                    $('.wgp-pagination').show();
                }

                $.ajax({
                    url: "{{ route('admin.contact.search') }}",
                    type: "GET",
                    data: { 'query': query },
                    success: function(data) {
                        contactTableBody.empty();

                        if (data.length > 0) {
                            $.each(data, function(index, contact) {
                                var deleteUrl = "{{ route('admin.contact.delete', ['id' => ':id']) }}".replace(':id', contact.id);
                                
                                // --- PERUBAHAN 2: Tambah URL Detail di sini ---
                                var detailsUrl = "{{ route('admin.contact.details', ['id' => ':id']) }}".replace(':id', contact.id);
                                
                                // Format tanggal agar lebih mudah dibaca
                                var sentDate = new Date(contact.created_at).toLocaleString('id-ID', {
                                    day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit'
                                });
                                
                                // Fungsi untuk membatasi panjang teks
                                const comment = contact.comment.length > 50 ? contact.comment.substring(0, 50) + '...' : contact.comment;

                                var row = `
                                    <tr>
                                        <td>${contact.id}</td>
                                        <td>${contact.name}</td>
                                        <td>${contact.email}</td>
                                        <td>${contact.phone}</td>
                                        <td>${comment}</td>
                                        <td>${sentDate}</td>
                                        <td>
                                            <div class="list-icon-function">
                                                {{-- PERUBAHAN 3: Tambah Ikon Mata di sini --}}
                                                <a href="${detailsUrl}">
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
                                contactTableBody.append(row);
                            });
                        } else {
                            contactTableBody.append('<tr><td colspan="7" class="text-center">Pesan tidak ditemukan.</td></tr>');
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