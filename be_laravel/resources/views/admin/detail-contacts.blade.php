@extends('layouts.admin')

@section('content')
<div class="main-content-inner">
    <div class="main-content-wrap">
        <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
            <h3>Detail Pesan</h3>
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
                    <a href="{{ route('admin.contacts') }}">
                        <div class="text-tiny">Semua Pesan</div>
                    </a>
                </li>
                <li>
                    <i class="icon-chevron-right"></i>
                </li>
                <li>
                    <div class="text-tiny">Detail Pesan</div>
                </li>
            </ul>
        </div>

        <div class="wg-box">
            <div class="flex items-center justify-between gap10 flex-wrap mb-20">
                <h5 class="f-w-700">Pesan dari: {{ $contact->name }}</h5>
                <a class="tf-button style-1" href="{{ route('admin.contacts') }}"><i class="icon-arrow-left"></i>Kembali</a>
            </div>
            
            <table class="table table-striped table-bordered">
                <tbody>
                    <tr>
                        <th style="width: 200px;">ID Pesan</th>
                        <td>{{ $contact->id }}</td>
                    </tr>
                    <tr>
                        <th>Tanggal Kirim</th>
                        <td>{{ $contact->created_at->format('d F Y, H:i') }}</td>
                    </tr>
                    <tr>
                        <th>Nama Pengirim</th>
                        <td>{{ $contact->name }}</td>
                    </tr>
                    <tr>
                        <th>Alamat Email</th>
                        <td>
                            {{-- PERUBAHAN 1: Tambahkan ID dan ikon copy --}}
                            <a href="mailto:{{ $contact->email }}" id="email-address">{{ $contact->email }}</a>
                            <i id="copy-icon" class="icon-copy" style="cursor: pointer; margin-left: 8px; color: #3498db;" title="Salin Email"></i>
                        </td>
                    </tr>
                    <tr>
                        <th>Nomor Telepon</th>
                        <td>{{ $contact->phone }}</td>
                    </tr>
                    <tr>
                        <th>Isi Pesan</th>
                        <td style="white-space: pre-wrap;">{{ $contact->comment }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection

{{-- PERUBAHAN 2: Tambahkan blok script untuk fungsionalitas copy --}}
@push('scripts')
<script>
    document.addEventListener('DOMContentLoaded', function () {
        const copyIcon = document.getElementById('copy-icon');
        
        if (copyIcon) {
            copyIcon.addEventListener('click', function () {
                // Ambil elemen anchor yang berisi alamat email
                const emailLink = document.getElementById('email-address');
                const emailText = emailLink.textContent || emailLink.innerText;

                // Gunakan Clipboard API untuk menyalin teks
                navigator.clipboard.writeText(emailText).then(function() {
                    // Tampilkan notifikasi sukses menggunakan Toastify
                    Toastify({
                        text: "Alamat email berhasil disalin!",
                        duration: 3000,
                        close: true,
                        gravity: "top",
                        position: "right",
                        stopOnFocus: true,
                        style: {
                            background: "linear-gradient(to right, #00b09b, #96c93d)",
                        }
                    }).showToast();
                }, function(err) {
                    // Tampilkan pesan error jika gagal (misalnya karena permission)
                    console.error('Gagal menyalin teks: ', err);
                    Toastify({
                        text: "Gagal menyalin email.",
                        duration: 3000,
                        close: true,
                        gravity: "top",
                        position: "right",
                        stopOnFocus: true,
                        style: {
                            background: "linear-gradient(to right, #e74c3c, #c0392b)",
                        }
                    }).showToast();
                });
            });
        }
    });
</script>
@endpush