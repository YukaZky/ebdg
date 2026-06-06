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

        <h1 class="page-title">Produk</h1>

        <div class="faq-list">

            <details class="faq-item">
                <summary>
                    <span>Bagaimana cara mencari produk yang saya inginkan?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Anda bisa menggunakan fitur pencarian di bagian atas website. Selain itu, pada halaman "Shop", Anda dapat memfilter produk berdasarkan kategori, merek, dan rentang harga untuk mempermudah pencarian.</p>
                </div>
            </details>

            <details class="faq-item">
                <summary>
                    <span>Apa yang terjadi jika produk yang saya inginkan stoknya habis?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Produk yang habis akan ditandai "Out of Stock". Sayangnya, kami belum memiliki fitur notifikasi otomatis. Kami sarankan Anda untuk memeriksa kembali halaman produk secara berkala atau menghubungi kami untuk menanyakan estimasi ketersediaan produk.</p>
                </div>
            </details>

            <details class="faq-item">
                <summary>
                    <span>Apakah semua produk yang dijual original?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Ya, kami menjamin semua produk yang berasal dari berbagai merek (brand) yang terdaftar di situs kami adalah 100% original.</p>
                </div>
            </details>

        </div>
    </div>
</main>
@endsection