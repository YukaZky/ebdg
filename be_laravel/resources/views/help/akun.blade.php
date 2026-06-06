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

    .account-title {
        font-size: 2.5rem;
        font-weight: bold;
        margin-bottom: 2rem;
    }

    .faq-list {
        list-style: none;
        padding: 0;
    }

    /* Styling for the dropdown item */
    .faq-item {
        border-bottom: 1px solid #f0f0f0;
        padding: 1.25rem 0;
    }

    .faq-item:last-child {
        border-bottom: none;
    }

    /* The clickable summary part */
    .faq-item summary {
        display: flex;
        justify-content: space-between;
        align-items: center;
        cursor: pointer;
        list-style: none;
        /* Remove default marker */
        color: #333;
        transition: background-color 0.2s ease-in-out;
        margin: -1.25rem 0;
        /* Expand click area */
        padding: 1.25rem 0;
        /* Restore padding */
        font-weight: normal;
    }

    .faq-item summary::-webkit-details-marker {
        display: none;
        /* Hide default arrow in Chrome/Safari */
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

    /* Rotate arrow when dropdown is open */
    .faq-item[open]>summary .arrow {
        transform: rotate(-180deg);
    }

    .faq-item[open] summary .arrow svg {
    stroke: currentColor;
    stroke-width: 1px;
}

    /* The answer content */
    .faq-answer {
        padding: 1.5rem 0.5rem 0.5rem;
        color: #555;
        line-height: 1.6;
    }
</style>

<main>
    <div class="container py-5 mt-5 faq-container">

        {{-- Tombol Kembali --}}
        <a href="{{ route('home.contact') }}" class="back-link">
            &lt; Kembali ke pusat bantuan
        </a>

        {{-- Judul Halaman --}}
        <h1 class="account-title">Akun Saya</h1>

        {{-- Daftar Pertanyaan (Dropdown) --}}
        <div class="faq-list">

            <details class="faq-item">
                <summary>
                    <span>Bagaimana cara membuat akun baru?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Anda dapat membuat akun dengan mengklik tombol "Daftar" atau "Register". Anda akan diminta untuk mengisi nama, alamat email, dan kata sandi. Setelah itu, Anda bisa langsung masuk ke akun Anda.</p>
                </div>
            </details>

            <details class="faq-item">
                <summary>
                    <span>Apa yang harus saya lakukan jika lupa kata sandi?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Pada halaman login, klik tautan "Lupa Kata Sandi?" atau "Forgot Password?". Masukkan alamat email yang terdaftar, dan kami akan mengirimkan tautan untuk mengatur ulang kata sandi Anda melalui email.</p>
                </div>
            </details>

            <details class="faq-item">
                <summary>
                    <span>Bagaimana cara mengubah atau menambah alamat pengiriman?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Masuk ke akun Anda, lalu masuk ke menu "Alamat" atau "Address". Di sana Anda dapat menambah alamat baru atau mengubah alamat yang sudah ada untuk kemudahan proses checkout di kemudian hari.</p>
                </div>
            </details>

            <details class="faq-item">
                <summary>
                    <span>Di mana saya bisa melihat riwayat pesanan saya?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Seluruh riwayat transaksi Anda dapat dilihat di dasbor akun Anda pada bagian "Pesanan" atau "Orders".</p>
                </div>
            </details>

            <details class="faq-item">
                <summary>
                    <span>Bagaimana cara mengubah informasi profil saya?</span>
                    <span class="arrow">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                            <path fill-rule="evenodd" d="M1.646 4.646a.5.5 0 0 1 .708 0L8 10.293l5.646-5.647a.5.5 0 0 1 .708.708l-6 6a.5.5 0 0 1-.708 0l-6-6a.5.5 0 0 1 0-.708z" />
                        </svg>
                    </span>
                </summary>
                <div class="faq-answer">
                    <p>Masuk ke akun Anda dan pilih menu "Detail Akun" atau "Account Details". Di halaman tersebut Anda dapat memperbarui informasi nama dan email Anda.</p>
                </div>
            </details>

        </div>

    </div>
</main>
@endsection