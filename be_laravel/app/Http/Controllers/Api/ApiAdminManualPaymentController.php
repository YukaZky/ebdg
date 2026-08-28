<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ManualPaymentAudit;
use App\Models\Order;
use App\Services\ManualPaymentService;
use App\Services\OrderCancellationService;
use App\Services\SuperAdminService;
use Illuminate\Http\Request;

class ApiAdminManualPaymentController extends Controller
{
    public function __construct(
        private readonly ManualPaymentService $payments,
        private readonly OrderCancellationService $cancellation,
        private readonly SuperAdminService $superAdmins,
    ) {}

    public function index(Request $request)
    {
        $this->authorizeSuperAdmin($request);
        $this->payments->expireDuePayments();

        $query = Order::query()
            ->with(['user:id,name,email,phone', 'transaction.latestConfirmation.reviewer'])
            ->withCount('items')
            ->whereHas('transaction', fn ($transaction) => $transaction
                ->where('mode', 'transfer')
                ->whereNotNull('manual_payment_account_id'));

        if ($request->filled('search')) {
            $search = trim((string) $request->input('search'));
            $numericId = (int) preg_replace('/\D/', '', $search);
            $query->where(function ($builder) use ($search, $numericId) {
                if ($numericId > 0) {
                    $builder->where('id', $numericId);
                }
                $builder->orWhere('name', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        $filter = strtolower((string) $request->input('status', 'all'));
        if ($filter === 'approved') {
            $query->whereHas('transaction', fn ($transaction) => $transaction->where('status', 'approved'));
        } elseif (in_array($filter, ['canceled', 'expired'], true)) {
            $query->whereHas('transaction', function ($transaction) use ($filter) {
                $transaction->where('status', 'declined');
                if ($filter === 'expired') {
                    $transaction->where('payment_details', 'like', '%"stage":"expired"%');
                } else {
                    $transaction->where('payment_details', 'not like', '%"stage":"expired"%');
                }
            });
        } elseif (in_array($filter, ['proof_submitted', 'proof_rejected', 'waiting_payment'], true)) {
            $query->whereHas('transaction', function ($transaction) use ($filter) {
                $transaction->where('status', 'pending')
                    ->where('payment_details', 'like', '%"stage":"'.$filter.'"%');
            });
        }

        $paginator = $query
            ->latest('orders.updated_at')
            ->paginate(min(max((int) $request->input('per_page', 20), 1), 100));

        $paginator->getCollection()->transform(fn (Order $order) => $this->listPayload($order));

        return response()->json(['success' => true, 'data' => $paginator]);
    }

    public function show(Request $request, Order $order)
    {
        $this->authorizeSuperAdmin($request);
        $this->payments->expireIfDue($order->load('transaction'));

        $order->load([
            'user:id,name,email,phone',
            'items.product.user:id,name,email',
            'transaction.latestConfirmation.reviewer',
            'transaction.confirmations' => fn ($query) => $query->with('reviewer')->latest('submitted_at'),
        ]);
        if (! $order->transaction
            || $order->transaction->mode !== 'transfer'
            || ! is_array($order->transaction->manual_payment_account_snapshot)) {
            return response()->json(['success' => false, 'message' => 'Transaksi pembayaran manual tidak ditemukan.'], 404);
        }

        $transaction = $order->transaction;
        $audits = ManualPaymentAudit::with('actor:id,name,email')
            ->where('transaction_id', $transaction->id)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'order' => $order->toArray(),
                'order_number' => $this->orderNumber($order),
                'payment_state' => $this->payments->state($transaction),
                'payment_info' => $this->payments->paymentInfo($order, $transaction),
                'latest_confirmation' => $this->payments->confirmationPayload($transaction->latestConfirmation),
                'confirmations' => $transaction->confirmations
                    ->map(fn ($confirmation) => $this->payments->confirmationPayload($confirmation))
                    ->values(),
                'audits' => $audits,
            ],
        ]);
    }

    public function approve(Request $request, Order $order)
    {
        $this->authorizeSuperAdmin($request);
        $updated = $this->payments->approve($order, $request->user()->id);

        return response()->json([
            'success' => true,
            'message' => 'Pembayaran telah diterima.',
            'data' => $updated,
        ]);
    }

    public function reject(Request $request, Order $order)
    {
        $this->authorizeSuperAdmin($request);
        $validated = $request->validate([
            'reason' => 'required|string|min:5|max:1000',
            'extend_deadline' => 'sometimes|boolean',
        ]);
        $updated = $this->payments->reject(
            $order,
            $request->user()->id,
            $validated['reason'],
            $request->boolean('extend_deadline', true),
        );

        return response()->json([
            'success' => true,
            'message' => 'Bukti ditolak. User dapat mengirim bukti baru.',
            'data' => $updated,
        ]);
    }

    public function cancel(Request $request, Order $order)
    {
        $this->authorizeSuperAdmin($request);
        $validated = $request->validate(['reason' => 'required|string|min:5|max:1000']);
        $updated = $this->cancellation->cancelPending(
            $order,
            ManualPaymentService::CANCELED,
            $validated['reason'],
            $request->user()->id,
            'order_canceled_by_admin',
        );

        return response()->json([
            'success' => true,
            'message' => 'Pesanan dibatalkan dan stok dikembalikan.',
            'data' => $updated,
        ]);
    }

    private function listPayload(Order $order): array
    {
        $transaction = $order->transaction;
        $snapshot = is_array($transaction?->manual_payment_account_snapshot)
            ? $transaction->manual_payment_account_snapshot
            : [];

        return [
            'id' => $order->id,
            'order_number' => $this->orderNumber($order),
            'buyer_name' => $order->name,
            'buyer_phone' => $order->phone,
            'total' => (float) $order->total,
            'order_status' => $order->status,
            'transaction_status' => $transaction?->status,
            'payment_state' => $this->payments->state($transaction),
            'payment_expires_at' => $transaction?->payment_expires_at?->toIso8601String(),
            'payment_approved_at' => $transaction?->payment_approved_at?->toIso8601String(),
            'destination_bank' => $snapshot['bank_name'] ?? null,
            'destination_account' => isset($snapshot['account_number'])
                ? '•••• '.substr((string) $snapshot['account_number'], -4)
                : null,
            'items_count' => $order->items_count,
            'latest_confirmation' => $this->payments->confirmationPayload($transaction?->latestConfirmation, false),
            'created_at' => $order->created_at?->toIso8601String(),
        ];
    }

    private function orderNumber(Order $order): string
    {
        return 'ORDER-'.str_pad((string) $order->id, 6, '0', STR_PAD_LEFT);
    }

    private function authorizeSuperAdmin(Request $request): void
    {
        abort_unless($this->superAdmins->check($request->user()), 403, 'Menu ini khusus Super Admin.');
    }
}
