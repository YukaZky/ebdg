@extends('layouts.app')
@section('content')
<main>
    <section class="my-account container">
        <h2 class="page-title">Detail Akun</h2>
        <div class="row">
            <div class="col-lg-3">
                @include('user.account-nav')
            </div>
            <div class="col-lg-9">
                <div class="page-content my-account__details">

                    {{-- Form untuk Update Detail Profil --}}
                    <div class="card mb-5">
                        <div class="card-header">
                            <h5>Ubah Detail Profil</h5>
                        </div>
                        <div class="card-body">
                            @if (session('profile_status'))
                            <div class="alert alert-success" role="alert">
                                {{ session('profile_status') }}
                            </div>
                            @endif
                            {{-- Ganti route('user.profile.update') dengan route yang sesuai di aplikasi Anda --}}
                            <form action="{{ route('user.profile.update') }}" method="POST">
                                @csrf
                                @method('PATCH')
                                <div class="row">
                                    <div class="col-md-12">
                                        <div class="form-floating my-3">
                                            <input type="text" class="form-control" name="name"
                                                value="{{ Auth::user()->name }}">
                                            <label for="name">Nama Lengkap *</label>
                                            @error('name')
                                            <span class="text-red">{{ $message }}</span>
                                            @enderror
                                        </div>
                                    </div>
                                    <div class="col-md-12">
                                        <div class="form-floating my-3">
                                            <input type="email" class="form-control" name="email"
                                                value="{{ Auth::user()->email }}" readonly>
                                            <label for="email">Alamat Email *</label>
                                            <small class="form-text text-muted">Email tidak dapat diubah.</small>
                                        </div>
                                    </div>
                                    <div class="col-md-12 text-right">
                                        <button type="submit" class="btn btn-success">Simpan Perubahan</button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>

                    {{-- Form untuk Update Password --}}
                    <div class="card">
                        <div class="card-header">
                            <h5>Ubah Kata Sandi</h5>
                        </div>
                        <div class="card-body">
                            @if (session('password_status'))
                            <div class="alert alert-success" role="alert">
                                {{ session('password_status') }}
                            </div>
                            @endif
                            {{-- Ganti route('user.password.update') dengan route yang sesuai di aplikasi Anda --}}
                            <form action="{{ route('user.password.update') }}" method="POST">
                                @csrf
                                @method('PUT')
                                <div class="row">
                                    <div class="col-md-12">
                                        <div class="form-floating my-3">
                                            <input type="password" class="form-control" name="current_password">
                                            <label>Kata Sandi Saat Ini *</label>
                                            @error('current_password')
                                            <span class="text-red">{{ $message }}</span>
                                            @enderror
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-floating my-3">
                                            <input type="password" class="form-control" name="new_password">
                                            <label>Kata Sandi Baru *</label>
                                            @error('new_password')
                                            <span class="text-red">{{ $message }}</span>
                                            @enderror
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-floating my-3">
                                            <input type="password" class="form-control" name="new_password_confirmation">
                                            <label>Konfirmasi Kata Sandi Baru *</label>
                                        </div>
                                    </div>
                                    <div class="col-md-12 text-right">
                                        <button type="submit" class="btn btn-success">Ubah Kata Sandi</button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>

                </div>
            </div>
        </div>
    </section>
</main>
@endsection