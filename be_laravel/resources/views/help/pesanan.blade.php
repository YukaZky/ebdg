@extends('layouts.app')

@section('content')
<style>
    /* Custom CSS for FAQ page */
    .faq-container {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    }

    .back-link {
        display: inline-block;
        margin-bottom: 2rem;
        color: #555;
        text-decoration: none;
        font-size: 0.9rem;
    }

    .back-link:hover {
        color: #000;
    }

    .page-title {
        font-size: 2.5rem;
        font-weight: bold;
        margin-bottom: 2rem;
    }

    .faq-list {
        list-style: none;
        padding: 0;
    }

    .faq-item {
        border-bottom: 1px solid #f0f0f0;
        padding: 1.25rem 0;
    }

    .faq-item:last-child {
        border-bottom: none;
    }

    .faq-item summary {
        display: flex;
        justify-content: space-between;
        align-items: center;
        cursor: pointer;
        list-style: none;
        color: #333;
        transition: background-color 0.2s ease-in-out;
        margin: -1.25rem 0;
        padding: 1.25rem 0;
        font-weight: normal;
    }

    .faq-item summary::-webkit-details-marker {
        display: none;
    }

    .faq-item summary:hover {
        background-color: #f9f9f9;
        color: #000;
    }

    .faq-item[open]>summary {
        font-weight: bold;
    }

    .faq-item .arrow {
        color: #ccc;
        font-weight: bold;
        transition: transform 0.2s ease-in-out;
    }

    .faq-item[open]>summary .arrow {
        transform: rotate(-180deg);
    }

    .faq-item[open] summary .arrow svg {
        stroke: currentColor;
        stroke-width: 1px;
    }

    .faq-answer {
        padding: 1.5rem 0.5rem 0.5rem;
        color: #555;
        line-height: 1.6;
    }
</style>

<main>
    <div class="container py-5 mt-5 faq-container">

        <a href="{{ route('home.contact') }}" class="back-link">
            &lt; Kembali ke pusat bantuan
        </a>

        <h1 class="page-title">Pesanan</h1>

        <div class="faq-list">

            <details class="faq-item">
                <summary>
                    <span>Apa saja tahapan status pesanan saya?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    Status pesanan Anda akan melalui beberapa tahap:<br>
                    <b>Ordered:</b> Pesanan berhasil dibuat dan menunggu konfirmasi.<br>
                    <b>Delivered:</b> Pesanan telah berhasil dikirim dan diterima.<br>
                    <b>Canceled:</b> Pesanan dibatalkan.
                </div>
            </details>

            <details class="faq-item">
                <summary>
                    <span>Bagaimana cara saya melihat detail dari pesanan saya?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Masuk ke akun Anda, buka menu "Pesanan", lalu klik pada nomor pesanan yang ingin Anda lihat. Anda akan melihat rincian produk, alamat pengiriman, dan total pembayaran.</p>
                </div>
            </details>

            <details class="faq-item">
                <summary>
                    <span>Apakah saya bisa membatalkan pesanan yang sudah dibuat?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Berdasarkan sistem kami, pembatalan pesanan dilakukan oleh administrator. Jika Anda ingin membatalkan pesanan, mohon segera hubungi layanan pelanggan kami melalui halaman "Kontak" dengan menyertakan nomor pesanan Anda.</p>
                </div>
            </details>

        </div>
    </div>
</main>
@endsection