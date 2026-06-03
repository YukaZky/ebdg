@extends('layouts.app')
@section('content')
    <style>
        .text-danger {
            color: #e72010 !important;
        }
        .search-banner {
            padding-top: 0px;
            text-align: center;
            color: #333;
        }
        .search-banner h2 {
            font-size: 2.5rem;
            margin-bottom: 20px;
        }
        .search-box {
            max-width: 600px;
            margin: auto;
            position: relative;
        }
        .search-box input {
            width: 100%;
            padding: 15px 20px;
            border-radius: 8px;
            border: 1px solid #ccc;
            font-size: 1rem;
        }
        .search-box button {
            position: absolute;
            right: 5px;
            top: 5px;
            bottom: 5px;
            border: none;
            background-color: #f0f0f0;
            color: #333;
            width: 50px;
            border-radius: 8px;
            font-size: 1.2rem;
        }
        .help-section {
            padding: 60px 0;
        }
        .section-title {
            font-size: 1.8rem;
            font-weight: bold;
            text-align: center;
            margin-bottom: 40px;
        }
        .category-grid {
            display: flex;
            flex-wrap: wrap;
            justify-content: flex-start;
            gap: 20px;
        }
        .category-item {
            text-align: center;
            width: 120px;
            text-decoration: none;
            color: #000;
        }
        .category-item:hover .category-icon {
            transform: scale(1.1);
        }
        .category-icon {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            border: 2px solid #ccc;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 10px;
            font-size: 2.5rem;
            color: #000;
            transition: transform 0.2s;
        }
        .category-item p {
            font-weight: 500;
        }
        .help-container {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-top: 60px;
        }
        .help-column {
            flex: 1;
            min-width: 0;
        }
        .help-column:first-child {
            border-right: 1px solid #e0e0e0;
            padding-right: 40px;
        }
        .help-column:last-child {
            padding-left: 40px;
        }
        .help-column .section-title {
            text-align: left;
            font-size: 1.5rem;
        }
        .faq-list {
            max-width: 800px;
        }
        .faq-item {
            padding: 20px 0;
            border-bottom: 1px solid #eee;
        }
        .faq-question {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 1.1rem;
            color: #000;
            cursor: pointer;
        }
        .faq-question i {
            font-size: 1.2rem;
            transition: transform 0.3s ease;
        }
        .faq-answer {
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.3s ease-out, padding 0.3s ease;
            padding: 0 10px;
            color: #555;
            font-size: 1rem;
        }
        .faq-item.active .faq-question {
            font-weight: bold;
        }
        .faq-item.active .faq-question i {
            transform: rotate(180deg);
        }
        .faq-item.active .faq-answer {
            max-height: 200px;
            padding: 20px 10px 10px;
        }
        /* PERUBAHAN DIMULAI DI SINI */
        .contact-us {
            margin-top: 4rem; /* Menambah jarak dari elemen di atasnya */
            padding-top: 4rem; /* Menambah jarak antara garis dan judul "Hubungi Kami" */
            border-top: 1px solid #e0e0e0; /* Membuat garis horizontal sebagai pembatas */
        }
        /* PERUBAHAN SELESAI DI SINI */

        /* CSS untuk Tombol WhatsApp */
        .whatsapp-float {
            position: fixed;
            width: 60px;
            height: 60px;
            bottom: 40px;
            right: 40px;
            background-color: #fff;
            border-radius: 50px;
            text-align: center;
            box-shadow: 2px 2px 5px rgba(0,0,0,0.2);
            z-index: 1000;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: transform 0.3s ease-in-out;
        }

        .whatsapp-float:hover {
            transform: scale(1.1);
        }

        .whatsapp-icon {
            width: 35px;
            height: 35px;
        }

        /* Penyesuaian Tombol WhatsApp untuk Mobile */
        @media (max-width: 767px) {
            .whatsapp-float {
                width: 55px;
                height: 55px;
                bottom: 80px; /* Disesuaikan agar di atas footer mobile */
                right: 20px;
            }

            .whatsapp-icon {
                width: 30px;
                height: 30px;
            }
        }
    </style>
    
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">

    <main class="pt-5">
        <section class="search-banner">
            <div class="container">
                <h2>Hai, ada yang bisa kami bantu?</h2>
            </div>
        </section>

        <div class="container">
            <div class="help-container">
                <section class="help-column">
                    <h2 class="section-title">Kategori Bantuan</h2>
                    <div class="category-grid">
                        <a href="/help/akun" class="category-item">
                            <div class="category-icon"><i class="far fa-user"></i></div>
                            <p>Akun Saya</p>
                        </a>
                        <a href="/help/pesanan" class="category-item">
                            <div class="category-icon"><i class="fas fa-shopping-bag"></i></div>
                            <p>Pesanan</p>
                        </a>
                        <a href="/help/pembayaran" class="category-item">
                            <div class="category-icon"><i class="far fa-credit-card"></i></div>
                            <p>Pembayaran</p>
                        </a>
                        <a href="/help/pengiriman" class="category-item">
                            <div class="category-icon"><i class="fas fa-truck"></i></div>
                            <p>Pengiriman</p>
                        </a>
                        <a href="/help/pengembalian" class="category-item">
                            <div class="category-icon"><i class="fas fa-undo-alt"></i></div>
                            <p>Pengembalian</p>
                        </a>
                        <a href="/help/produk" class="category-item">
                            <div class="category-icon"><i class="fas fa-box-open"></i></div>
                            <p>Produk</p>
                        </a>
                        <a href="/help/promosi" class="category-item">
                            <div class="category-icon"><i class="fas fa-tags"></i></div>
                            <p>Promosi</p>
                        </a>
                    </div>
                </section>

                <section class="help-column">
                    <h2 class="section-title">Hal Yang Sering Ditanyakan</h2>
                    <div class="faq-list">
                        <div class="faq-item">
                            <div class="faq-question">
                                <span>Bagaimana cara melacak pesanan saya?</span>
                                <i class="fas fa-chevron-down"></i>
                            </div>
                            <div class="faq-answer">
                                <p>Anda dapat melihat status pesanan (apakah sudah dikirim atau belum) di menu "Pesanan Saya" pada dasbor akun Anda. Untuk detail pelacakan, silakan hubungi customer service kami.</p>
                            </div>
                        </div>
                        <div class="faq-item">
                            <div class="faq-question">
                                <span>Metode pembayaran apa saja yang diterima?</span>
                                <i class="fas fa-chevron-down"></i>
                            </div>
                            <div class="faq-answer">
                                <p>Kami menerima pembayaran melalui COD (Bayar di Tempat).</p>
                            </div>
                        </div>
                         <div class="faq-item">
                            <div class="faq-question">
                                <span>Apakah saya bisa membatalkan atau mengubah pesanan?</span>
                                <i class="fas fa-chevron-down"></i>
                            </div>
                            <div class="faq-answer">
                                <p>Untuk pembatalan atau perubahan pesanan, mohon segera hubungi layanan pelanggan kami, karena pengguna tidak dapat melakukannya langsung dari website.</p>
                            </div>
                        </div>
                        <div class="faq-item">
                            <div class="faq-question">
                                <span>Apa yang harus dilakukan jika saya lupa kata sandi?</span>
                                <i class="fas fa-chevron-down"></i>
                            </div>
                            <div class="faq-answer">
                                <p>Gunakan fitur "Lupa Kata Sandi" di halaman login. Anda hanya perlu memasukkan email terdaftar dan tautan untuk reset kata sandi akan dikirimkan ke email Anda.</p>
                            </div>
                        </div>
                        <div class="faq-item">
                            <div class="faq-question">
                                <span>Bagaimana jika produk yang saya terima rusak atau salah?</span>
                                <i class="fas fa-chevron-down"></i>
                            </div>
                            <div class="faq-answer">
                                <p>Segera hubungi kami melalui halaman "Kontak" maksimal 2x24 jam setelah barang diterima. Sertakan nomor pesanan dan bukti foto agar kami bisa segera memproses pengembalian atau penukaran.</p>
                            </div>
                        </div>
                    </div>
                </section>
            </div>

            <section class="contact-us container">
            <div class="mw-930">
                <div class="contact-us__form">
                    @if (Session::has('success'))
                        <div class="alert alert-success alert-dismissible fade show" role="alert">
                            {{ Session::get('success') }}
                        </div>
                    @endif
                    <form action="{{ route('home.contact.store') }}" method="POST" name="contact-us-form"
                        class="needs-validation" novalidate="">
                        @csrf
                        <h3 class="mb-5 text-center">Hubungi Kami</h3>
                        <div class="form-floating my-4">
                            <input type="text" class="form-control" name="name" placeholder="Name *"
                                value="{{ old('name') }}" required="">
                            <label for="contact_us_name">Name *</label>
                            @error('name')
                                <span class="text-danger">{{ $message }}</span>
                            @enderror
                        </div>
                        <div class="form-floating my-4">
                            <input type="text" class="form-control" name="phone" placeholder="Phone *"
                                value="{{ old('phone') }}" required="">
                            <label for="contact_us_name">Phone *</label>
                            @error('phone')
                                <span class="text-danger">{{ $message }}</span>
                            @enderror
                        </div>
                        <div class="form-floating my-4">
                            <input type="email" class="form-control" name="email" placeholder="Email address *"
                                value="{{ old('email') }}" required="">
                            <label for="contact_us_name">Email address *</label>
                            @error('email')
                                <span class="text-danger">{{ $message }}</span>
                            @enderror
                        </div>
                        <div class="my-4">
                            <textarea class="form-control form-control_gray" name="comment" placeholder="Your Message *" cols="30"
                                rows="8" required="">{{ old('comment') }}</textarea>
                            @error('comment')
                                <span class="text-danger">{{ $message }}</span>
                            @enderror
                        </div>
                        <div class="my-4">
                            <button type="submit" class="btn btn-primary">Submit</button>
                        </div>
                    </form>
                </div>
            </div>
        </section>
        </div>

        <script>
            const faqItems = document.querySelectorAll('.faq-item');
            faqItems.forEach(item => {
                const question = item.querySelector('.faq-question');
                question.addEventListener('click', () => {
                    const isActive = item.classList.contains('active');
                    faqItems.forEach(otherItem => {
                        otherItem.classList.remove('active');
                    });
                    if (!isActive) {
                        item.classList.add('active');
                    }
                });
            });
        </script>
        </main>

        <!-- Tombol WhatsApp Mengambang -->
        <a href="https://wa.me/{{ $whatsappNumber }}?text=Halo,%20saya%20tertarik%20dengan%20layanan%20Anda." class="whatsapp-float" target="_blank" rel="noopener noreferrer">
            <img src="{{ asset('images/whatsapp-icon.svg') }}" alt="Chat di WhatsApp" class="whatsapp-icon">
        </a>
@endsection
