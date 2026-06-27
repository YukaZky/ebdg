<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use App\Models\CouponTake;
use App\Models\StoreProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class ApiMarketplaceCouponController extends Controller
{
    private function hasCouponColumn(string $column): bool
    {
        return Schema::hasTable('coupons') && Schema::hasColumn('coupons', $column);
    }

    private function hasTakeTable(): bool
    {
        return Schema::hasTable('cuppon_takes');
    }

    private function couponQueryForStore(int $sellerId)
    {
        $query = Coupon::query();

        if ($this->hasCouponColumn('id_user')) {
            $query->where(function ($query) use ($sellerId) {
                $query->where('id_user', $sellerId)->orWhereNull('id_user');
            });
        }

        return $query;
    }

    private function activeCouponQueryForStore(int $sellerId)
    {
        $query = $this->couponQueryForStore($sellerId);

        if ($this->hasCouponColumn('status')) {
            $query->where(function ($query) {
                $query->where('status', 'active')->orWhereNull('status');
            });
        }

        if ($this->hasCouponColumn('starts_at')) {
            $query->where(function ($query) {
                $query->whereNull('starts_at')->orWhere('starts_at', '<=', now());
            });
        }

        if ($this->hasCouponColumn('expires_at')) {
            $query->where(function ($query) {
                $query->whereNull('expires_at')->orWhere('expires_at', '>=', now());
            });
        }

        return $query;
    }

    private function payload(Coupon $coupon, ?int $userId = null): array
    {
        $take = null;
        $takenCount = 0;

        if ($this->hasTakeTable()) {
            $take = $userId
                ? CouponTake::where('id_cuppon', $coupon->id)->where('id_user', $userId)->first()
                : null;
            $takenCount = CouponTake::where('id_cuppon', $coupon->id)->count();
        }

        $data = $coupon->toArray();
        $data['name'] = $data['name'] ?? ($data['title'] ?? ($data['code'] ?? 'Kupon Toko'));
        $data['code'] = $data['code'] ?? ('KUPON' . $coupon->id);
        $data['type'] = $data['type'] ?? 'fixed';
        $data['value'] = $data['value'] ?? ($data['amount'] ?? ($data['discount'] ?? 0));
        $data['min_purchase'] = $data['min_purchase'] ?? ($data['minimum_purchase'] ?? 0);
        $data['max_discount'] = $data['max_discount'] ?? null;
        $data['status'] = $data['status'] ?? 'active';
        $data['take_status'] = $take?->status;
        $data['is_taken'] = (bool) $take;
        $data['taken_count'] = $takenCount;
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

        if ($this->hasCouponColumn('id_user')) {
            $data['id_user'] = auth()->id();
        }

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
        if ($this->hasTakeTable()) {
            CouponTake::where('id_cuppon', $coupon->id)->delete();
        }
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
        if (! $this->hasTakeTable()) {
            return response()->json(['success' => false, 'message' => 'Tabel cuppon_takes belum dimigrate.'], 422);
        }

        $coupon = Coupon::query()
            ->when($this->hasCouponColumn('status'), fn ($query) => $query->where(function ($query) {
                $query->where('status', 'active')->orWhereNull('status');
            }))
            ->findOrFail($id);

        if ($this->hasCouponColumn('id_user') && (int) $coupon->id_user === (int) $request->user()->id) {
            return response()->json(['success' => false, 'message' => 'Tidak bisa mengambil kupon toko sendiri.'], 422);
        }

        if ($this->hasCouponColumn('starts_at') && $coupon->starts_at && $coupon->starts_at->isFuture()) {
            return response()->json(['success' => false, 'message' => 'Kupon belum aktif.'], 422);
        }

        if ($this->hasCouponColumn('expires_at') && $coupon->expires_at && $coupon->expires_at->isPast()) {
            return response()->json(['success' => false, 'message' => 'Kupon sudah kedaluwarsa.'], 422);
        }

        if ($this->hasCouponColumn('usage_limit') && $coupon->usage_limit && CouponTake::where('id_cuppon', $coupon->id)->count() >= (int) $coupon->usage_limit) {
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
