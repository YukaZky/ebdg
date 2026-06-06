{{-- resources/views/kupon.blade.php --}}
@extends('layouts.app')

@section('content')
<main class="pt-20">
  <section class="container">

    {{-- ===== Header ===== --}}
    <div class="d-flex align-items-center justify-content-between flex-wrap gap-2 mb-4">
      <div>
        <h2 class="mb-1">Kupon Belanja</h2>
        <div class="text-muted">Gunakan kode kupon untuk mendapatkan diskon saat checkout.</div>
      </div>
    </div>

    {{-- ===== Daftar Kupon ===== --}}
    @if(isset($coupons) && count($coupons))
    <div class="row g-3 g-md-4">
      @foreach($coupons as $coupon)
      @php
      // Ambil stok/jumlah kupon
      // DIPERBAIKI: 'cart_value' diprioritaskan karena itu yang dipakai di admin.
      $stok = data_get($coupon, 'cart_value')
              ?? data_get($coupon, 'stok')
              ?? data_get($coupon, 'jumlah');

      // Jika field stok memang ada (BUKAN null) dan nilainya 0 atau kurang → sembunyikan
      // Ini PENTING: Jika kupon stok 0 masih tampil, controller Anda TIDAK mengirim 'cart_value'
      if (!is_null($stok) && (int)$stok <= 0) {
        continue;
      }

      // Ambil field aman untuk array/objek
      $code=(string) (data_get($coupon, 'code' ) ?? data_get($coupon, 'coupon_code' ) ?? data_get($coupon, 'kode' ) ?? 'KUPON' );
      $type=(string) (data_get($coupon, 'type' ) ?? data_get($coupon, 'tipe' ) ?? 'percent' ); // fixed|percent
      $value=(float) (data_get($coupon, 'value' ) ?? data_get($coupon, 'nominal' ) ?? 0);

      // DIPERBAIKI: 'cart_value' BUKAN min order, itu adalah STOK.
      // Jadi, 'cart_value' dihapus dari baris ini.
      $minOrder = data_get($coupon, 'min_order')
                  ?? data_get($coupon, 'min_belanja');

      $endRaw=data_get($coupon, 'expiry_date' ) ?? data_get($coupon, 'end_date' ) ?? data_get($coupon, 'berlaku_sampai' );
      $end=$endRaw ? \Carbon\Carbon::parse($endRaw)->endOfDay() : null;
      $now = \Carbon\Carbon::now();
      $isActive = is_null($end) || $end->gte($now);
      $leftDays = $end ? $now->diffInDays($end, false) : null;

      // Teks potongan di bawah label "KUPON"
      $potonganText = $type === 'fixed'
      ? 'Potongan harga Rp' . number_format($value, 0, ',', '.')
      : 'Potongan ' . rtrim(rtrim(number_format($value, 2, '.', ''), '0'), '.') . '%';
      @endphp

        <div class="col-12 col-md-6 col-xl-4">
          <div class="card h-100 border-0 shadow-sm coupon-card">
            {{-- Header bar --}}
            <div class="coupon-head d-flex align-items-center justify-content-between px-3 py-2">
              <span class="badge coupon-available">Kupon Tersedia</span>
              @if($isActive)
              @else
              <span class="badge coupon-expired">Kedaluwarsa</span>
              @endif
            </div>

            <div class="card-body d-flex flex-column">
              {{-- Kiri: label KUPON + potongan | Kanan: KODE KUPON BESAR --}}
              <div class="d-flex align-items-start justify-content-between mb-3">
                <div class="d-flex flex-column">
                  <span class="coupon-label">KUPON</span>
                  <small class="coupon-potongan mt-2">{{ $potonganText }}</small>

                  @if($end)
                  <small class="text-muted mt-1">
                    Berlaku s/d: <strong>{{ $end->format('d M Y') }}</strong>
                    @if(!is_null($leftDays))
                    <span class="ms-1 {{ $leftDays <= 3 ? 'text-danger' : 'text-muted' }}">
                      ({{ $leftDays >= 0 ? $leftDays.' hari lagi' : 'kedaluwarsa' }})
                    </span>
                    @endif
                  </small>
                  @endif
                </div>

                {{-- Kanan: tampilkan KODE KUPON besar --}}
                <div class="coupon-summary text-end">
                  <div class="coupon-code-big" title="Kode Kupon">{{ $code }}</div>
                </div>
              </div>

              {{-- Aksi --}}
              <div class="mt-auto d-flex gap-2">
                <button class="btn btn-outline-dark flex-grow-1 copy-btn"
                  type="button"
                  data-code="{{ $code }}">
                  Salin Kode
                </button>

                <form method="POST" action="{{ route('cart.apply_coupon_code') }}">
                  @csrf
                  <input type="hidden" name="coupon_code" value="{{ $code }}">
                </form>
              </div>
            </div>

            <div class="coupon-ribbon"></div>
          </div>
        </div>
        @endforeach
    </div>
    @else
    <div class="alert alert-info">Belum ada kupon yang tersedia saat ini.</div>
    @endif


  </section>
