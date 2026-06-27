<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use App\Models\CouponTake;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class ApiMarketplaceClaimedCouponController extends Controller
{
    private function hasCouponColumn(string $column): bool
    {
        return Schema::hasTable('coupons') && Schema::hasColumn('coupons', $column);
    }

    private function isExpired(Coupon $coupon): bool
    {
        if ($this->hasCouponColumn('expires_at') && $coupon->expires_at) {
            return $coupon->expires_at->isPast();
        }

        if ($this->hasCouponColumn('expiry_date') && $coupon->expiry_date) {
            return $coupon->expiry_date < now()->toDateString();
        }

        return false;
    }

    private function isStarted(Coupon $coupon): bool
    {
        if ($this->hasCouponColumn('starts_at') && $coupon->starts_at) {
            return ! $coupon->starts_at->isFuture();
        }

        return true;
    }

    private function isActive(Coupon $coupon): bool
    {
        if ($this->hasCouponColumn('status')) {
            return $coupon->status === 'active' || (string) $coupon->status === '1' || $coupon->status === null;
        }

        if ($this->hasCouponColumn('is_active')) {
            return (bool) $coupon->is_active;
        }

        return true;
    }

    private function couponPayload(Coupon $coupon): array
    {
        $data = $coupon->toArray();
        $rawType = $data['type'] ?? ($data['coupon_type'] ?? 'fixed');

        $data['name'] = $data['name'] ?? ($data['title'] ?? ($data['coupon_name'] ?? ($data['code'] ?? ($data['coupon_code'] ?? 'Kupon Toko'))));
        $data['code'] = $data['code'] ?? ($data['coupon_code'] ?? ('KUPON' . $coupon->id));
        $data['type'] = $rawType === 'percent' ? 'discount' : $rawType;
        $data['value'] = $data['value'] ?? ($data['amount'] ?? ($data['discount'] ?? ($data['discount_amount'] ?? 0)));
        $data['min_purchase'] = $data['min_purchase'] ?? ($data['cart_value'] ?? ($data['minimum_purchase'] ?? ($data['min_order'] ?? 0)));
        $data['max_discount'] = $data['max_discount'] ?? null;
        $data['expires_at'] = $data['expires_at'] ?? ($data['expiry_date'] ?? null);

        return $data;
    }

    public function index(Request $request)
    {
        $takes = CouponTake::with('coupon')
            ->where('id_user', $request->user()->id)
            ->latest()
            ->get();

        $data = $takes->map(function (CouponTake $take) {
            $coupon = $take->coupon;

            if (! $coupon) {
                return null;
            }

            $expired = $this->isExpired($coupon);
            $started = $this->isStarted($coupon);
            $active = $this->isActive($coupon);
            $usable = $take->status === 'take' && $active && $started && ! $expired;

            return [
                'id' => $take->id,
                'id_cuppon' => $take->id_cuppon,
                'id_user' => $take->id_user,
                'status' => $take->status,
                'claimed_at' => optional($take->created_at)->toDateTimeString(),
                'is_expired' => $expired,
                'is_active' => $active,
                'is_started' => $started,
                'can_use' => $usable,
                'usage_status' => $expired ? 'expired' : ($usable ? 'available' : $take->status),
                'coupon' => $this->couponPayload($coupon),
            ];
        })->filter()->values();

        return response()->json(['success' => true, 'data' => $data]);
    }
}
