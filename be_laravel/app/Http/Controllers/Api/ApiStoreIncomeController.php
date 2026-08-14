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

class ApiStoreIncomeController extends Controller
{
    private const PAID_TRANSACTION_STATUSES = ['approved', 'settlement', 'capture'];
    private const COMPLETED_ORDER_STATUSES = ['done', 'completed', 'complete', 'selesai'];
    private const BANK_PROVIDERS = [
        'BRI', 'BCA', 'BNI', 'MANDIRI', 'BSI', 'PERMATA', 'SEABANK',
        'DANA', 'OVO', 'GOPAY', 'SHOPEEPAY', 'LAINNYA',
    ];

    private function eligibleOrdersQuery(int $sellerId, bool $onlyAvailable = false): Builder
    {
        $query = Order::query()
            ->with(['items.product', 'transaction'])
            ->whereIn('status', self::COMPLETED_ORDER_STATUSES)
            ->whereHas('transaction', function ($transaction) {
                $transaction->whereIn('status', self::PAID_TRANSACTION_STATUSES);
            })
            ->whereHas('items.product', function ($product) use ($sellerId) {
                $product->where('user_id', $sellerId);
            });

        if ($onlyAvailable && Schema::hasTable('store_payout_items')) {
            $query->whereNotIn('orders.id', function ($subQuery) use ($sellerId) {
                $subQuery->select('order_id')
                    ->from('store_payout_items')
                    ->where('seller_id', $sellerId);
            });
        }

        return $query->latest('updated_at');
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

    private function incomeDate(Order $order): string
    {
        if ($order->completed_at) return $order->completed_at->toDateString();
        if ($order->updated_at) return $order->updated_at->toDateString();
        if ($order->delivered_date) return (string) $order->delivered_date;
        return $order->created_at?->toDateString() ?? now()->toDateString();
    }

    private function orderPayload(Order $order, int $sellerId, ?StorePayoutItem $payoutItem = null): array
    {
        $items = $this->sellerItems($order, $sellerId);
        $amount = $this->sellerOrderAmount($order, $sellerId);

        return [
            'id' => $order->id,
            'order_number' => 'ORD-' . str_pad((string) $order->id, 6, '0', STR_PAD_LEFT),
            'buyer_name' => $order->name,
            'income_date' => $this->incomeDate($order),
            'completed_at' => $order->completed_at?->toDateTimeString(),
            'amount' => $amount,
            'status' => $order->status,
            'payout_status' => $payoutItem ? 'sudah_dicairkan' : 'belum_dicairkan',
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

                return [
                    'date' => $date,
                    'total' => $total,
                    'available_total' => $availableTotal,
                    'paid_total' => $paidTotal,
                    'order_count' => $payloadOrders->count(),
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
                ? url('/uploads/payouts/' . ltrim($payout->proof_photo, '/'))
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
        $orders = $this->eligibleOrdersQuery($sellerId, true)->get();
        $daily = $this->dailyPayload($orders, $sellerId);
        $store = StoreProfile::where('user_id', $sellerId)->first();

        return response()->json([
            'success' => true,
            'data' => [
                'seller_id' => $sellerId,
                'store_name' => $store?->name ?? $request->user()->name,
                'available_balance' => round((float) collect($daily)->sum('available_total'), 2),
                'available_order_count' => $orders->count(),
                'total_paid_out' => round((float) StorePayout::where('seller_id', $sellerId)
                    ->where('status', 'paid')
                    ->sum('amount'), 2),
                'daily' => $daily,
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
        $orders = $this->eligibleOrdersQuery($sellerId, true)
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
                $orders = $this->eligibleOrdersQuery($sellerId, true)->get();
                $balance = round((float) $orders->sum(fn (Order $order) => $this->sellerOrderAmount($order, $sellerId)), 2);

                return [
                    'store_id' => $store->id,
                    'seller_id' => $sellerId,
                    'store_name' => $store->name,
                    'owner_name' => $store->user?->name,
                    'owner_email' => $store->user?->email,
                    'available_balance' => $balance,
                    'available_order_count' => $orders->count(),
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
        if (! $seller) return response()->json(['success' => false, 'message' => 'Pemilik toko tidak ditemukan.'], 404);

        $store = StoreProfile::where('user_id', $sellerId)->first();
        $orders = $this->eligibleOrdersQuery($sellerId)->get();
        $payoutItems = StorePayoutItem::with('payout')
            ->where('seller_id', $sellerId)
            ->get()
            ->keyBy('order_id')
            ->all();
        $daily = $this->dailyPayload($orders, $sellerId, $payoutItems);

        return response()->json([
            'success' => true,
            'data' => [
                'seller_id' => $sellerId,
                'store_name' => $store?->name ?? $seller->name,
                'owner_name' => $seller->name,
                'available_balance' => round((float) collect($daily)->sum('available_total'), 2),
                'daily' => $daily,
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
            'income_date' => 'required|date_format:Y-m-d',
            'description' => 'nullable|string|max:2000',
            'proof_photo' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
            'bank_account_id' => 'nullable|integer',
        ]);

        $seller = User::find($sellerId);
        if (! $seller) return response()->json(['success' => false, 'message' => 'Pemilik toko tidak ditemukan.'], 404);

        $bankQuery = StoreBankAccount::where('user_id', $sellerId);
        if ($request->filled('bank_account_id')) {
            $bankQuery->where('id', $request->bank_account_id);
        } else {
            $bankQuery->where('slot', 1);
        }
        $bank = $bankQuery->first();

        if (! $bank) {
            return response()->json([
                'success' => false,
                'message' => 'Toko belum memiliki rekening pencairan. Minta pemilik toko mengisi Setting Rekening Toko.',
            ], 422);
        }

        $incomeDate = (string) $request->income_date;
        $orders = $this->eligibleOrdersQuery($sellerId, true)
            ->get()
            ->filter(fn (Order $order) => $this->incomeDate($order) === $incomeDate)
            ->values();

        if ($orders->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada saldo yang belum dicairkan pada tanggal tersebut.',
            ], 422);
        }

        $amount = round((float) $orders->sum(fn (Order $order) => $this->sellerOrderAmount($order, $sellerId)), 2);
        if ($amount <= 0) {
            return response()->json(['success' => false, 'message' => 'Nominal pencairan tidak valid.'], 422);
        }

        $proofName = null;
        if ($request->hasFile('proof_photo')) {
            $directory = public_path('uploads/payouts');
            if (! is_dir($directory)) mkdir($directory, 0775, true);
            $extension = strtolower($request->file('proof_photo')->getClientOriginalExtension() ?: 'jpg');
            $proofName = now()->format('YmdHis') . '_seller_' . $sellerId . '_' . Str::random(8) . '.' . $extension;
            $request->file('proof_photo')->move($directory, $proofName);
        }

        $payout = DB::transaction(function () use ($request, $sellerId, $incomeDate, $amount, $bank, $orders, $proofName) {
            $payout = StorePayout::create([
                'seller_id' => $sellerId,
                'processed_by' => $request->user()->id,
                'income_date' => $incomeDate,
                'payout_date' => now()->toDateString(),
                'amount' => $amount,
                'description' => $request->description,
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
                    'income_date' => $incomeDate,
                    'amount' => $this->sellerOrderAmount($order, $sellerId),
                ]);
            }

            return $payout->fresh(['processor:id,name', 'items']);
        });

        return response()->json([
            'success' => true,
            'message' => 'Pencairan pendapatan berhasil dicatat dan saldo order terkait sudah ditandai dicairkan.',
            'data' => $this->payoutPayload($payout),
        ]);
    }
}
