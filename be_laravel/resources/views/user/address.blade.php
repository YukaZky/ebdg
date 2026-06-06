@extends('layouts.app')
@section('content')
    <main >
        <section class="my-account container">
            <h2 class="page-title">Alamat</h2>
            <div class="row">
                <div class="col-lg-3">
                    @include('user.account-nav')
                </div>
                <div class="col-lg-9">
                    <div class="page-content my-account__address">
                        @if (Session::has('success'))
                            <p class="alert alert-success">{{ Session::get('success') }}</p>
                        @endif
                        <div class="row">
                            <div class="col-6">
                                <p class="notice">Alamat berikut akan digunakan pada halaman checkout secara default.</p>
                            </div>
                            <div class="col-6 text-right">
                                <a href="{{ route('user.address.add') }}" class="btn btn-sm btn-info">Tambah Baru</a>
                            </div>
                        </div>
                        <div class="my-account__address-list row">
                            <h5>Alamat Pengiriman</h5>
                            @foreach ($addresses as $address)
                                <div class="my-account__address-item col-md-6">
                                    <div class="my-account__address-item__title">
                                        <h5>{{ $address->name }}
                                            @if ($address->isdefault == '1')
                                                <i class="fa fa-check-circle"></i>
                                            @endif
                                        </h5>
                                        {{-- <div class="flex justify-between">
                                            <a href="{{ route('user.address.edit', ['id' => $address->id]) }}"
                                                style="margin-right: 10px">EDIT</a>
                                            <a href="{{ route('user.address.delete', ['id' => $address->id]) }}"
                                                class="delete">Delete</a>
                                            <form action="{{ route('user.address.delete', ['id' => $address->id]) }}"
                                                method="POST">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" class="btn btn-link text-danger p-0 delete"
                                                    style="text-decoration: underline; background: none; border: none;">DELETE</button>
                                            </form>
                                        </div> --}}
                                        <div class="d-flex align-items-center">
                                            {{-- <a href="{{ route('user.address.edit', ['id' => $address->id]) }}"
                                                class="btn btn-link fw-semi-bold p-0 me-3 mt-1"
                                                style="text-decoration: underline; background: none; border: none;">
                                                UBAH
                                            </a> --}}
                                            <form action="{{ route('user.address.edit', ['id' => $address->id]) }}" method="GET"
                                                class="btn btn-link p-0 me-3">
                                                <button type="submit" class="btn btn-link p-0 fw-semi-bold"
                                                    style="text-decoration: underline; background: none; border: none;">
                                                    UBAH
                                                </button>
                                            </form>
                                            <form action="{{ route('user.address.delete', ['id' => $address->id]) }}"
                                                method="POST" class="m-0 p-0">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" class="btn btn-link text-red fw-semi-bold p-0 delete"
                                                    style="text-decoration: underline; background: none; border: none;">
                                                    HAPUS
                                                </button>
                                            </form>
                                        </div>

                                    </div>
                                    <div class="my-account__address-item__detail">
                                        <h6>{{ $address->type }}</h6>
                                        <p>{{ $address->address }}</p>
                                        <p>{{ $address->landmark }},{{ $address->locality }}</p>
                                        <p>{{ $address->state }},{{ $address->city }},{{ $address->country }}</p>
                                        <p>{{ $address->zip }}</p>
                                        <p>WhatsApp : {{ $address->phone }}</p>
                                    </div>
                                </div>
                                <hr>
                            @endforeach
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </main>
@endsection

@push('scripts')
    <script>
        $(function() {
            $('.delete').on('click', function(e) {
                e.preventDefault();
                var form = $(this).closest('form');
                swal({
                        title: "Hapus Alamat?",
                        text: "Yakin Ingin Menghapus Alamat ini?",
                        type: "warning",
                        buttons: ["Tidak", "Iya"],
                        dangermode: true
                    })
                    .then(function(result) {
                        if (result) {
                            form.submit();
                        }
                    })
            })
        })
    </script>
@endpush
