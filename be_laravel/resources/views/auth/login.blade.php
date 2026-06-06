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
        .login-wrapper {
            display: flex;
            min-height: 90vh;
            /* Mengisi tinggi viewport, disesuaikan agar tidak terlalu ke bawah */
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        /* Card utama yang menampung kedua sisi */
        .login-card {
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

        /* Sisi kiri untuk branding/gambar */
        .login-branding {
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
        .login-branding::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.4);
            border-radius: 15px 0 0 15px;
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

        /* Sisi kanan untuk formulir */
        .login-form-container {
            flex-basis: 50%;
            padding: 50px 40px;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }

        .login-form-container h3 {
            font-weight: 700;
            font-size: 1.8rem;
            margin-bottom: 10px;
            color: #333;
        }

        .login-form-container .text-muted {
            margin-bottom: 30px;
            font-size: 0.9rem;
        }

        /* Styling untuk input form */
        .form-control {
            border-radius: 8px;
            border: 1px solid #ddd;
            padding: 12px 15px;
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
        }

        /* Tombol utama */
        .btn-login {
            width: 100%;
            padding: 12px;
            font-size: 1rem;
            font-weight: 600;
            border-radius: 8px;
            background-color: #007bff;
            border-color: #007bff;
            transition: all 0.3s ease;
        }

        .btn-login:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
        }

        /* Tautan "Lupa Password" dan "Daftar" */
        .extra-links {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 15px;
            font-size: 0.85rem;
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
            .login-card {
                flex-direction: column;
            }

            .login-branding {
                display: none;
                /* Sembunyikan gambar di layar kecil agar fokus ke form */
            }

            .login-form-container {
                flex-basis: 100%;
            }
        }
    </style>
@endpush

@section('content')
    <div class="login-wrapper">
        <div class="login-card">
            <div class="login-branding">
                <div class="branding-content">
                    <h2>Bergabunglah dengan Kami</h2>
                    <p>Akses ribuan produk eksklusif dan dapatkan penawaran terbaik hanya untuk Anda.</p>
                </div>
            </div>

            <div class="login-form-container">
                <h3>Selamat Datang Kembali!</h3>
                <p class="text-muted">Silakan masukkan detail Anda untuk masuk.</p>

                <form method="POST" action="{{ route('login') }}">
                    @csrf

                    <div class="mb-3">
                        <label for="email" class="form-label">{{ __('Alamat Email') }}</label>
                        <input id="email" type="email" class="form-control @error('email') is-invalid @enderror"
                            name="email" value="{{ old('email') }}" required autocomplete="email" autofocus>
                        @error('email')
                            <span class="invalid-feedback" role="alert">
                                <strong>{{ $message }}</strong>
                            </span>
                        @enderror
                    </div>

                    <div class="mb-3">
                        <label for="password" class="form-label">{{ __('Password') }}</label>
                        <input id="password" type="password" class="form-control @error('password') is-invalid @enderror"
                            name="password" required autocomplete="current-password">
                        @error('password')
                            <span class="invalid-feedback" role="alert">
                                <strong>{{ $message }}</strong>
                            </span>
                        @enderror
                    </div>

                    <div class="mb-3 form-check">
                        <input class="form-check-input" type="checkbox" name="remember" id="remember"
                            {{ old('remember') ? 'checked' : '' }}>
                        <label class="form-check-label" for="remember">
                            {{ __('Ingat Saya') }}
                        </label>
                    </div>

                    <div class="form-group mb-3">
                        <div class="g-recaptcha" data-sitekey="{{ env('RECAPTCHA_SITE_KEY') }}"></div>
                        @if ($errors->has('g-recaptcha-response'))
                            <span class="text-danger">{{ $errors->first('g-recaptcha-response') }}</span>
                        @endif
                    </div>

                    <div class="d-grid mb-3">
                        <button type="submit" class="btn btn-primary btn-login">
                            {{ __('Masuk') }}
                        </button>
                    </div>

                    <div class="extra-links">
                        @if (Route::has('password.request'))
                            <a class="btn btn-link p-0" href="{{ route('password.request') }}">
                                {{ __('Lupa Password?') }}
                            </a>
                        @endif

                        @if (Route::has('register'))
                            <a href="{{ route('register') }}" class="fw-bold">Daftar Akun Baru</a>
                        @endif
                    </div>
                    <div class="text-center">
                        <a href="{{ route('google.login') }}" class="google-btn">
                            <img src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" alt="Google Logo"
                                class="google-icon">
                            <span>Masuk Menggunakan Google</span>
                        </a>
                    </div>

                </form>
            </div>
        </div>
    </div>
@endsection
