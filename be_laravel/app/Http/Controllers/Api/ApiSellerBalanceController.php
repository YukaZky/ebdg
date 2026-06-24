<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SellerBalance;
use App\Models\SellerWithdrawal;
use App\Models\StoreProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ApiSellerBalanceController extends Controller
{
    private function store(Request $request): StoreProfile
    {
        return StoreProfile::firstOrCreate(
            ['user_id' => $request->user()->id],
            [
                'name' => $request->user()->name . ' Store',
                'slug' => Str::slug($request->user()->name . '-' . $request->user()->id),
                'status' => 'active',
            ]
        );
    }

    private function release(int $storeId): void
    {
        SellerBalance::where('store_id', $storeId)
            ->where('status', 'pending')
            ->whereNotNull('available_at')
            ->where('available_at', '<=', now())
            ->update(['status' => 'available', 'updated_at' => now()]);
    }

    private function activeWithdrawals(int $storeId): float
    {
        return (float) SellerWithdrawal::where('store_id', $storeId)
            ->whereIn('status', ['pending', 'approved', 'processing'])
            ->sum('amount');
    }

    private function availableBalance(int $storeId): float
    {
        $available = (float) SellerBalance::where('store_id', $storeId)
            ->where('status', 'available')
            ->sum('amount');

        return max($available - $this->activeWithdrawals($storeId), 0);
    }

    public function index(Request $request)
    {
        $store = $this->store($request);
        $this->release($store->id);

        $balances = SellerBalance::with(['order:id,status,created_at', 'orderItem.product:id,name,image,user_id'])
            ->where('store_id', $store->id)
            ->latest()
            ->limit(100)
            ->get()
            ->map(fn (SellerBalance $balance) => [
                'id' => $balance->id,
                'order_id' => $balance->order_id,
                'order_item_id' => $balance->order_item_id,
                'product_name' => $balance->orderItem?->product?->name ?? 'Produk',
                'gross_amount' => $balance->gross_amount,
                'platform_fee' => $balance->platform_fee,
                'amount' => $balance->amount,
                'status' => $balance->status,
                'status_label' => match ($balance->status) {
                    'pending' => 'Pending 3 Hari Kerja',
                    'available' => 'Bisa Ditarik',
                    'withdrawn' => 'Sudah Ditarik',
                    'cancelled', 'canceled' => 'Dibatalkan',
                    default => ucfirst((string) $balance->status),
                },
                'available_at' => $balance->available_at?->toDateTimeString(),
                'created_at' => $balance->created_at?->toDateTimeString(),
                'order_status' => $balance->order?->status,
            ])->values();

        $withdrawals = SellerWithdrawal::where('store_id', $store->id)
            ->latest()
            ->limit(100)
            ->get()
            ->map(fn (SellerWithdrawal $withdrawal) => [
                'id' => $withdrawal->id,
                'amount' => $withdrawal->amount,
                'bank_name' => $withdrawal->bank_name,
                'bank_account_number' => $withdrawal->bank_account_number,
                'bank_account_name' => $withdrawal->bank_account_name,
                'status' => $withdrawal->status,
                'status_label' => match ($withdrawal->status) {
                    'pending' => 'Menunggu Persetujuan',
                    'approved' => 'Disetujui',
                    'processing' => 'Diproses',
                    'paid' => 'Sudah Dibayar',
                    'failed' => 'Gagal',
                    'rejected' => 'Ditolak',
                    default => ucfirst((string) $withdrawal->status),
                },
                'note' => $withdrawal->note,
                'paid_at' => $withdrawal->paid_at?->toDateTimeString(),
                'created_at' => $withdrawal->created_at?->toDateTimeString(),
            ])->values();

        $pending = (float) SellerBalance::where('store_id', $store->id)->where('status', 'pending')->sum('amount');
        $available = $this->availableBalance($store->id);
        $requested = $this->activeWithdrawals($store->id);
        $withdrawn = (float) SellerWithdrawal::where('store_id', $store->id)->where('status', 'paid')->sum('amount');
        $total = (float) SellerBalance::where('store_id', $store->id)->whereNotIn('status', ['cancelled', 'canceled'])->sum('amount');

        return response()->json(['success' => true, 'data' => [
            'store' => $store,
            'bank_account' => [
                'bank_name' => $store->bank_name,
                'bank_account_number' => $store->bank_account_number,
                'bank_account_name' => $store->bank_account_name,
            ],
            'is_sandbox' => ! (bool) config('midtrans.is_production'),
            'summary' => [
                'total_income' => $total,
                'pending_balance' => $pending,
                'available_balance' => $available,
                'requested_balance' => $requested,
                'withdrawn_balance' => $withdrawn,
            ],
            'balances' => $balances,
            'withdrawals' => $withdrawals,
        ]]);
    }

    public function withdraw(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:10000',
            'bank_name' => 'nullable|string|max:100',
            'bank_account_number' => 'nullable|string|max:50',
            'bank_account_name' => 'nullable|string|max:150',
        ]);

        $store = $this->store($request);
        $this->release($store->id);

        $bankName = trim((string) ($request->bank_name ?: $store->bank_name));
        $bankNumber = trim((string) ($request->bank_account_number ?: $store->bank_account_number));
        $bankOwner = trim((string) ($request->bank_account_name ?: $store->bank_account_name));

        if ($bankName === '' || $bankNumber === '' || $bankOwner === '') {
            return response()->json(['success' => false, 'message' => 'Lengkapi data rekening toko sebelum tarik saldo.'], 422);
        }

        $amount = round((float) $request->amount, 2);

        $withdrawal = DB::transaction(function () use ($store, $amount, $bankName, $bankNumber, $bankOwner) {
            if ($amount > $this->availableBalance($store->id)) {
                abort(response()->json(['success' => false, 'message' => 'Saldo tersedia tidak mencukupi untuk ditarik.'], 422));
            }

            $store->forceFill([
                'bank_name' => $bankName,
                'bank_account_number' => $bankNumber,
                'bank_account_name' => $bankOwner,
            ])->save();

            return SellerWithdrawal::create([
                'store_id' => $store->id,
                'amount' => $amount,
                'bank_name' => $bankName,
                'bank_account_number' => $bankNumber,
                'bank_account_name' => $bankOwner,
                'status' => 'pending',
            ]);
        });

        return response()->json(['success' => true, 'message' => 'Request tarik saldo berhasil dibuat.', 'data' => $withdrawal], 201);
    }
}
