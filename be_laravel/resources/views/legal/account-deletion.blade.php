@extends('layouts.legal')

@section('title', 'Penghapusan Akun')

@section('content')
<h1>Penghapusan Akun GeoDesaConnect</h1>
<p>Masukkan kredensial akun untuk menghapus akun dan data terkait secara permanen. Anda juga dapat menjalankan proses yang sama melalui menu <strong>Pengaturan Akun</strong> di aplikasi.</p>

<p class="notice">Penghapusan tidak dapat dibatalkan. Profil, alamat, toko, produk, ulasan, percakapan, dan data akun akan dihapus. Informasi yang wajib dipertahankan karena hukum atau penyelesaian sengketa dapat disimpan secara terbatas sesuai Kebijakan Privasi.</p>

<form method="POST" action="{{ route('account.deletion.destroy') }}">
    @csrf
    @method('DELETE')

    <label for="email">Email akun</label>
    <input id="email" name="email" type="email" value="{{ old('email') }}" autocomplete="email" required>
    @error('email')<div class="error">{{ $message }}</div>@enderror

    <label for="password">Password</label>
    <input id="password" name="password" type="password" autocomplete="current-password" required>
    @error('password')<div class="error">{{ $message }}</div>@enderror

    <label class="check">
        <input name="confirmation" type="checkbox" value="1" required>
        <span>Saya memahami bahwa akun dan data terkait akan dihapus secara permanen.</span>
    </label>
    @error('confirmation')<div class="error">{{ $message }}</div>@enderror

    <button type="submit">Hapus Akun Permanen</button>
</form>
@endsection
