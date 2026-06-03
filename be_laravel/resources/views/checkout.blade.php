@extends('layouts.app')

@section('content')
<main class="pt-20">
  <section class="shop-checkout container">

    {{-- ===== PAGE HEADER ===== --}}
    <header class="ck-header d-flex align-items-center justify-content-between mb-4 flex-wrap gap-3">
      <div>
        <h2 class="ck-title mb-1">Pengiriman & Checkout</h2>
        <p class="ck-subtitle mb-0">Periksa alamat, ongkos kirim, lalu pilih metode pembayaran.</p>
      </div>
    </header>

    {{-- ========= KALKULASI TERPUSAT UNTUK KUPON ========= --}}
    @php
      // Total dari server (sebelum ongkir)
      $serverTotal = isset($total) ? (int)$total : 0;

      if (Session::has('discounts')) {
          // Controller sudah menaruh subtotal (SETELAH diskon) dan discount
          $rawSubtotal = (int)(Session::get('discounts')['subtotal'] ?? $serverTotal);
          $discount    = (int)(Session::get('discounts')['discount']  ?? 0);
      } else {
          // Fallback bila hanya session 'coupon' yg ada
          $rawSubtotal = $serverTotal;
          $discount = 0;

          if (Session::has('coupon')) {
              $c    = Session::get('coupon');
              $type = $c['type'] ?? $c['kind'] ?? $c['mode'] ?? null;     // 'percent' | 'fixed'
              $val  = $c['value'] ?? $c['amount'] ?? $c['discount'] ?? 0; // angka kupon
              $pct  = $c['percent'] ?? $c['percentage'] ?? null;

              if (in_array($type, ['percent','percentage','%'], true)) {
                  $rate = is_numeric($pct) ? (float)$pct : (float)$val;
                  $discount = (int) floor($rawSubtotal * max(0, $rate) / 100);
              } elseif ($type === 'fixed' || $type === 'amount') {
                  $discount = (int) $val;
              } else {
                  $num = (float)$val;
                  $discount = ($num > 0 && $num <= 100)
                      ? (int) floor($rawSubtotal * $num / 100)
                      : (int) $num;
              }
          }
      }

      // Guard
      $discount = max(0, min($discount, $rawSubtotal));
      $totalAfterDiscount = max(0, $rawSubtotal - $discount);
    @endphp
    {{-- ========= /KALKULASI ========= --}}

    <form id="checkout-form" name="checkout-form" action="{{ route('cart.place.an.order') }}" method="POST" class="ck-form">
      @csrf

      <div class="row g-4">
        {{-- ===================== LEFT: DETAIL PENGIRIMAN ===================== --}}
        <div class="col-lg-7">
          {{-- DETAIL PENGIRIMAN --}}
          <div class="card ck-card mb-4">
            <div class="card-header ck-card__header">
              <div class="d-flex align-items-center justify-content-between w-100 gap-2">
                <h5 class="mb-0 d-flex align-items-center gap-2">
                  <span class="ck-icon">
                    <svg width="18" height="18" viewBox="0 0 24 24"><path d="M12 2a7 7 0 0 0-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 0 0-7-7zm0 9.5A2.5 2.5 0 1 1 12 6a2.5 2.5 0 0 1 0 5.5z" fill="currentColor"/></svg>
                  </span>
                  Detail Pengiriman
                </h5>
                @if ($address)
                  <a href="{{ route('user.address.index') }}" class="btn btn-link p-0 fw-semibold">Ubah Alamat</a>
                @endif
              </div>
            </div>

            <div class="card-body">
              {{-- Jika alamat sudah ada, tampilkan --}}
              @if ($address)
                <div class="ck-address">
                  <div class="d-flex align-items-center justify-content-between flex-wrap gap-2 mb-2">
                    <span class="badge ck-badge">Alamat Utama</span>
                    <small class="text-muted">Pastikan detailnya benar sebelum lanjut pembayaran.</small>
                  </div>
                  <div class="ck-address__content">
                    <div class="ck-address__left">
                      <p class="mb-1 fw-semibold">{{ $address->name }}</p>
                      <p class="mb-0 text-muted">{{ $address->phone }}</p>
                    </div>
                    <div class="ck-address__right">
                      <p class="mb-1">{{ $address->address }}</p>
                      <p class="mb-1">{{ $address->landmark }}</p>
                      <p class="mb-1">{{ $address->locality }}, {{ $address->city }}, {{ $address->state }}</p>
                      <p class="mb-0">{{ $address->zip }}, {{ $address->country }}</p>
                    </div>
                  </div>
                </div>
              @else
                {{-- Jika alamat belum ada, CTA tambah alamat --}}
                <div class="ck-address ck-address--empty">
                  <div class="d-flex align-items-start gap-3">
                    <div class="ck-address__icon">
                      <svg width="22" height="22" viewBox="0 0 24 24"><path d="M12 2a7 7 0 0 0-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 0 0-7-7zm1 10H11V9H8V7h3V4h2v3h3v2h-3v3z" fill="currentColor"/></svg>
                    </div>
                    <div class="flex-grow-1">
                      <div class="fw-semibold mb-1">Belum ada alamat tersimpan</div>
                      <div class="small text-muted mb-2">Silakan daftarkan alamat pengiriman terlebih dahulu.</div>
                      <a href="{{ route('user.address.add') }}" class="btn btn-sm btn-info">Tambah Baru</a>
                    </div>
                  </div>
                </div>
              @endif
            </div>
          </div>

          {{-- EKSPEDISI & ONGKIR --}}
          <div class="card ck-card mb-4">
            <div class="card-header ck-card__header">
              <h5 class="mb-0 d-flex align-items-center gap-2">
                <span class="ck-icon">
                  <svg width="18" height="18" viewBox="0 0 24 24"><path d="M20 8h-3V4H3v13h2a3 3 0 0 0 6 0h4a3 3 0 0 0 6 0h2v-5l-3-4zM7 19a1 1 0 1 1 0-2 1 1 0 0 1 0 2zm10 0a1 1 0 1 0 .001-2.001A1 1 0 0 1 17 19zm3-4h-1.17a3.001 3.001 0 0 0-5.66 0H11a3.001 3.001 0 0 0-5.66 0H5V6h10v4h4l1 1.333V15z" fill="currentColor"/></svg>
                </span>
                Ekspedisi & Ongkos Kirim
              </h5>
            </div>

            <div class="card-body">
              {{-- Hidden hasil pilihan ongkir (untuk dikirim ke server) --}}
              <input type="hidden" name="shipping_courier" id="shipping_courier">
              <input type="hidden" name="shipping_service" id="shipping_service">
              <input type="hidden" name="shipping_cost" id="shipping_cost" value="0">
              <input type="hidden" name="shipping_etd" id="shipping_etd">

              {{-- Total barang SETELAH diskon untuk kalkulasi client-side --}}
              <input type="hidden" id="base_total_without_shipping"
                     value="@if(Session::has('discounts')){{ Session::get('discounts')['subtotal'] }}@else{{ $total }}@endif">

              <div class="mb-3">
                <div class="ck-courier d-flex flex-wrap gap-2">
                  <label class="ck-pill">
                    <input type="radio" id="courier_jne" name="courier" value="jne" class="d-none" checked>
                    <span>JNE</span>
                  </label>
                  <label class="ck-pill">
                    <input type="radio" id="courier_pos" name="courier" value="pos" class="d-none">
                    <span>POS Indonesia</span>
                  </label>
                  <label class="ck-pill">
                    <input type="radio" id="courier_jnt" name="courier" value="jnt" class="d-none">
                    <span>J&amp;T</span>
                  </label>
                </div>
              </div>

              <div class="d-flex align-items-center gap-2 flex-wrap">
                <button type="button" class="btn btn-primary" id="btnCheckOngkir">
                  Cek Ongkos Kirim
                </button>
                <div id="shippingNote" class="text-muted small"></div>
              </div>

              <div id="shippingOptions" class="mt-3 ck-ship-options"></div>

              {{-- elemen lama (biarkan ada) --}}
              <ul id="ongkirResult" class="list-group d-none"></ul>
              <div id="ongkirEmpty" class="alert alert-warning d-none mt-3 mb-0">Tarif tidak tersedia.</div>
            </div>
          </div>
        </div>

        {{-- ===================== RIGHT: RINGKASAN & PEMBAYARAN ===================== --}}
        <div class="col-lg-5">
          <div class="position-lg-sticky top-lg-20">

            {{-- RINGKASAN --}}
            <div class="card ck-card mb-4">
              <div class="card-header ck-card__header">
                <h5 class="mb-0 d-flex align-items-center gap-2">
                  <span class="ck-icon">
                    <svg width="18" height="18" viewBox="0 0 24 24"><path d="M7 4h-2l-1 2H1v2h2l3.6 7.59-1.35 2.45A1.996 1.996 0 0 0 6 20h12v-2H6.42a.25.25 0 0 1-.22-.37L7.1 16h7.45a2 2 0 0 0 1.79-1.11L21 6H7.42L7 4zM7 22a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm10 0a2 2 0 1 0 .001-3.999A2 2 0 0 0 17 22z" fill="currentColor"/></svg>
                  </span>
                  Ringkasan Pesanan
                </h5>
              </div>
              <div class="card-body">
                <div class="table-responsive">
                  <table class="table align-middle ck-table-items mb-3">
                    <tbody>
                      @foreach ($items as $item)
                        <tr>
                          <td class="border-0">
                            <div class="fw-semibold">{{ $item->product->name }}</div>
                            <div class="text-muted small">x {{ $item->quantity }}</div>
                          </td>
                          <td class="border-0 text-end">
                            Rp. {{ number_format($item->subtotal ?? $item->price * $item->quantity, 0, ',', '.') }}
                          </td>
                        </tr>
                      @endforeach
                    </tbody>
                  </table>
                </div>

                <hr class="ck-sep">

                {{-- INPUT KUPON --}}
                @if (!Session::has('coupon'))
                  <div class="position-relative bg-body">
                    <input class="form-control" type="text" name="coupon_code" id="coupon_code"
                           placeholder="Kode Kupon" value="" form="coupon-apply-form">
                    <input class="btn-link fw-medium position-absolute top-0 end-0 h-100 px-4"
                           type="submit" id="apply-voucher-btn" value="GUNAKAN KUPON"
                           form="coupon-apply-form" disabled>
                  </div>
                @else
                  <div class="position-relative bg-body">
                    <input class="form-control" type="text" name="coupon_code" placeholder="Coupon Code"
                           value="@if (Session::has('coupon')) {{ Session::get('coupon')['code'] }} Digunakan! @endif" readonly
                           form="coupon-remove-form">
                    <input class="btn-link fw-medium position-absolute top-0 end-0 h-100 px-4"
                           type="submit" value="HAPUS KUPON" form="coupon-remove-form">
                  </div>
                @endif
                {{-- /INPUT KUPON --}}

                <div class="mt-2">
                  @if (Session::has('success'))
                    <p class="text-success">{{ Session::get('success') }}</p>
                  @elseif(Session::has('error'))
                    <p class="text-danger">{{ Session::get('error') }}</p>
                  @endif
                </div>

                <div class="table-responsive">
                  <table class="table ck-table-totals mb-0">
                    <tbody>
                      @if (Session::has('discounts'))
                        {{-- Subtotal (sebelum diskon) --}}
                        <tr>
                          <th class="border-0">Subtotal</th>
                          <td class="border-0 text-end" id="subtotal_products_text">
                            Rp. {{ number_format($subtotal, 0, ',', '.') }}
                          </td>
                        </tr>
                        {{-- Diskon --}}
                        <tr>
                          @php $couponCode = data_get(Session::get('coupon'), 'code', 'Kupon'); @endphp