</main>

{{-- ====== Styles ====== --}}
<style>
  .coupon-card {
    position: relative;
    overflow: hidden;
    border-radius: 1rem;
    background: #000;
    /* 🔥 background hitam */
    color: #fff;
    /* teks default putih agar kontras */
  }

  .coupon-card:hover {
    transform: translateY(-2px);
    transition: .2s ease;
    box-shadow: 0 10px 20px rgba(0, 0, 0, .08);
  }

  .coupon-head {
    background: linear-gradient(90deg, #111 0%, #222 100%);
    /* header ikut gelap */
    border-bottom: 1px solid rgba(255, 255, 255, .1);
  }

  .coupon-available {
    background: #e7f1ff;
    color: #0b5ed7;
    border-radius: 999px;
    font-weight: 600;
    padding: .35rem .7rem;
  }

  .coupon-limited {
    background: #fff3cd;
    color: #b58100;
    border-radius: 999px;
    font-weight: 600;
    padding: .35rem .7rem;
  }

  .coupon-expired {
    background: #fde2e2;
    color: #b42318;
    border-radius: 999px;
    font-weight: 600;
    padding: .35rem .7rem;
  }

  .coupon-label {
    display: inline-block;
    font-weight: 700;
    letter-spacing: .06em;
    border: 1.5px dashed #ffc107;
    /* dashed jadi kuning */
    padding: .4rem .7rem;
    border-radius: .6rem;
    background: #111;
    color: #ffc107;
  }

  .coupon-potongan {
    color: #fff;
    font-weight: 600;
  }

  /* Kanan: KODE KUPON besar */
  .coupon-summary .coupon-code-big {
    font-size: clamp(26px, 4.2vw, 40px);
    font-weight: 800;
    line-height: 1.05;
    letter-spacing: .04em;
    background: #111;
    color: #ffc107;
    /* kode kupon jadi kuning agar standout */
    padding: .35rem .6rem;
    border-radius: .75rem;
    display: inline-block;
    min-width: 120px;
    text-align: right;
  }

  /* Ribbon garis kuning */
  .coupon-card .coupon-ribbon {
    position: absolute;
    right: -40px;
    top: 12px;
    width: 140px;
    /* diperkecil biar tidak melebihi bawah */
    height: 20px;
    background: repeating-linear-gradient(45deg,
        #ffc107 0 8px,
        /* kuning solid */
        transparent 8px 16px);
    border-radius: 4px;
    transform: rotate(25deg);
    z-index: 1;
  }
</style>


{{-- ====== Script salin kode ====== --}}
<script>
  document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(btn.dataset.code);
        const prev = btn.innerHTML;
        btn.innerHTML = 'Tersalin!';
        btn.classList.remove('btn-outline-dark');
        btn.classList.add('btn-success');
        setTimeout(() => {
          btn.innerHTML = prev;
          btn.classList.add('btn-outline-dark');
          btn.classList.remove('btn-success');
        }, 1400);
      } catch (e) {
        alert('Gagal menyalin kode');
      }
    });
  });
</script>
@endsection