@extends('layouts.app')

{{-- Menambahkan custom styles yang diadaptasi dari register.blade.php --}}
@push('styles')
<style>
    /* Mengatur body dan html untuk mengisi seluruh layar */
    html, body {
        height: 100%;
        margin: 0;
        font-family: 'Poppins', sans-serif;
        background-color: #f0f2f5; /* Warna latar belakang yang lembut */
    }

    /* Kontainer utama untuk layout split-screen */
    .auth-wrapper {
        display: flex;
        min-height: 90vh; /* Mengisi tinggi viewport */
        align-items: center;
        justify-content: center;
        padding: 20px;
    }

    /* Card utama yang menampung kedua sisi */
    .auth-card {
        display: flex;
        flex-direction: row;
        width: 100%;
        max-width: 950px;
        background-color: #ffffff;
        border-radius: 15px;
        box-shadow: 0 15px 40px rgba(0, 0, 0, 0.1);
        overflow: hidden; /* Penting agar border-radius berfungsi */
    }

    /* Sisi kanan untuk branding/gambar */
    .auth-branding {
        flex-basis: 50%;
        background: url("{{ asset('images/loginbg.png') }}") no-repeat center center;
        background-size: cover;
        position: relative;
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        text-align: center;
        padding: 40px;
    }
    
    /* Overlay gelap di atas gambar agar teks lebih terbaca */
    .auth-branding::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.4);
        border-radius: 0 15px 15px 0; 
    }

    .branding-content {
        position: relative; /* Agar di atas overlay */
        z-index: 1;
    }

    .branding-content h2 {
        font-weight: 700;
        font-size: 2rem;
        margin-bottom: 10px;
        color: white;
    }

    .branding-content p {
        font-size: 1rem;
        opacity: 0.9;
    }

    /* Sisi kiri untuk formulir */
    .auth-form-container {
        flex-basis: 50%;
        padding: 40px;
        display: flex;
        flex-direction: column;
        justify-content: center;
    }

    .auth-form-container h3 {
        font-weight: 700;
        font-size: 1.8rem;
        margin-bottom: 10px;
        color: #333;
    }

    .auth-form-container .text-muted {
        margin-bottom: 25px;
        font-size: 0.9rem;
    }

    /* Styling untuk input form */
    .form-control {
        border-radius: 8px;
        border: 1px solid #ddd;
        padding: 10px 15px;
        height: auto;
        transition: all 0.3s ease;
    }

    .form-control:focus {
        border-color: #007bff;
        box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
    }

    .form-label {
        font-weight: 600;
        color: #555;
        margin-bottom: 5px;
    }

    /* Tombol utama */
    .btn-auth {
        width: 100%;
        padding: 12px;
        font-size: 1rem;
        font-weight: 600;
        border-radius: 8px;
        background-color: #007bff;
        border-color: #007bff;
        transition: all 0.3s ease;
    }

    .btn-auth:hover {
        background-color: #0056b3;
        transform: translateY(-2px);
    }

    /* Tautan tambahan */
    .extra-links {
        text-align: center;
        margin-top: 20px;
        font-size: 0.9rem;
    }

    /* Desain responsif untuk layar kecil */
    @media (max-width: 768px) {
        .auth-card {
            flex-direction: column;
        }
        .auth-branding {
            display: none; /* Sembunyikan gambar di layar kecil agar fokus ke form */
        }
        .auth-form-container {
            flex-basis: 100%;
        }
    }
</style>
@endpush

@section('content')
<div class="auth-wrapper">
    <div class="auth-card">
        {{-- === BAGIAN FORM DI KIRI === --}}
        <div class="auth-form-container">
            <h3>Reset Password</h3>
            <p class="text-muted">Masukkan email Anda untuk menerima tautan reset password.</p>

            @if (session('status'))
                <div class="alert alert-success" role="alert">
                    {{ session('status') }}
                </div>
            @endif

            <form method="POST" action="{{ route('password.email') }}">
                @csrf

                <div class="mb-3">
                    <label for="email" class="form-label">{{ __('Alamat Email') }}</label>
                    <input id="email" type="email" class="form-control @error('email') is-invalid @enderror" name="email" value="{{ old('email') }}" required autocomplete="email" autofocus>
                    
                    @error('email')
                        <span class="invalid-feedback" role="alert">
                            <strong>{{ $message }}</strong>
                        </span>
                    @enderror
                </div>
                
                <div class="d-grid mt-4">
                    <button type="submit" class="btn btn-primary btn-auth">
                        {{ __('Kirim Tautan Reset Password') }}
                    </button>
                </div>

                <div class="extra-links">
                    <span>
                        Ingat password Anda?
                        <a href="{{ route('login') }}" class="fw-bold">Kembali ke Login</a>
                    </span>
                </div>
            </form>
        </div>

        {{-- === BAGIAN BRANDING DI KANAN === --}}
        <div class="auth-branding">
            <div class="branding-content">
                <h2>Lupa Password?</h2>
                <p>Tidak masalah. Kami akan membantu Anda untuk kembali masuk ke akun Anda dengan mudah.</p>
            </div>
        </div>
    </div>
</div>
@endsection