<th class="border-0">Diskon ({{ $couponCode }})</th>

                          <td class="border-0 text-end">
                            - Rp. {{ number_format(Session::get('discounts')['discount'], 0, ',', '.') }}
                          </td>
                        </tr>
                        {{-- Total barang (setelah diskon) --}}
                        <tr>
                          <th class="border-0">Total Barang</th>
                          <td class="border-0 text-end" id="total_products_text">
                            Rp. {{ number_format(Session::get('discounts')['subtotal'], 0, ',', '.') }}
                          </td>
                        </tr>
                      @else
                        <tr>
                          <th class="border-0">Total Barang</th>
                          <td class="border-0 text-end" id="total_products_text">
                            Rp. {{ number_format($total, 0, ',', '.') }}
                          </td>
                        </tr>
                      @endif

                      {{-- Ongkos Kirim (dinamis) --}}
                      <tr>
                        <th class="border-0">Ongkos Kirim</th>
                        <td class="border-0 text-end" id="shipping_cost_text">Rp. 0</td>
                      </tr>

                      <tr class="fw-semibold ck-total-row">
                        <th class="border-0">Total Bayar</th>
                        <td class="border-0 text-end" id="grand_total_text">
                          {{-- default: total setelah diskon, ongkir 0 --}}
                          Rp. {{ number_format($totalAfterDiscount, 0, ',', '.') }}
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                {{-- Hidden untuk server --}}
                <input type="hidden" name="products_total_without_shipping" id="products_total_without_shipping_hidden"
                       value="@if(Session::has('discounts')){{ Session::get('discounts')['subtotal'] }}@else{{ $total }}@endif">
                <input type="hidden" name="grand_total_client" id="grand_total_client_hidden"
                       value="@if(Session::has('discounts')){{ Session::get('discounts')['subtotal'] }}@else{{ $total }}@endif">
              </div>
            </div>

            {{-- METODE PEMBAYARAN --}}
            <div class="card ck-card mb-4">
              <div class="card-header ck-card__header">
                <h5 class="mb-0 d-flex align-items-center gap-2">
                  <span class="ck-icon">
                    <svg width="18" height="18" viewBox="0 0 24 24"><path d="M21 6H3a2 2 0 0 0-2 2v1h22V8a2 2 0 0 0-2-2zM1 18a2 2 0 0 0 2 2h18a2 2 0 0 0 2-2V11H1v7zm5-3h4v2H6v-2z" fill="currentColor"/></svg>
                  </span>
                  Metode Pembayaran
                </h5>
              </div>
              <div class="card-body">
                <div class="ck-payment vstack gap-3">
                  <label class="ck-radio">
                    <input class="form-check-input form-check-input_fill" type="radio" name="mode" id="mode3" value="cod" checked>
                    <span class="ck-radio__box"></span>
                    <span class="ck-radio__label">Cash On Delivery (COD)</span>
                  </label>
                  <label class="ck-radio">
                    <input class="form-check-input form-check-input_fill" type="radio" name="mode" id="mode4" value="transfer">
                    <span class="ck-radio__box"></span>
                    <span class="ck-radio__label">Transfer Bank</span>
                  </label>
                </div>

                <div class="ck-policy small text-muted mt-3">
                  Data pribadi Anda akan digunakan untuk memproses pesanan Anda...
                </div>
                @error('mode')<div class="text-danger mt-2">{{ $message }}</div>@enderror

                {{-- gunakan id "place-order-btn" --}}
                <button type="submit" id="place-order-btn" class="btn btn-primary w-100 mt-3" disabled>
                  Buat Pesanan
                </button>
              </div>
            </div>

          </div>
        </div>
      </div> {{-- /row --}}
    </form>

    {{-- ====== Form asli untuk kupon (di luar #checkout-form supaya tidak nested) ====== --}}
    @if (!Session::has('coupon'))
      <form id="coupon-apply-form" action="{{ route('cart.coupon.apply') }}" method="POST" class="d-none">
        @csrf
      </form>
    @else
      <form id="coupon-remove-form" action="{{ route('cart.coupon.remove') }}" method="POST" class="d-none">
        @csrf
        @method('DELETE')
      </form>
    @endif

  </section>
</main>

{{-- ========== STYLE KHUSUS TAMPILAN (UI ONLY) ========== --}}
@push('styles')
<style>
  :root{
    --ck-border: rgba(0,0,0,.08);
    --ck-border-strong: rgba(0,0,0,.12);
    --ck-bg-soft: #f7f8fa;
    --ck-primary: #0d6efd;
    --ck-radius: 14px;
  }

  .top-lg-20 { top: 20px; }
  @media (min-width: 992px) { .position-lg-sticky { position: sticky; } }

  .ck-title{ font-weight:800; letter-spacing:.2px; }
  .ck-subtitle{ color:#666; }

  .ck-card{ border:1px solid var(--ck-border); border-radius:var(--ck-radius); overflow:hidden; }
  .ck-card__header{ background:#fff; border-bottom:1px solid var(--ck-border); padding:1rem 1.25rem; }
  .ck-card .card-body{ padding:1.25rem; }
  .ck-icon{ display:inline-flex; align-items:center; justify-content:center; color:var(--ck-primary); }

  .ck-badge{
    background:rgba(13,110,253,.08); color:#0b5ed7; border:1px solid rgba(13,110,253,.2);
    padding:.3rem .55rem; border-radius:999px;
  }
  .ck-address{ border:1px dashed var(--ck-border-strong); background:#fff; border-radius:12px; padding:1rem; }
  .ck-address--empty{ background:#f9fbff; }
  .ck-address__content{ display:grid; grid-template-columns: 1fr 2fr; gap:1rem; }
  .ck-address__icon{ color:var(--ck-primary); }
  @media (max-width: 576px){ .ck-address__content{ grid-template-columns:1fr; } }

  .ck-pill{
    display:inline-flex; align-items:center; gap:.5rem; padding:.5rem .85rem; border-radius:999px;
    border:1px solid var(--ck-border); cursor:pointer; user-select:none; background:#fff;
    transition: all .15s ease;
  }
  .ck-pill:hover{ border-color:var(--ck-border-strong); background:#fafafa; }
  .ck-pill input:checked ~ span{ font-weight:600; }
  .ck-pill input:checked ~ span::after{ content:""; display:inline-block; width:.5rem; height:.5rem; margin-left:.4rem; border-radius:50%; background:var(--ck-primary); }

  #shippingOptions .custom-control{ border:1px solid var(--ck-border); border-radius:12px; padding:.85rem .85rem .85rem 2.25rem; background:#fff; }
  #shippingOptions .custom-control:hover{ background:#fafafa; border-color:var(--ck-border-strong); }
  .ck-ship-options{ display:grid; gap:.6rem; }

  .ck-table-items th, .ck-table-items td{ background:transparent !important; }
  .ck-sep{ border-color:var(--ck-border); opacity:1; }

  .ck-table-totals th{ width:55%; }
  .ck-total-row td, .ck-total-row th{ border-top:1px dashed var(--ck-border-strong) !important; font-size:1.05rem; }

  .ck-radio{ position:relative; display:flex; align-items:center; gap:.75rem; cursor:pointer; }
  .ck-radio input{ position:absolute; opacity:0; }
  .ck-radio__box{
    width:22px; height:22px; border:2px solid var(--ck-border-strong); border-radius:50%;
    display:inline-block; transition:.15s ease; background:#fff;
  }
  .ck-radio input:checked + .ck-radio__box{ border-color:var(--ck-primary); box-shadow:inset 0 0 0 6px var(--ck-primary); }
  .ck-radio__label{ font-weight:600; }

  .btn-primary{ border-radius:12px; padding:.7rem 1rem; font-weight:600; }
  .ck-policy{ line-height:1.6; }
</style>
@endpush

{{-- ====== SCRIPT ====== --}}
@push('scripts')
{{-- Midtrans Snap --}}
<script type="text/javascript" src="https://app.sandbox.midtrans.com/snap/snap.js"
  data-client-key="{{ config('midtrans.client_key') }}"></script>

<script type="text/javascript">
  $(document).ready(function() {
    let pendingOrderId = null;

    // Tombol voucher aktif saat ada input
    const couponInput = $('#coupon_code');
    const applyBtn = $('#apply-voucher-btn');
    couponInput.on('input', function() {
      applyBtn.prop('disabled', $(this).val().trim() === '');
    });

    $('#checkout-form').on('submit', function(event) {
      var payButton = $('#place-order-btn');
      var selectedPaymentMethod = $('input[name="mode"]:checked').val();

      if (selectedPaymentMethod === 'transfer') {
        event.preventDefault();

        payButton.prop('disabled', true).text('Memproses...');

        $.ajax({
          url: $(this).attr('action'),
          method: 'POST',
          data: $(this).serialize(),
          cache: false,
          success: function(data) {
            if (data.error || !data.snap_token) {
              alert(data.error || 'Gagal mendapatkan token pembayaran.');
              payButton.prop('disabled', false).text('Buat Pesanan');
              return;
            }

            pendingOrderId = data.order_id;

            snap.pay(data.snap_token, {
              onSuccess: function(result) {
                pendingOrderId = null;
                sendPaymentResult(result);
              },
              onPending: function(result) {
                alert("Pembayaran Gagal!");
                cancelOrder(pendingOrderId);
                payButton.prop('disabled', false).text('Buat Pesanan');
              },
              onError: function() {
                alert("Pembayaran Gagal!");
                cancelOrder(pendingOrderId);
                payButton.prop('disabled', false).text('Buat Pesanan');
              },
              onClose: function() {
                if (pendingOrderId) {
                  cancelOrder(pendingOrderId);
                }
                payButton.prop('disabled', false).html('Buat Pesanan');
              }
            });
          },
          error: function(xhr) {
            console.error(xhr.responseText);
            alert("Terjadi kesalahan saat membuat pesanan. Silakan coba lagi.");
            payButton.prop('disabled', false).text('Buat Pesanan');
          }
        });
      } else {
        payButton.prop('disabled', true).text('Memproses...');
      }
    });

    function sendPaymentResult(result) {
      $.ajax({
        url: "{{ route('payment.success') }}",
        method: 'POST',
        data: {
          _token: '{{ csrf_token() }}',
          result: result
        },
        success: function() {
          window.location.href = "{{ route('cart.order.confirmation') }}";
        },
        error: function(xhr) {
          console.error(xhr.responseText);
          alert('Gagal memproses hasil pembayaran di server.');
        }
      });
    }

    function cancelOrder(orderId) {
      if (!orderId) return;
      $.ajax({
        url: "{{ route('cart.order.cancel') }}",
        method: 'POST',
        data: {
          _token: "{{ csrf_token() }}",
          order_id: orderId
        },
        success: function() {},
        error: function(xhr) { console.error(xhr.responseText); }
      });
    }
  });
</script>

{{-- Variabel RO dari server --}}
<script>
  window.RO_CHECK_URL = "{{ route('ro.check') }}"; // endpoint cek ongkir anda
  window.RO_DEST = @json($address -> district_id ?? ''); // id kecamatan tujuan (UI-only)
  window.RO_WEIGHT_G = @json((int)($totalWeightG ?? 1)); // total berat gram
</script>

{{-- Ongkir checker + KALKULASI RINGKASAN (dinamis) --}}
<script>
  document.addEventListener('DOMContentLoaded', function() {
    const btn = document.getElementById('btnCheckOngkir');
    const box = document.getElementById('shippingOptions');
    const note = document.getElementById('shippingNote');

    const hidCourier = document.getElementById('shipping_courier');
    const hidService = document.getElementById('shipping_service');
    const hidCost = document.getElementById('shipping_cost');
    const hidEtd = document.getElementById('shipping_etd');

    const lblShip = document.getElementById('shipping_cost_text');
    const lblGrand = document.getElementById('grand_total_text');

    const baseWithoutShipInput = document.getElementById('base_total_without_shipping');
    const hiddenProductsTotal = document.getElementById('products_total_without_shipping_hidden');
    const hiddenGrandClient = document.getElementById('grand_total_client_hidden');
    const placeBtn = document.getElementById('place-order-btn');

    function rupiah(n) {
      return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        maximumFractionDigits: 0
      }).format(Number(n || 0));
    }

    function getBaseTotal() {
      const v = Number(baseWithoutShipInput?.value || hiddenProductsTotal?.value || 0);
      return isNaN(v) ? 0 : v;
    }

    function recalcGrand() {
      const base = getBaseTotal();
      const ship = Number(hidCost?.value || 0);
      const grand = base + ship;

      if (lblShip) lblShip.textContent = rupiah(ship);
      if (lblGrand) lblGrand.textContent = rupiah(grand);
      if (hiddenGrandClient) hiddenGrandClient.value = grand;
    }

    function applySelection(radio) {
      if (!radio) return;
      if (hidCourier) hidCourier.value = radio.dataset.courier || '';
      if (hidService) hidService.value = radio.dataset.service || '';
      if (hidCost) hidCost.value = radio.dataset.price || '0';
      if (hidEtd) hidEtd.value = radio.dataset.etd || '';
      recalcGrand();
    }

    const token = document.querySelector('meta[name="csrf-token"]')?.content || '';
    const destinationDistrictId = window.RO_DEST || '';
    const totalWeightGram = Number(window.RO_WEIGHT_G || 1) || 1;
    const getCourier = () => document.querySelector('input[name="courier"]:checked')?.value || 'jne';

    async function checkOngkir() {
      box.innerHTML = '';
      note.textContent = '';

      if (!destinationDistrictId) {
        note.textContent = 'Alamat tujuan belum lengkap (kecamatan belum dipilih).';
        return;
      }

      const payload = new URLSearchParams({
        district_id: String(destinationDistrictId),
        weight: String(Math.max(1, +totalWeightGram || 1)),
        courier: String(getCourier())
      });

      let res;
      try {
        res = await fetch(window.RO_CHECK_URL, {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'X-CSRF-TOKEN': token,
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: payload.toString()
        });
      } catch (e) {
        note.textContent = 'Tidak bisa menghubungi server ongkir.';
        if (placeBtn) placeBtn.disabled = true;
        return;
      }

      let data;
      try { data = await res.json(); } catch (e) { data = {}; }

      const results = Array.isArray(data?.results) ? data.results : (Array.isArray(data) ? data : []);
      renderServices(results, data?.message);
    }

    function renderServices(results, apiMessage) {
      box.innerHTML = '';
      if (!Array.isArray(results) || results.length === 0) {
        box.innerHTML = '<div class="alert alert-warning mb-0">Tarif tidak tersedia.</div>';
        if (apiMessage) note.textContent = apiMessage;
        if (hidCost) hidCost.value = 0;
        recalcGrand();
        if (placeBtn) placeBtn.disabled = true;
        return;
      }

      // Format flat {service, description, cost, etd}
      if ('cost' in (results[0] || {})) {
        const frag = document.createDocumentFragment();
        const courierCode = getCourier();

        results.forEach((r, idx) => {
          const svc = r.service || '';
          const desc = r.description || '';
          const price = Number(r.cost) || 0;
          const etd = r.etd || '';
          const id = `ship_${svc}_${idx}`;

          const wrap = document.createElement('div');
          wrap.className = 'custom-control custom-radio mb-2';
          wrap.innerHTML =
            '<input type="radio" id="' + id + '" name="shipping_pick" class="custom-control-input"' +
            ' data-courier="' + courierCode + '" data-service="' + svc + '" data-price="' + price + '" data-etd="' + etd + '">' +
            '<label class="custom-control-label" for="' + id + '">' +
            '<strong>' + svc + '</strong> — ' + desc + ' · ' + rupiah(price) + (etd ? ' · ETD ' + etd : '') +
            '</label>';
          frag.appendChild(wrap);
        });

        box.appendChild(frag);

        const radios = box.querySelectorAll('input[name="shipping_pick"]');
        if (radios.length) {
          let pick = radios[0];
          radios.forEach(r => { if (+r.dataset.price < +pick.dataset.price) pick = r; });
          pick.checked = true;
          applySelection(pick);
          if (placeBtn) placeBtn.disabled = false;
        }

        box.addEventListener('change', (e) => {
          if (e.target && e.target.name === 'shipping_pick') applySelection(e.target);
          if (placeBtn) placeBtn.disabled = false;
        });

        return;
      }

      // Format RajaOngkir klasik
      const first = results[0] || {};
      const courierCode = first.code || getCourier();
      const costs = Array.isArray(first.costs) ? first.costs : [];

      if (!costs.length) {
        box.innerHTML = '<div class="alert alert-warning mb-0">Layanan tidak ditemukan untuk kurir terpilih. Coba kurir lain.</div>';
        if (hidCost) hidCost.value = 0;
        recalcGrand();
        return;
      }

      const frag = document.createDocumentFragment();
      costs.forEach((c, idx) => {
        const svc = c?.service || '';
        const desc = c?.description || '';
        const price = (c?.cost?.[0]?.value) ?? 0;
        const etd = (c?.cost?.[0]?.etd) ?? '';
        const id = `ship_${svc}_${idx}`;

        const wrap = document.createElement('div');
        wrap.className = 'custom-control custom-radio mb-2';
        wrap.innerHTML =
          '<input type="radio" id="' + id + '" name="shipping_pick" class="custom-control-input"' +
          ' data-courier="' + courierCode + '" data-service="' + svc + '" data-price="' + price + '" data-etd="' + etd + '">' +
          '<label class="custom-control-label" for="' + id + '">' +
          '<strong>' + svc + '</strong> — ' + desc + ' · ' + rupiah(price) + (etd ? ' · ETD ' + etd + ' hari' : '') +
          '</label>';
        frag.appendChild(wrap);
      });
      box.appendChild(frag);

      const radios2 = box.querySelectorAll('input[name="shipping_pick"]');
      if (radios2.length) {
        let pick = radios2[0];
        radios2.forEach(r => { if (+r.dataset.price < +pick.dataset.price) pick = r; });
        pick.checked = true;
        applySelection(pick);
        if (placeBtn) placeBtn.disabled = false;
      }

      box.addEventListener('change', (e) => {
        if (e.target && e.target.name === 'shipping_pick') applySelection(e.target);
        if (placeBtn) placeBtn.disabled = false;
      });
    }

    // tombol cek ongkir
    document.getElementById('btnCheckOngkir')?.addEventListener('click', checkOngkir);

    // inisialisasi tampilan default
    recalcGrand();
    document.querySelector('form#checkout-form')?.addEventListener('submit', (e) => {
      if (!hidCost || Number(hidCost.value || 0) <= 0) {
        e.preventDefault();
        note.textContent = 'Silakan cek dan pilih ongkos kirim terlebih dahulu.';
        if (placeBtn) placeBtn.disabled = true;
      }
    });

  });
</script>
@endpush
@endsection
