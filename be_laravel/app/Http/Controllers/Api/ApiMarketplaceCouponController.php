<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use App\Models\CouponTake;
use App\Models\StoreProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class ApiMarketplaceCouponController extends Controller
{
    private function couponQueryForStore(int $sellerId)
    {
        return Coupon::query()->where('id_user', $sellerId);
    }

    private function activeCouponQueryForStore(int $sellerId)
    {
        return $this->couponQueryForStore($sellerId)
            ->where('status', 'active')
            ->where(function ($query) {
                $query->whereNull('starts_at')->orWhere('starts_at', '<=', now());
            })
            ->where(function ($query) {
                $query->whereNull('expires_at')->orWhere('expires_at', '>=', now());
            });
    }

    private function payload(Coupon $coupon, ?int $userId = null): array
    {
        $take = $userId
            ? CouponTake::where('id_cuppon', $coupon->id)->where('id_user', $userId)->first()
            : null;

        $data = $coupon->toArray();
        $data['take_status'] = $take?->status;
        $data['is_taken'] = (bool) $take;
        $data['taken_count'] = CouponTake::where('id_cuppon', $coupon->id)->count();
        return $data;
    }

    private function validatedPayload(Request $request): array
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:80',
            'type' => ['required', 'string', Rule::in(['fixed', 'discount'])],
            'value' => 'required|numeric|min:0',
            'min_purchase' => 'nullable|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'usage_limit' => 'nullable|integer|min:1',
            'description' => 'nullable|string',
            'status' => ['nullable', 'string', Rule::in(['active', 'inactive'])],
            'starts_at' => 'nullable|date',
            'expires_at' => 'nullable|date',
        ]);

        if ($data['type'] === 'discount' && (float) $data['value'] > 100) {
            throw ValidationException::withMessages(['value' => 'Diskon persen maksimal 100%.']);
        }

        $data['code'] = strtoupper(trim($data['code'] ?? '')) ?: strtoupper('TOKO' . auth()->id() . Str::random(5));
        $data['min_purchase'] = $data['min_purchase'] ?? 0;
        $data['status'] = $data['status'] ?? 'active';
        $data['id_user'] = auth()->id();
        return $data;
    }

    public function index(Request $request)
    {
        $coupons = $this->couponQueryForStore($request->user()->id)
            ->latest()
            ->get()
            ->map(fn (Coupon $coupon) => $this->payload($coupon, $request->user()->id));

        return response()->json(['success' => true, 'data' => $coupons]);
    }

    public function store(Request $request)
    {
        $coupon = Coupon::create($this->validatedPayload($request));
        return response()->json(['success' => true, 'message' => 'Kupon berhasil dibuat.', 'data' => $this->payload($coupon, $request->user()->id)], 201);
    }

    public function show(Request $request, $id)
    {
        $coupon = $this->couponQueryForStore($request->user()->id)->findOrFail($id);
        return response()->json(['success' => true, 'data' => $this->payload($coupon, $request->user()->id)]);
    }

    public function update(Request $request, $id)
    {
        $coupon = $this->couponQueryForStore($request->user()->id)->findOrFail($id);
        $coupon->update($this->validatedPayload($request));
        return response()->json(['success' => true, 'message' => 'Kupon berhasil diperbarui.', 'data' => $this->payload($coupon->fresh(), $request->user()->id)]);
    }

    public function destroy(Request $request, $id)
    {
        $coupon = $this->couponQueryForStore($request->user()->id)->findOrFail($id);
        CouponTake::where('id_cuppon', $coupon->id)->delete();
        $coupon->delete();
        return response()->json(['success' => true, 'message' => 'Kupon berhasil dihapus.']);
    }

    public function storeCoupons(Request $request, $slug)
    {
        $store = StoreProfile::where('slug', $slug)->firstOrFail();
        $userId = optional($request->user())->id;

        $coupons = $this->activeCouponQueryForStore((int) $store->user_id)
            ->latest()
            ->get()
            ->map(fn (Coupon $coupon) => $this->payload($coupon, $userId));

        return response()->json(['success' => true, 'data' => $coupons]);
    }

    public function take(Request $request, $id)
    {
        $coupon = Coupon::where('status', 'active')->findOrFail($id);

        if ((int) $coupon->id_user === (int) $request->user()->id) {
            return response()->json(['success' => false, 'message' => 'Tidak bisa mengambil kupon toko sendiri.'], 422);
        }

        if ($coupon->starts_at && $coupon->starts_at->isFuture()) {
            return response()->json(['success' => false, 'message' => 'Kupon belum aktif.'], 422);
        }

        if ($coupon->expires_at && $coupon->expires_at->isPast()) {
            return response()->json(['success' => false, 'message' => 'Kupon sudah kedaluwarsa.'], 422);
        }

        if ($coupon->usage_limit && CouponTake::where('id_cuppon', $coupon->id)->count() >= (int) $coupon->usage_limit) {
            return response()->json(['success' => false, 'message' => 'Kuota kupon sudah habis.'], 422);
        }

        $take = CouponTake::where('id_cuppon', $coupon->id)
            ->where('id_user', $request->user()->id)
            ->first();

        if ($take && $take->status === 'used') {
            return response()->json(['success' => false, 'message' => 'Kupon sudah pernah digunakan.'], 422);
        }

        $take = CouponTake::updateOrCreate(
            ['id_cuppon' => $coupon->id, 'id_user' => $request->user()->id],
            ['status' => 'take']
        );

        return response()->json([
            'success' => true,
            'message' => 'Kupon berhasil diambil.',
            'data' => $take,
            'coupon' => $this->payload($coupon->fresh(), $request->user()->id),
        ]);
    }
}
