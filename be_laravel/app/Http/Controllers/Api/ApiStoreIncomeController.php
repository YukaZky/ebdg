<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\StoreBankAccount;
use App\Models\StorePayout;
use App\Models\StorePayoutItem;
use App\Models\StoreProfile;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class ApiStoreIncomeController extends Controller
{
    private const PAID_TRANSACTION_STATUSES = ['approved', 'settlement', 'capture'];
    private const CANCELED_ORDER_STATUSES = ['canceled', 'cancelled'];
    private const PAYOUT_WAIT_DAYS = 3;

    private const BANK_PROVIDERS = [
        'BRI', 'BCA', 'BNI', 'MANDIRI', 'BSI', 'PERMATA', 'SEABANK',
        'DANA', 'OVO', 'GOPAY', 'SHOPEEPAY', 'LAINNYA',
    ];

    /**
     * Pendapatan toko berasal dari semua order yang pembayarannya sudah diterima.
     * Status order boleh ordered/paid/packing/processing/shipped/delivered/done/completed.
     * Order canceled dan pembayaran yang belum approved tidak dihitung.
     */
    private function incomeOrdersQuery(int $sellerId, bool $onlyNotPaidOut = false): Builder
    {
        $query = Order::query()
            ->with(['items.product', 'transaction'])
            ->whereNotIn('status', self::CANCELED_ORDER_STATUSES)
            ->whereHas('transaction', function ($transaction) {
                $transaction->whereIn('status', self::PAID_TRANSACTION_STATUSES);
            })
            ->whereHas('items.product', function ($product) use ($sellerId) {
                $product->where('user_id', $sellerId);
            });

        if ($onlyNotPaidOut && Schema::hasTable('store_payout_items')) {
            $query->whereNotIn('orders.id', function ($subQuery) use ($sellerId) {
                $subQuery->select('order_id')
                    ->from('store_payout_items')
                    ->where('seller_id', $sellerId);
            });
        }

        return $query->latest('orders.updated_at');
    }

    private function transactionDetails($transaction): array
    {
        if (! $transaction || ! Schema::hasColumn('transactions', 'payment_details')) {
            return [];
        }

        $raw = $transaction->payment_details ?? null;
        if (is_array($raw)) return $raw;
        if (! is_string($raw) || trim($raw) === '') return [];

        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : [];
    }

    private function sellerDiscount(Order $order, int $sellerId): float
    {
        $details = $this->transactionDetails($order->transaction);
        $coupon = $details['coupon'] ?? null;
        if (! is_array($coupon)) return 0;

        $couponSellerId = (int) ($coupon['seller_id'] ?? 0);
        if ($couponSellerId !== $sellerId) return 0;

        return max(0, (float) ($coupon['amount'] ?? 0));
    }

    private function sellerItems(Order $order, int $sellerId)
    {
        return $order->items
            ->filter(fn ($item) => $item->product && (int) $item->product->user_id === $sellerId)
            ->values();
    }

    private function sellerOrderAmount(Order $order, int $sellerId): float
    {
        $subtotal = $this->sellerItems($order, $sellerId)
            ->sum(fn ($item) => (float) $item->price * (int) $item->quantity);

        return max(0, round($subtotal - $this->sellerDiscount($order, $sellerId), 2));
    }

    /**
     * Belum ada kolom approved_at di transactions, sehingga sesuai kebutuhan saat ini
     * updated_at transaksi dipakai sebagai waktu pembayaran approved.
     */
    private function paymentApprovedAt(Order $order)
    {
        return $order->transaction?->updated_at ?? $order->transaction?->created_at;
    }

    private function incomeDate(Order $order): string
    {
        $approvedAt = $this->paymentApprovedAt($order);
        return $approvedAt?->toDateString()
            ?? $order->updated_at?->toDateString()
            ?? $order->created_at?->toDateString()
            ?? now()->toDateString();
    }

    private function payoutAvailableAt(Order $order)
    {
        $approvedAt = $this->paymentApprovedAt($order);
        return $approvedAt?->copy()->addDays(self::PAYOUT_WAIT_DAYS);
    }

    private function isPayoutEligible(Order $order): bool
    {
        $availableAt = $this->payoutAvailableAt($order);
        return $availableAt !== null && now()->greaterThanOrEqualTo($availableAt);
    }

    private function orderStatusLabel(string $status): string
    {
        return match (strtolower($status)) {
            'ordered', 'paid' => 'Dibayar',
            'packing', 'processing' => 'Dikemas',
            'shipped' => 'Dikirim',
            'delivered' => 'Sampai',
            'done', 'completed', 'complete', 'selesai' => 'Selesai',
            'canceled', 'cancelled' => 'Dibatalkan',
            default => ucfirst($status),
        };
    }

    private function orderPayload(Order $order, int $sellerId, ?StorePayoutItem $payoutItem = null): array
    {
        $items = $this->sellerItems($order, $sellerId);
        $amount = $this->sellerOrderAmount($order, $sellerId);
        $approvedAt = $this->paymentApprovedAt($order);
        $availableAt = $this->payoutAvailableAt($order);
        $isPaidOut = $payoutItem !== null;
        $eligible = ! $isPaidOut && $this->isPayoutEligible($order);

        $remainingHours = 0;
        if (! $isPaidOut && $availableAt && now()->lessThan($availableAt)) {
            $remainingSeconds = now()->diffInSeconds($availableAt, false);
            $remainingHours = $remainingSeconds > 0 ? (int) ceil($remainingSeconds / 3600) : 0;
        }

        return [
            'id' => $order->id,
            'order_number' => 'ORD-' . str_pad((string) $order->id, 6, '0', STR_PAD_LEFT),
            'buyer_name' => $order->name,
            'income_date' => $this->incomeDate($order),
            'payment_status' => $order->transaction?->status,
            'payment_approved_at' => $approvedAt?->toDateTimeString(),
            'payout_available_at' => $availableAt?->toDateTimeString(),
            'payout_wait_days' => self::PAYOUT_WAIT_DAYS,
            'payout_eligible' => $eligible,
            'remaining_hours' => $remainingHours,
            'amount' => $amount,
            'status' => $order->status,
            'status_label' => $this->orderStatusLabel((string) $order->status),
            'payout_status' => $isPaidOut ? 'sudah_dicairkan' : 'belum_dicairkan',
            'payout_id' => $payoutItem?->payout_id,
            'items' => $items->map(function ($item) {
                return [
                    'id' => $item->id,
                    'product_id' => $item->product_id,
                    'product_name' => $item->product?->name,
                    'quantity' => (int) $item->quantity,
                    'price' => (float) $item->price,
                    'line_total' => round((float) $item->price * (int) $item->quantity, 2),
                ];
            })->all(),
        ];
    }

    private function dailyPayload($orders, int $sellerId, array $payoutItemsByOrder = []): array
    {
        return $orders
            ->groupBy(fn (Order $order) => $this->incomeDate($order))
            ->map(function ($dayOrders, $date) use ($sellerId, $payoutItemsByOrder) {
                $payloadOrders = $dayOrders->map(function (Order $order) use ($sellerId, $payoutItemsByOrder) {
                    $payoutItem = $payoutItemsByOrder[$order->id] ?? null;
                    return $this->orderPayload($order, $sellerId, $payoutItem);
                })->values();

                $total = round((float) $payloadOrders->sum('amount'), 2);
                $paidTotal = round((float) $payloadOrders
                    ->where('payout_status', 'sudah_dicairkan')
                    ->sum('amount'), 2);
                $availableTotal = round($total - $paidTotal, 2);
                $eligibleTotal = round((float) $payloadOrders
                    ->where('payout_eligible', true)
                    ->sum('amount'), 2);

                return [
                    'date' => $date,
                    'total' => $total,
                    'available_total' => $availableTotal,
                    'eligible_payout_total' => $eligibleTotal,
                    'paid_total' => $paidTotal,
                    'order_count' => $payloadOrders->count(),
                    'eligible_order_count' => $payloadOrders->where('payout_eligible', true)->count(),
                    'status' => $availableTotal <= 0 ? 'sudah_dicairkan' : 'belum_dicairkan',
                    'orders' => $payloadOrders->all(),
                ];
            })
            ->sortKeysDesc()
            ->values()
            ->all();
    }

    private function bankAccountsForUser(int $userId)
    {
        return StoreBankAccount::where('user_id', $userId)
            ->orderBy('slot')
            ->get();
    }

    private function payoutPayload(StorePayout $payout): array
    {
        return [
            'id' => $payout->id,
            'income_date' => $payout->income_date?->toDateString(),
            'payout_date' => $payout->payout_date?->toDateString(),
            'amount' => (float) $payout->amount,
            'description' => $payout->description,
            'proof_photo' => $payout->proof_photo,
            'proof_url' => $payout->proof_photo
                ? url('/api/marketplace/payouts/' . $payout->id . '/proof')
                : null,
            'bank_provider' => $payout->bank_provider,
            'account_number' => $payout->account_number,
            'account_name' => $payout->account_name,
            'status' => $payout->status,
            'processed_by' => $payout->processor ? [
                'id' => $payout->processor->id,
                'name' => $payout->processor->name,
            ] : null,
            'order_ids' => $payout->items->pluck('order_id')->values()->all(),
            'order_count' => $payout->items->count(),
            'created_at' => $payout->created_at?->toDateTimeString(),
        ];
    }

    private function isSuperAdmin(Request $request): bool
    {
        return Schema::hasTable('user_super')
            && DB::table('user_super')->where('user_id', $request->user()->id)->exists();
    }

    public function sellerIncome(Request $request)
    {
        $sellerId = (int) $request->user()->id;
        $orders = $this->incomeOrdersQuery($sellerId, true)->get();
        $daily = $this->dailyPayload($orders, $sellerId);
        $store = StoreProfile::where('user_id', $sellerId)->first();

        $availableBalance = round((float) $orders
            ->sum(fn (Order $order) => $this->sellerOrderAmount($order, $sellerId)), 2);
        $eligibleBalance = round((float) $orders
            ->filter(fn (Order $order) => $this->isPayoutEligible($order))
            ->sum(fn (Order $order) => $this->sellerOrderAmount($order, $sellerId)), 2);

        return response()->json([
            'success' => true,
            'data' => [
                'seller_id' => $sellerId,
                'store_name' => $store?->name ?? $request->user()->name,
                'available_balance' => $availableBalance,
                'available_order_count' => $orders->count(),
                'eligible_payout_balance' => $eligibleBalance,
                'eligible_order_count' => $orders->filter(fn (Order $order) => $this->isPayoutEligible($order))->count(),
                'payout_wait_days' => self::PAYOUT_WAIT_DAYS,
                'total_paid_out' => round((float) StorePayout::where('seller_id', $sellerId)
                    ->where('status', 'paid')
                    ->sum('amount'), 2),
                'daily' => $daily,
                'orders' => $orders->map(fn (Order $order) => $this->orderPayload($order, $sellerId))->values()->all(),
                'bank_accounts' => $this->bankAccountsForUser($sellerId),
            ],
        ]);
    }

    public function sellerIncomeByDate(Request $request, string $date)
    {
        if (! preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            return response()->json(['success' => false, 'message' => 'Format tanggal tidak valid.'], 422);
        }

        $sellerId = (int) $request->user()->id;
        $orders = $this->incomeOrdersQuery($sellerId, true)
            ->get()
            ->filter(fn (Order $order) => $this->incomeDate($order) === $date)
            ->values();

        return response()->json([
            'success' => true,
            'data' => [
                'date' => $date,
                'total' => round((float) $orders->sum(fn (Order $order) => $this->sellerOrderAmount($order, $sellerId)), 2),
                'orders' => $orders->map(fn (Order $order) => $this->orderPayload($order, $sellerId))->all(),
            ],
        ]);
    }

    public function sellerPayouts(Request $request)
    {
        $payouts = StorePayout::with(['processor:id,name', 'items'])
            ->where('seller_id', $request->user()->id)
            ->latest('payout_date')
            ->latest('id')
            ->get()
            ->map(fn (StorePayout $payout) => $this->payoutPayload($payout));

        return response()->json(['success' => true, 'data' => $payouts]);
    }

    public function bankAccounts(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $this->bankAccountsForUser((int) $request->user()->id),
            'providers' => self::BANK_PROVIDERS,
        ]);
    }

    public function saveBankAccounts(Request $request)
    {
        $request->validate([
            'accounts' => 'required|array|min:1|max:2',
            'accounts.*.slot' => 'required|integer|in:1,2',
            'accounts.*.provider' => 'required|string|in:' . implode(',', self::BANK_PROVIDERS),
            'accounts.*.account_number' => 'required|string|max:100',
            'accounts.*.account_name' => 'nullable|string|max:255',
        ]);

        $sellerId = (int) $request->user()->id;
        $accounts = collect($request->input('accounts'))
            ->unique('slot')
            ->values();

        if ($accounts->count() !== count($request->input('accounts'))) {
            return response()->json(['success' => false, 'message' => 'Slot rekening tidak boleh duplikat.'], 422);
        }

        DB::transaction(function () use ($sellerId, $accounts) {
            $slots = $accounts->pluck('slot')->map(fn ($slot) => (int) $slot)->all();
            StoreBankAccount::where('user_id', $sellerId)->whereNotIn('slot', $slots)->delete();

            foreach ($accounts as $account) {
                StoreBankAccount::updateOrCreate(
                    ['user_id' => $sellerId, 'slot' => (int) $account['slot']],
                    [
                        'provider' => strtoupper(trim((string) $account['provider'])),
                        'account_number' => trim((string) $account['account_number']),
                        'account_name' => isset($account['account_name'])
                            ? trim((string) $account['account_name'])
                            : null,
                    ]
                );
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Rekening toko berhasil disimpan.',
            'data' => $this->bankAccountsForUser($sellerId),
        ]);
    }

    public function superAdminStores(Request $request)
    {
        if (! $this->isSuperAdmin($request)) {
            return response()->json(['success' => false, 'message' => 'Akses khusus Super Admin.'], 403);
        }

        $stores = StoreProfile::with('user:id,name,email')
            ->orderBy('name')
            ->get()
            ->map(function (StoreProfile $store) {
                $sellerId = (int) $store->user_id;
                $orders = $this->incomeOrdersQuery($sellerId, true)->get();
                $eligibleOrders = $orders->filter(fn (Order $order) => $this->isPayoutEligible($order));

                return [
                    'store_id' => $store->id,
                    'seller_id' => $sellerId,
                    'store_name' => $store->name,
                    'owner_name' => $store->user?->name,
                    'owner_email' => $store->user?->email,
                    'available_balance' => round((float) $orders->sum(fn (Order $order) => $this->sellerOrderAmount($order, $sellerId)), 2),
                    'available_order_count' => $orders->count(),
                    'eligible_payout_balance' => round((float) $eligibleOrders->sum(fn (Order $order) => $this->sellerOrderAmount($order, $sellerId)), 2),
                    'eligible_order_count' => $eligibleOrders->count(),
                ];
            })
            ->values();

        return response()->json(['success' => true, 'data' => $stores]);
    }

    public function superAdminSellerDetail(Request $request, int $sellerId)
    {
        if (! $this->isSuperAdmin($request)) {
            return response()->json(['success' => false, 'message' => 'Akses khusus Super Admin.'], 403);
        }

        $seller = User::find($sellerId);
        if (! $seller) {
            return response()->json(['success' => false, 'message' => 'Pemilik toko tidak ditemukan.'], 404);
        }

        $store = StoreProfile::where('user_id', $sellerId)->first();
        $orders = $this->incomeOrdersQuery($sellerId, true)->get();
        $eligibleOrders = $orders->filter(fn (Order $order) => $this->isPayoutEligible($order));
        $daily = $this->dailyPayload($orders, $sellerId);

        return response()->json([
            'success' => true,
            'data' => [
                'seller_id' => $sellerId,
                'store_name' => $store?->name ?? $seller->name,
                'owner_name' => $seller->name,
                'available_balance' => round((float) $orders->sum(fn (Order $order) => $this->sellerOrderAmount($order, $sellerId)), 2),
                'available_order_count' => $orders->count(),
                'eligible_payout_balance' => round((float) $eligibleOrders->sum(fn (Order $order) => $this->sellerOrderAmount($order, $sellerId)), 2),
                'eligible_order_count' => $eligibleOrders->count(),
                'payout_wait_days' => self::PAYOUT_WAIT_DAYS,
                'daily' => $daily,
                'orders' => $orders->map(fn (Order $order) => $this->orderPayload($order, $sellerId))->values()->all(),
                'bank_accounts' => $this->bankAccountsForUser($sellerId),
            ],
        ]);
    }

    public function processPayout(Request $request, int $sellerId)
    {
        if (! $this->isSuperAdmin($request)) {
            return response()->json(['success' => false, 'message' => 'Akses khusus Super Admin.'], 403);
        }

        $request->validate([
            'order_ids' => 'required|array|min:1',
            'order_ids.*' => 'required|integer|distinct',
            'description' => 'nullable|string|max:2000',
            'proof_photo' => 'required|image|mimes:jpg,jpeg,png,webp|max:5120',
            'bank_account_id' => 'required|integer',
        ]);

        $seller = User::find($sellerId);
        if (! $seller) {
            return response()->json(['success' => false, 'message' => 'Pemilik toko tidak ditemukan.'], 404);
        }

        $bank = StoreBankAccount::where('user_id', $sellerId)
            ->where('id', $request->bank_account_id)
            ->first();

        if (! $bank) {
            return response()->json([
                'success' => false,
                'message' => 'Rekening pencairan toko tidak valid. Minta pemilik toko mengatur rekening terlebih dahulu.',
            ], 422);
        }

        $orderIds = collect($request->input('order_ids'))
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values();

        $selectedOrders = $this->incomeOrdersQuery($sellerId, true)
            ->whereIn('orders.id', $orderIds->all())
            ->get();

        if ($selectedOrders->count() !== $orderIds->count()) {
            return response()->json([
                'success' => false,
                'message' => 'Sebagian order tidak valid, belum dibayar, dibatalkan, atau sudah pernah dicairkan.',
            ], 422);
        }

        $notEligible = $selectedOrders
            ->filter(fn (Order $order) => ! $this->isPayoutEligible($order));

        if ($notEligible->isNotEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'Ada order yang belum melewati masa tunggu 3 x 24 jam sejak pembayaran approved.',
                'order_ids' => $notEligible->pluck('id')->values(),
            ], 422);
        }

        $amount = round((float) $selectedOrders
            ->sum(fn (Order $order) => $this->sellerOrderAmount($order, $sellerId)), 2);

        if ($amount <= 0) {
            return response()->json(['success' => false, 'message' => 'Nominal pencairan tidak valid.'], 422);
        }

        $directory = storage_path('app/private/payouts');
        if (! is_dir($directory)) mkdir($directory, 0775, true);
        $extension = strtolower($request->file('proof_photo')->getClientOriginalExtension() ?: 'jpg');
        $proofName = now()->format('YmdHis') . '_seller_' . $sellerId . '_' . Str::random(8) . '.' . $extension;
        $request->file('proof_photo')->move($directory, $proofName);

        try {
            $payout = DB::transaction(function () use ($request, $sellerId, $seller, $bank, $orderIds, $proofName) {
                $orders = $this->incomeOrdersQuery($sellerId, true)
                    ->whereIn('orders.id', $orderIds->all())
                    ->lockForUpdate()
                    ->get();

                if ($orders->count() !== $orderIds->count()) {
                    throw ValidationException::withMessages([
                        'order_ids' => ['Sebagian order sudah dicairkan atau tidak lagi memenuhi syarat.'],
                    ]);
                }

                $notEligible = $orders->filter(fn (Order $order) => ! $this->isPayoutEligible($order));
                if ($notEligible->isNotEmpty()) {
                    throw ValidationException::withMessages([
                        'order_ids' => ['Ada order yang belum melewati masa tunggu 3 x 24 jam.'],
                    ]);
                }

                $amount = round((float) $orders
                    ->sum(fn (Order $order) => $this->sellerOrderAmount($order, $sellerId)), 2);

                $dates = $orders->map(fn (Order $order) => $this->incomeDate($order))->unique()->values();
                $incomeDate = $dates->count() === 1 ? $dates->first() : null;
                $description = trim((string) $request->description);
                if ($description === '') {
                    $description = 'Pencairan pendapatan toko ' . $seller->name . ' untuk ' . $orders->count() . ' order.';
                }

                $payout = StorePayout::create([
                    'seller_id' => $sellerId,
                    'processed_by' => $request->user()->id,
                    'income_date' => $incomeDate,
                    'payout_date' => now()->toDateString(),
                    'amount' => $amount,
                    'description' => $description,
                    'proof_photo' => $proofName,
                    'bank_provider' => $bank->provider,
                    'account_number' => $bank->account_number,
                    'account_name' => $bank->account_name,
                    'status' => 'paid',
                ]);

                foreach ($orders as $order) {
                    StorePayoutItem::create([
                        'payout_id' => $payout->id,
                        'seller_id' => $sellerId,
                        'order_id' => $order->id,
                        'income_date' => $this->incomeDate($order),
                        'amount' => $this->sellerOrderAmount($order, $sellerId),
                    ]);
                }

                return $payout->fresh(['processor:id,name', 'items']);
            });
        } catch (\Throwable $e) {
            $proofPath = $directory . DIRECTORY_SEPARATOR . $proofName;
            if (is_file($proofPath)) @unlink($proofPath);
            throw $e;
        }

        return response()->json([
            'success' => true,
            'message' => 'Pencairan berhasil. Order yang dipilih sudah dikurangi dari saldo belum dicairkan.',
            'data' => $this->payoutPayload($payout),
        ]);
    }
}
