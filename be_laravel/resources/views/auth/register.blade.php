@extends('layouts.app')

@push('scripts')
    <script src="https://www.google.com/recaptcha/api.js" async defer></script>
@endpush

@push('styles')
    <style>
        /* Mengatur body dan html untuk mengisi seluruh layar */
        html,
        body {
            height: 100%;
            margin: 0;
            font-family: 'Poppins', sans-serif;
            background-color: #f0f2f5;
            /* Warna latar belakang yang lembut */
        }

        /* Kontainer utama untuk layout split-screen */
        .register-wrapper {
            display: flex;
            min-height: 90vh;
            /* Mengisi tinggi viewport, disesuaikan agar tidak terlalu ke bawah */
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        /* Card utama yang menampung kedua sisi */
        .register-card {
            display: flex;
            flex-direction: row;
            width: 100%;
            max-width: 950px;
            background-color: #ffffff;
            border-radius: 15px;
            box-shadow: 0 15px 40px rgba(0, 0, 0, 0.1);
            overflow: hidden;
            /* Penting agar border-radius berfungsi */
        }

        /* Sisi kanan untuk branding/gambar */
        .register-branding {
            flex-basis: 50%;
            /* === PERUBAHAN DI SINI === */
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
        .register-branding::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.4);
            /* PERUBAHAN: Disesuaikan untuk kolom kanan */
            border-radius: 0 15px 15px 0;
        }

        .branding-content {
            position: relative;
            /* Agar di atas overlay */
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
        .register-form-container {
            flex-basis: 50%;
            padding: 40px;
            /* Sedikit disesuaikan agar pas */
            display: flex;
            flex-direction: column;
            justify-content: center;
        }

        .register-form-container h3 {
            font-weight: 700;
            font-size: 1.8rem;
            margin-bottom: 10px;
            color: #333;
        }

        .register-form-container .text-muted {
            margin-bottom: 25px;
            /* Sedikit disesuaikan */
            font-size: 0.9rem;
        }

        /* Styling untuk input form */
        .form-control {
            border-radius: 8px;
            border: 1px solid #ddd;
            padding: 10px 15px;
            /* Disesuaikan tingginya */
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
            /* Margin bawah untuk label */
        }

        /* Tombol utama */
        .btn-register {
            width: 100%;
            padding: 12px;
            font-size: 1rem;
            font-weight: 600;
            border-radius: 8px;
            background-color: #007bff;
            border-color: #007bff;
            transition: all 0.3s ease;
        }

        .btn-register:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
        }

        /* Tautan "Sudah Punya Akun?" */
        .extra-links {
            text-align: center;
            margin-top: 20px;
            font-size: 0.9rem;
        }

        .google-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            background-color: #ffffff;
            color: #444;
            border: 1px solid #ccc;
            padding: 10px 16px;
            border-radius: 4px;
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
            transition: background 0.3s;
            margin-top: 20px;
        }

        .google-btn:hover {
            background-color: #f1f1f1;
        }

        .google-icon {
            width: 20px;
            height: 20px;
        }

        /* Desain responsif untuk layar kecil */
        @media (max-width: 768px) {
            .register-card {
                flex-direction: column;
            }

            .register-branding {
                display: none;
                /* Sembunyikan gambar di layar kecil agar fokus ke form */
            }

            .register-form-container {
                flex-basis: 100%;
            }
        }
    </style>
@endpush

@section('content')
    <div class="register-wrapper">
        <div class="register-card">
            {{-- === BAGIAN FORM DI KIRI === --}}
            <div class="register-form-container">
                <h3>Buat Akun Baru</h3>
                <p class="text-muted">Hanya butuh beberapa detik untuk memulai.</p>

                <form method="POST" action="{{ route('register') }}">
                    @csrf

                    <div class="mb-3">
                        <label for="name" class="form-label">{{ __('Nama Lengkap') }}</label>
                        <input id="name" type="text" class="form-control @error('name') is-invalid @enderror"
                            name="name" value="{{ old('name') }}" required autocomplete="name" autofocus>
                        @error('name')
                            <span class="invalid-feedback" role="alert">
                                <strong>{{ $message }}</strong>
                            </span>
                        @enderror
                    </div>

                    <div class="mb-3">
                        <label for="email" class="form-label">{{ __('Alamat Email') }}</label>
                        <input id="email" type="email" class="form-control @error('email') is-invalid @enderror"
                            name="email" value="{{ old('email') }}" required autocomplete="email">
                        @error('email')
                            <span class="invalid-feedback" role="alert">
                                <strong>{{ $message }}</strong>
                            </span>
                        @enderror
                    </div>

                    <div class="mb-3">
                        <label for="password" class="form-label">{{ __('Password') }}</label>
                        <input id="password" type="password" class="form-control @error('password') is-invalid @enderror"
                            name="password" required autocomplete="new-password">
                        @error('password')
                            <span class="invalid-feedback" role="alert">
                                <strong>{{ $message }}</strong>
                            </span>
                        @enderror
                    </div>

                    <div class="mb-3">
                        <label for="password-confirm" class="form-label">{{ __('Konfirmasi Password') }}</label>
                        <input id="password-confirm" type="password" class="form-control" name="password_confirmation"
                            required autocomplete="new-password">
                    </div>

                    <div class="form-group mb-3">
                        <div class="g-recaptcha" data-sitekey="{{ env('RECAPTCHA_SITE_KEY') }}"></div>
                        @if ($errors->has('g-recaptcha-response'))
                            <span class="text-danger">{{ $errors->first('g-recaptcha-response') }}</span>
                        @endif
                    </div>

                    <div class="d-grid mt-4">
                        <button type="submit" class="btn btn-primary btn-register">
                            {{ __('Daftar Sekarang') }}
                        </button>
                    </div>

                    <div class="extra-links">
                        <span>
                            Sudah punya akun?
                            <a href="{{ route('login') }}" class="fw-bold">Masuk di sini</a>
                        </span>
                    </div>
                    <div class="text-center">
                        <a href="{{ route('google.login') }}" class="google-btn">
                            <img src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" alt="Google Logo"
                                class="google-icon">
                            <span>Daftar Menggunakan Google</span>
                        </a>
                    </div>
                </form>
            </div>

            {{-- === BAGIAN BRANDING DI KANAN === --}}
            <div class="register-branding">
                <div class="branding-content">
                    <h2>Selamat Datang!</h2>
                    <p>Satu langkah lagi untuk menjadi bagian dari komunitas dan nikmati semua fiturnya.</p>
                </div>
            </div>
        </div>
    </div>
@endsection
