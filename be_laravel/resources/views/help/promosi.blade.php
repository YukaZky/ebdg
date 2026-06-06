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

        <h1 class="page-title">Promosi</h1>

        <div class="faq-list">

            <details class="faq-item">
                <summary>
                    <span>Bagaimana cara menggunakan kode kupon/voucher?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Anda dapat memasukkan kode kupon pada kolom yang tersedia di halaman Keranjang Belanja (Cart). Total harga akan otomatis terpotong sesuai dengan nilai kupon jika syaratnya terpenuhi.</p>
                </div>
            </details>

            <details class="faq-item">
                <summary>
                    <span>Mengapa kode kupon saya tidak berfungsi?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Pastikan beberapa hal berikut:</p>
                    <ul>
                        <li>Kode kupon yang Anda masukkan sudah benar.</li>
                        <li>Kupon masih dalam masa berlaku.</li>
                        <li>Total pembelian Anda telah memenuhi syarat minimum yang ditentukan untuk kupon tersebut.</li>
                    </ul>
                </div>
            </details>

            <details class="faq-item">
                <summary>
                    <span>Di mana saya bisa melihat informasi promosi terbaru?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Semua promosi aktif biasanya kami tampilkan di banner utama (slide) pada halaman beranda. Pastikan juga untuk mengikuti media sosial kami untuk info promo menarik lainnya.</p>
                </div>
            </details>

        </div>
    </div>
</main>
@endsection