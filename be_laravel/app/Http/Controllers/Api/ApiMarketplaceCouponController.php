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

    private function putIfColumn(array &$payload, string $column, $value): void
    {
        if ($this->hasCouponColumn($column)) {
            $payload[$column] = $value;
        }
    }

    private function orderedCoupons($query)
    {
        return $this->hasCouponColumn('created_at') ? $query->latest() : $query->orderByDesc('id');
    }

    private function saveCouponModel(Coupon $coupon, array $attributes): Coupon
    {
        if (! $this->hasCouponColumn('created_at') && ! $this->hasCouponColumn('updated_at')) {
            $coupon->timestamps = false;
        }

        $coupon->forceFill($attributes);
        $coupon->save();

        return $coupon;
    }

    private function couponQueryForStore(int $sellerId)
    {
        $query = Coupon::query();

        if ($this->hasCouponColumn('id_user')) {
            $query->where(function ($query) use ($sellerId) {
                $query->where('id_user', $sellerId)->orWhereNull('id_user');
            });
        } elseif ($this->hasCouponColumn('user_id')) {
            $query->where(function ($query) use ($sellerId) {
                $query->where('user_id', $sellerId)->orWhereNull('user_id');
            });
        }

        return $query;
    }

    private function activeCouponQueryForStore(int $sellerId)
    {
        $query = $this->couponQueryForStore($sellerId);

        if ($this->hasCouponColumn('status')) {
            $query->where(function ($query) {
                $query->where('status', 'active')->orWhere('status', 1)->orWhereNull('status');
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
        } elseif ($this->hasCouponColumn('expiry_date')) {
            $query->where(function ($query) {
                $query->whereNull('expiry_date')->orWhere('expiry_date', '>=', now()->toDateString());
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
        $rawType = $data['type'] ?? ($data['coupon_type'] ?? 'fixed');
        $data['name'] = $data['name'] ?? ($data['title'] ?? ($data['coupon_name'] ?? ($data['code'] ?? ($data['coupon_code'] ?? 'Kupon Toko'))));
        $data['code'] = $data['code'] ?? ($data['coupon_code'] ?? ('KUPON' . $coupon->id));
        $data['type'] = $rawType === 'percent' ? 'discount' : $rawType;
        $data['value'] = $data['value'] ?? ($data['amount'] ?? ($data['discount'] ?? ($data['discount_amount'] ?? 0)));
        $data['min_purchase'] = $data['min_purchase'] ?? ($data['cart_value'] ?? ($data['minimum_purchase'] ?? ($data['min_order'] ?? 0)));
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
            'type' => ['required', 'string', Rule::in(['fixed', 'discount', 'percent'])],
            'value' => 'required|numeric|min:0',
            'min_purchase' => 'nullable|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'usage_limit' => 'nullable|integer|min:1',
            'description' => 'nullable|string',
            'status' => ['nullable', 'string', Rule::in(['active', 'inactive'])],
            'starts_at' => 'nullable|date',
            'expires_at' => 'nullable|date',
        ]);

        if (in_array($data['type'], ['discount', 'percent'], true) && (float) $data['value'] > 100) {
            throw ValidationException::withMessages(['value' => 'Diskon persen maksimal 100%.']);
        }

        $data['code'] = strtoupper(trim($data['code'] ?? '')) ?: strtoupper('TOKO' . auth()->id() . Str::random(5));
        $data['min_purchase'] = $data['min_purchase'] ?? 0;
        $data['status'] = $data['status'] ?? 'active';

        return $data;
    }

    private function couponAttributes(array $data): array
    {
        $payload = [];
        $storedType = in_array($data['type'], ['discount', 'percent'], true) ? 'percent' : 'fixed';

        $this->putIfColumn($payload, 'id_user', auth()->id());
        $this->putIfColumn($payload, 'user_id', auth()->id());
        $this->putIfColumn($payload, 'name', $data['name']);
        $this->putIfColumn($payload, 'title', $data['name']);
        $this->putIfColumn($payload, 'coupon_name', $data['name']);
        $this->putIfColumn($payload, 'code', $data['code']);
        $this->putIfColumn($payload, 'coupon_code', $data['code']);
        $this->putIfColumn($payload, 'type', $storedType);
        $this->putIfColumn($payload, 'coupon_type', $data['type']);
        $this->putIfColumn($payload, 'value', $data['value']);
        $this->putIfColumn($payload, 'amount', $data['value']);
        $this->putIfColumn($payload, 'discount', $data['value']);
        $this->putIfColumn($payload, 'discount_amount', $data['value']);
        $this->putIfColumn($payload, 'min_purchase', $data['min_purchase']);
        $this->putIfColumn($payload, 'cart_value', $data['min_purchase']);
        $this->putIfColumn($payload, 'minimum_purchase', $data['min_purchase']);
        $this->putIfColumn($payload, 'min_order', $data['min_purchase']);
        $this->putIfColumn($payload, 'max_discount', $data['max_discount'] ?? null);
        $this->putIfColumn($payload, 'usage_limit', $data['usage_limit'] ?? null);
        $this->putIfColumn($payload, 'description', $data['description'] ?? null);
        $this->putIfColumn($payload, 'starts_at', $data['starts_at'] ?? null);
        $this->putIfColumn($payload, 'expires_at', $data['expires_at'] ?? null);
        $this->putIfColumn($payload, 'expiry_date', $data['expires_at'] ?? now()->addYear()->toDateString());

        $status = ($data['status'] ?? 'active') === 'active' ? 'active' : 'inactive';
        $this->putIfColumn($payload, 'status', $status);
        $this->putIfColumn($payload, 'is_active', $status === 'active');

        return $payload;
    }

    public function index(Request $request)
    {
        $coupons = $this->orderedCoupons($this->couponQueryForStore($request->user()->id))
            ->get()
            ->map(fn (Coupon $coupon) => $this->payload($coupon, $request->user()->id));

        return response()->json(['success' => true, 'data' => $coupons]);
    }

    public function store(Request $request)
    {
        $coupon = $this->saveCouponModel(new Coupon(), $this->couponAttributes($this->validatedPayload($request)));
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
        $coupon = $this->saveCouponModel($coupon, $this->couponAttributes($this->validatedPayload($request)));
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

        $coupons = $this->orderedCoupons($this->activeCouponQueryForStore((int) $store->user_id))
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
                $query->where('status', 'active')->orWhere('status', 1)->orWhereNull('status');
            }))
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
        } elseif ($this->hasCouponColumn('expiry_date') && $coupon->expiry_date && $coupon->expiry_date < now()->toDateString()) {
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
