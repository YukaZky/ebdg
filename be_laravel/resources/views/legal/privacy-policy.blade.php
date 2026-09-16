@extends('layouts.legal')

@section('title', 'Kebijakan Privasi')

@section('content')
<h1>Kebijakan Privasi</h1>
<p class="meta">Berlaku sejak 16 September 2026</p>

<p>{{ config('privacy.entity_name') }} mengelola aplikasi dan layanan GeoDesaConnect. Kebijakan ini menjelaskan data yang diproses ketika Anda menggunakan marketplace GeoDesaConnect.</p>

<h2>Data yang Kami Proses</h2>
<ul>
    <li>Identitas dan kontak, seperti nama, alamat email, nomor telepon, serta foto profil.</li>
    <li>Alamat dan lokasi yang Anda pilih untuk pengiriman, lokasi toko, atau pencarian lokasi.</li>
    <li>Informasi toko, produk, gambar, ulasan, kupon, dan percakapan marketplace yang Anda buat.</li>
    <li>Informasi pesanan, pembayaran, bukti pembayaran, pengiriman, dan riwayat transaksi.</li>
    <li>Data teknis yang diperlukan untuk keamanan dan operasi layanan, seperti alamat IP, waktu akses, serta informasi permintaan jaringan.</li>
</ul>

<h2>Tujuan Pemrosesan</h2>
<p>Data digunakan untuk membuat dan mengamankan akun, menjalankan transaksi marketplace, menghitung pengiriman, menampilkan lokasi toko, memproses pembayaran, menghubungkan pembeli dengan penjual, menangani dukungan, serta mencegah penyalahgunaan.</p>

<h2>Perizinan Perangkat</h2>
<p>Aplikasi dapat meminta akses lokasi ketika Anda memilih lokasi saat ini dan akses galeri ketika Anda mengunggah foto. Akses tersebut hanya digunakan setelah Anda menjalankan fitur terkait dan dapat dicabut melalui pengaturan perangkat.</p>

<h2>Pembagian Data</h2>
<p>Data transaksi dapat diberikan secara terbatas kepada pihak yang diperlukan untuk menyelesaikan layanan, seperti penjual atau pembeli terkait, penyedia pembayaran, penyedia pengiriman, dan penyedia infrastruktur. Kami tidak menjual data pribadi untuk periklanan.</p>

<h2>Penyimpanan dan Keamanan</h2>
<p>Kami menggunakan koneksi HTTPS, autentikasi, pembatasan akses, dan pengamanan server yang wajar. Data disimpan selama akun aktif atau selama diperlukan untuk menjalankan layanan. Informasi tertentu dapat dipertahankan apabila diwajibkan oleh hukum, penyelesaian sengketa, keamanan, atau pencegahan penipuan.</p>

<h2>Penghapusan Akun</h2>
<p>Anda dapat menghapus akun melalui menu Pengaturan Akun di aplikasi atau melalui halaman <a href="{{ route('account.deletion') }}">Penghapusan Akun</a>. Penghapusan akan menghapus profil dan data yang terkait dengan akun, kecuali informasi yang wajib dipertahankan berdasarkan alasan hukum yang sah. Data yang telah diteruskan kepada penyedia pihak ketiga tunduk pada kebijakan retensi penyedia tersebut.</p>

<h2>Hak dan Kontak</h2>
<p>Anda dapat memperbarui informasi akun melalui aplikasi. Pertanyaan mengenai privasi dapat dikirim ke <a href="mailto:{{ config('privacy.contact_email') }}">{{ config('privacy.contact_email') }}</a>.</p>

<h2>Perubahan Kebijakan</h2>
<p>Kebijakan ini dapat diperbarui untuk mencerminkan perubahan layanan atau ketentuan hukum. Tanggal berlaku terbaru akan ditampilkan pada halaman ini.</p>
@endsection
