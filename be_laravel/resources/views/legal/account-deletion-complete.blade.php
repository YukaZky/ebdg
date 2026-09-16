@extends('layouts.legal')

@section('title', 'Akun Telah Dihapus')

@section('content')
<h1>Akun telah dihapus</h1>
<p>Akun GeoDesaConnect beserta data terkait telah dihapus. Anda tidak lagi dapat masuk menggunakan akun tersebut.</p>
<p><a href="{{ url('/') }}">Kembali ke beranda</a></p>
@endsection
