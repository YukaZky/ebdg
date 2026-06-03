<?php
// app/Http/Controllers/CouponController.php
namespace App\Http\Controllers;

use App\Models\Coupon;
use Carbon\Carbon;

class CouponController extends Controller
{
    public function publicIndex()
    {
        $now = Carbon::now()->startOfDay();

        // Tampilkan kupon yang belum kedaluwarsa (atau tidak ada expiry_date)
        $rows = Coupon::query()
            ->where(function($q) use ($now) {
                $q->whereNull('expiry_date')->orWhereDate('expiry_date', '>=', $now);
            })
            ->orderBy('expiry_date', 'asc')
            ->get();

        // Normalisasi data untuk view
        $coupons = $rows->map(function($c) use ($now) {
            $end = $c->expiry_date ? Carbon::parse($c->expiry_date)->endOfDay() : null;
            
            // ================= PERBAIKAN DI SINI =================
            return [
                'code'         => $c->code,
                'type'         => $c->type,
                'value'        => (float)$c->value,
                
                // 1. Kirim 'cart_value' (stok) apa adanya
                'cart_value'   => $c->cart_value, 

                // 2. 'min_order' TIDAK SAMA dengan 'cart_value'. 
                //    Jika Anda punya kolom 'min_order' di database, gunakan $c->min_order
                //    Jika tidak punya, isi saja dengan null atau 0
                'min_order'    => null, // Ganti 'null' jika Anda punya kolom minimum order
                
                'max_discount' => null,
                'end'          => $end?->toDateString(),
                'is_active'    => is_null($end) || $end->gte($now),
                'left_days'    => $end ? $now->diffInDays($end, false) : null,
            ];
            // =====================================================
        });

        return view('kupon', compact('coupons'));
    }
}