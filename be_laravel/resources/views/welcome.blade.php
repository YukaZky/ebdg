@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">{{ __('Selamat Datang') }}</div>

                <div class="card-body text-center">
                    <h5 class="card-title mb-4">Harap login atau sign in untuk melanjutkan</h5>
                    
                    {{-- Tombol Login --}}
                    <a href="{{ route('login') }}" class="btn btn-primary mx-2">
                        Login
                    </a>

                    {{-- Tombol Register/Sign In, ditampilkan jika rute registrasi tersedia --}}
                    @if (Route::has('register'))
                        <a href="{{ route('register') }}" class="btn btn-secondary mx-2">
                            Sign In
                        </a>
                    @endif
                </div>
            </div>
        </div>
    </div>
</div>
@endsection