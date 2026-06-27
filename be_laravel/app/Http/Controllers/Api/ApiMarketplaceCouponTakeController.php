<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use App\Models\CouponTake;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ApiMarketplaceCouponTakeController extends Controller
{
    private function hasCouponColumn(string $column): bool
    {
        return Schema::hasTable('coupons') && Schema::hasColumn('coupons', $column);
    }

    private function hasTakeColumn(string $column): bool
    {
        return Schema::hasTable('cuppon_takes') && Schema::hasColumn('cuppon_takes', $column);
    }

    private function payload(Coupon $coupon, ?int $userId = null): array
    {
        $take = $userId
            ? CouponTake::where('id_cuppon', $coupon->id)->where('id_user', $userId)->first()
            : null;

        $data = $coupon->toArray();
        $rawType = $data['type'] ?? ($data['coupon_type'] ?? 'fixed');
        $data['name'] = $data['name'] ?? ($data['title'] ?? ($data['coupon_name'] ?? ($data['code'] ?? ($data['coupon_code'] ?? 'Kupon Toko'))));
        $data['code'] = $data['code'] ?? ($data['coupon_code'] ?? ('KUPON' . $coupon->id));
        $data['type'] = $rawType === 'percent' ? 'discount' : $rawType;
        $data['value'] = $data['value'] ?? ($data['amount'] ?? ($data['discount'] ?? ($data['discount_amount'] ?? 0)));
        $data['min_purchase'] = $data['min_purchase'] ?? ($data['cart_value'] ?? ($data['minimum_purchase'] ?? ($data['min_order'] ?? 0)));
        $data['max_discount'] = $data['max_discount'] ?? null;
        $data['status'] = $data['status'] ?? 'active';
        $data['remaining_limit'] = $data['usage_limit'] ?? null;
        $data['take_status'] = $take?->status;
        $data['is_taken'] = (bool) $take;
        $data['taken_count'] = CouponTake::where('id_cuppon', $coupon->id)->count();
        return $data;
    }

    private function saveCoupon(Coupon $coupon, array $attributes): void
    {
        if (! $this->hasCouponColumn('created_at') && ! $this->hasCouponColumn('updated_at')) {
            $coupon->timestamps = false;
        }

        $coupon->forceFill($attributes);
        $coupon->save();
    }

    private function createTake(Coupon $coupon, int $userId)
    {
        $payload = [
            'id_cuppon' => $coupon->id,
            'id_user' => $userId,
            'status' => 'take',
        ];

        if ($this->hasTakeColumn('created_at')) {
            $payload['created_at'] = now();
        }

        if ($this->hasTakeColumn('updated_at')) {
            $payload['updated_at'] = now();
        }

        $id = DB::table('cuppon_takes')->insertGetId($payload);
        return CouponTake::find($id) ?: (object) array_merge(['id' => $id], $payload);
    }

    public function take(Request $request, $id)
    {
        if (! Schema::hasTable('cuppon_takes')) {
            return response()->json(['success' => false, 'message' => 'Tabel cuppon_takes belum dimigrate.'], 422);
        }

        return DB::transaction(function () use ($request, $id) {
            $coupon = Coupon::query()
                ->when($this->hasCouponColumn('status'), fn ($query) => $query->where(function ($query) {
                    $query->where('status', 'active')->orWhere('status', 1)->orWhereNull('status');
                }))
                ->lockForUpdate()
                ->findOrFail($id);

            if ($this->hasCouponColumn('id_user') && (int) $coupon->id_user === (int) $request->user()->id) {
                return response()->json(['success' => false, 'message' => 'Tidak bisa mengambil kupon toko sendiri.'], 422);
            }

            if ($this->hasCouponColumn('user_id') && (int) $coupon->user_id === (int) $request->user()->id) {
                return response()->json(['success' => false, 'message' => 'Tidak bisa mengambil kupon toko sendiri.'], 422);
            }

            if ($this->hasCouponColumn('starts_at') && $coupon->starts_at && $coupon->starts_at->isFuture()) {
                return response()->json(['success' => false, 'message' => 'Kupon belum aktif.'], 422);
            }

            if ($this->hasCouponColumn('expires_at') && $coupon->expires_at && $coupon->expires_at->isPast()) {
                return response()->json(['success' => false, 'message' => 'Kupon sudah kedaluwarsa.'], 422);
            }

            if ($this->hasCouponColumn('expiry_date') && $coupon->expiry_date && $coupon->expiry_date < now()->toDateString()) {
                return response()->json(['success' => false, 'message' => 'Kupon sudah kedaluwarsa.'], 422);
            }

            $take = CouponTake::where('id_cuppon', $coupon->id)
                ->where('id_user', $request->user()->id)
                ->first();

            if ($take && $take->status === 'used') {
                return response()->json(['success' => false, 'message' => 'Kupon sudah pernah digunakan.'], 422);
            }

            if ($take) {
                return response()->json([
                    'success' => true,
                    'message' => 'Kupon sudah diambil.',
                    'data' => $take,
                    'coupon' => $this->payload($coupon->fresh(), $request->user()->id),
                ]);
            }

            if ($this->hasCouponColumn('usage_limit') && $coupon->usage_limit !== null && (int) $coupon->usage_limit <= 0) {
                return response()->json(['success' => false, 'message' => 'Kuota kupon sudah habis.'], 422);
            }

            $take = $this->createTake($coupon, (int) $request->user()->id);

            if ($this->hasCouponColumn('usage_limit') && $coupon->usage_limit !== null) {
                $this->saveCoupon($coupon, ['usage_limit' => max(0, (int) $coupon->usage_limit - 1)]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Kupon berhasil diambil.',
                'data' => $take,
                'coupon' => $this->payload($coupon->fresh(), $request->user()->id),
            ]);
        });
    }
}
