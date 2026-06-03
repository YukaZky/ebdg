@extends('layouts.admin')
@section('content')
    <div class="main-content-wrap">
        <div class="flex items-center flex-wrap justify-between gap20 mb-27 page-header">
            <h3>Edit Kupon Diskon</h3>
            <ul class="breadcrumbs flex items-center flex-wrap justify-start gap10">
                <li>
                    <a href="{{ route('admin.index') }}">
                        <div class="text-tiny">Menu Utama</div>
                    </a>
                </li>
                <li>
                    <i class="icon-chevron-right"></i>
                </li>
                <li>
                    <a href="{{ route('admin.coupons') }}">
                        <div class="text-tiny">Kupon Diskon</div>
                    </a>
                </li>
                <li>
                    <i class="icon-chevron-right"></i>
                </li>
                <li>
                    <div class="text-tiny">Edit Kupon</div>
                </li>
            </ul>
        </div>
        <div class="wg-box">
            <form class="form-new-product form-style-1" method="POST" action="{{ route('admin.coupon.update') }}">
                @csrf
                @method('PUT')
                <input type="hidden" name="id" value="{{ $coupon->id }}">
                <fieldset class="name">
                    <div class="body-title">kode kupon <span class="tf-color-1">*</span></div>
                    <input class="flex-grow" type="text" placeholder="kode kupon" name="code" tabindex="0"
                        value="{{ $coupon->code }}" aria-required="true" required="">
                </fieldset>
                @error('code')
                    <span class="alert alert-danger text-center">{{ $message }}</span>
                @enderror
                <fieldset class="category">
                    <div class="body-title">Tipe Diskon</div>
                    <div class="select flex-grow">
                        <select class="" name="type">
                            <option value="">Pilih</option>
                            <option value="fixed" {{ $coupon->type == 'fixed' ? 'selected' : '' }}>Potongan Harga Tetap</option>
                            <option value="percent" {{ $coupon->type == 'percent' ? 'selected' : '' }}>Potongan Harga Persen</option>
                        </select>
                    </div>
                </fieldset>
                @error('type')
                    <span class="alert alert-danger text-center">{{ $message }}</span>
                @enderror
                <fieldset class="name">
                    <div class="body-title">nominal <span class="tf-color-1">*</span></div>
                    <input class="flex-grow" type="text" placeholder="nominal Kupon" name="value" tabindex="0"
                        value="{{ $coupon->value }}" aria-required="true" required="">
                </fieldset>
                @error('value')
                    <span class="alert alert-danger text-center">{{ $message }}</span>
                @enderror
                <fieldset class="name">
                    <div class="body-title">Jumlah Kupon <span class="tf-color-1">*</span></div>
                    <input class="flex-grow" type="text" placeholder="Jumlah Kupon" name="cart_value" tabindex="0"
                        value="{{ $coupon->cart_value }}" aria-required="true" required="">
                </fieldset>
                @error('cart_value')
                    <span class="alert alert-danger text-center">{{ $message }}</span>
                @enderror
                <fieldset class="name">
                    <div class="body-title">tanggal kadaluarsa kupon <span class="tf-color-1">*</span></div>
                    <input class="flex-grow" type="date" placeholder="tanggal kadaluarsa kupon" name="expiry_date" tabindex="0"
                        value="{{ $coupon->expiry_date }}" aria-required="true" required="">
                </fieldset>
                @error('expiry_date')
                    <span class="alert alert-danger text-center">{{ $message }}</span>
                @enderror

                <div class="bot">
                    <div></div>
                    <button class="tf-button w208" type="submit">Simpan</button>
                </div>
            </form>
        </div>
    </div>
@endsection
