@extends('layouts.app')

@section('content')
    <main class="pt-20">
        <section class="shop-checkout container">
            <h2 class="page-title">PESANAN DITERIMA</h2>
            <div class="checkout-steps">
                <a href="javascript:void(0)" class="checkout-steps__item active">
                    <span class="checkout-steps__item-number">01</span>
                    <span class="checkout-steps__item-title">
                        <span>Tas Belanja</span>
                        <em>Kelola Daftar Item Anda</em>
                    </span>
                </a>
                <a href="javascript:void(0)" class="checkout-steps__item active">
                    <span class="checkout-steps__item-number">02</span>
                    <span class="checkout-steps__item-title">
                        <span>Pengiriman dan Checkout</span>
                        <em>Checkout Pesanan Anda</em>
                    </span>
                </a>
                <a href="javascript:void(0)" class="checkout-steps__item active">
                    <span class="checkout-steps__item-number">03</span>
                    <span class="checkout-steps__item-title">
                        <span>Konfirmasi</span>
                        <em>Lihat dan Konfirmasi Pesanan</em>
                    </span>
                </a>
            </div>

            @if (isset($order))
                <div class="order-complete">
                    <div class="order-complete__message">
                        <svg width="80" height="80" viewBox="0 0 80 80" fill="none"
                            xmlns="http://www.w3.org/2000/svg">
                            <circle cx="40" cy="40" r="40" fill="#B9A16B" />
                            <path
                                d="M52.9743 35.7612C52.9743 35.3426 52.8069 34.9241 52.5056 34.6228L50.2288 32.346C49.9275 32.0446 49.5089 31.8772 49.0904 31.8772C48.6719 31.8772 48.2533 32.0446 47.952 32.346L36.9699 43.3449L32.048 38.4062C31.7467 38.1049 31.3281 37.9375 30.9096 37.9375C30.4911 37.9375 30.0725 38.1049 29.7712 38.4062L27.4944 40.683C27.1931 40.9844 27.0257 41.4029 27.0257 41.8214C27.0257 42.24 27.1931 42.6585 27.4944 42.9598L33.5547 49.0201L35.8315 51.2969C36.1328 51.5982 36.5513 51.7656 36.9699 51.7656C37.3884 51.7656 37.8069 51.5982 38.1083 51.2969L40.385 49.0201L52.5056 36.8996C52.8069 36.5982 52.9743 36.1797 52.9743 35.7612Z"
                                fill="white" />
                        </svg>
                        <h3>Pesanan Anda telah Selesai!</h3>
                        <p>Terima kasih. Pesanan Anda telah kami terima. Kami akan segera memproses pesanan Anda.</p>
                    </div>

                    <div class="order-info">
                        <div class="order-info__item">
                            <label>Nomor Pesanan</label>
                            <span>#{{ $order->id }}</span>
                        </div>
                        <div class="order-info__item">
                            <label>Tanggal</label>
                            <span>{{ $order->created_at->format('d M Y') }}</span>
                        </div>
                        <div class="order-info__item">
                            <label>Total</label>
                            <span>Rp. {{ number_format($order->total, 0, ',', '.') }}</span>
                        </div>
                        <div class="order-info__item">
                            <label>Metode Pembayaran</label>
                            <span>{{ $order->transaction->mode == 'cod' ? 'Cash On Delivery' : 'Transfer' }}</span>
                        </div>
                    </div>

                    @if (isset($transactionDetails))
                        <div class="order-info" style="border-top: 1px solid #ddd; margin-top: 20px; padding-top: 20px;">
                            <div class="order-info__item">
                                <label>ID Transaksi</label>
                                <span>{{ $transactionDetails['transaction_id'] }}</span>
                            </div>
                            <div class="order-info__item">
                                <label>Tipe Pembayaran</label>
                                <span>{{ ucwords($transactionDetails['payment_type']) }}</span>
                            </div>
                            <div class="order-info__item">
                                <label>Status</label>
                                <span
                                    style="color: green; font-weight: bold;">{{ $transactionDetails['status_message'] }}</span>
                            </div>
                    @endif

                    <div class="checkout__totals-wrapper">
                        <div class="checkout__totals">
                            <h3>Detail Pesanan</h3>
                            <table class="checkout-cart-items">
                                <thead>
                                    <tr>
                                        <th>PRODUK</th>
                                        <th class="text-right">SUBTOTAL</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach ($order->orderItems as $item)
                                        <tr>
                                            <td>
                                                {{ $item->product->name }} x {{ $item->quantity }}
                                            </td>
                                            <td class="text-right">
                                                Rp. {{ number_format($item->price * $item->quantity, 0, ',', '.') }}
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                            <table class="checkout-totals">
                                <tbody>
                                    <tr>
                                        <th>SUBTOTAL</th>
                                        <td class="text-right">Rp. {{ number_format($order->subtotal, 0, ',', '.') }}</td>
                                    </tr>
                                    <tr>
                                        <th>DISKON</th>
                                        <td class="text-right">- Rp. {{ number_format($order->discount, 0, ',', '.') }}
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>ONGKOS KIRIM</td>
                                        <td class="text-right">Rp {{ number_format($order->ongkir, 0, ',', '.') }}
                                        </td>
                                    </tr>

                                    <tr>
                                        <th>TOTAL</th>
                                        <td class="text-right"><strong>Rp.
                                                {{ number_format($order->total, 0, ',', '.') }}</strong></td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            @else
                <div class="text-center py-5">
                    <h3>Pesanan tidak ditemukan.</h3>
                    <p>Silakan kembali ke keranjang belanja Anda.</p>
                    <a href="{{ route('cart.index') }}" class="btn btn-primary mt-3">Kembali ke Keranjang</a>
                </div>
            @endif

        </section>
    </main>
@endsection
