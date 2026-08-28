<?php

namespace App\Services;

use App\Models\ManualPaymentAccount;
use App\Models\ManualPaymentConfirmation;
use App\Models\Order;
use App\Models\Transaction;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class ManualPaymentService
{
    public const WAITING_PAYMENT = 'waiting_payment';

    public const PROOF_SUBMITTED = 'proof_submitted';

    public const PROOF_REJECTED = 'proof_rejected';

    public const APPROVED = 'payment_approved';

    public const EXPIRED = 'expired';

    public const CANCELED = 'canceled';

    public function __construct(
        private readonly ManualPaymentAuditService $audit,
        private readonly OrderCancellationService $cancellation,
    ) {}

    public function primaryAccount(): ?ManualPaymentAccount
    {
        return ManualPaymentAccount::query()
            ->where('is_active', true)
            ->orderByDesc('is_primary')
            ->orderByDesc('updated_at')
            ->first();
    }

    public function createInstruction(
        Order $order,
        string $checkoutSignature,
        ?string $requestedPaymentType = null,
        ?string $requestedBank = null,
    ): array {
        $account = $this->primaryAccount();
        if (! $account) {
            throw ValidationException::withMessages([
                'payment_account' => 'Rekening/VA tujuan belum diatur oleh Super Admin.',
            ]);
        }

        return DB::transaction(function () use ($order, $account, $checkoutSignature, $requestedPaymentType, $requestedBank) {
            $lockedOrder = Order::with(['transaction', 'items.product'])
                ->lockForUpdate()
                ->findOrFail($order->id);
            $transaction = $lockedOrder->transaction ?: new Transaction;
            $details = $this->details($transaction);
            $currentStage = $details['stage'] ?? null;

            if (in_array(strtolower((string) $transaction->status), ['approved', 'settlement', 'capture'], true)) {
                return $this->instructionResponse($lockedOrder, $transaction, 'Pembayaran sudah diterima.');
            }

            if ($currentStage === self::PROOF_SUBMITTED) {
                return $this->instructionResponse($lockedOrder, $transaction, 'Bukti pembayaran sedang menunggu verifikasi.');
            }

            $sameCheckout = ($details['checkout_signature'] ?? null) === $checkoutSignature;
            $hasManualSnapshot = is_array($transaction->manual_payment_account_snapshot);
            $hasManualInstruction = ($details['manual_payment'] ?? false) === true
                && is_array($details['payment_info'] ?? null);
            $deadlineActive = $transaction->payment_expires_at === null || now()->lt($transaction->payment_expires_at);

            if ($sameCheckout && $hasManualSnapshot && $hasManualInstruction && $deadlineActive && $transaction->status === 'pending') {
                return $this->instructionResponse($lockedOrder, $transaction, 'Instruksi pembayaran aktif digunakan kembali.');
            }

            $fromStage = $currentStage ?? 'waiting_payment_method';
            $snapshot = $this->accountSnapshot($account);
            $expiresAt = now()->addHours(24);
            $history = $details['superseded_attempts'] ?? [];
            $coupon = $details['coupon'] ?? null;
            $shippingBreakdown = $details['shipping_breakdown'] ?? $lockedOrder->shipping_breakdown;

            $transaction->user_id = $lockedOrder->user_id;
            $transaction->order_id = $lockedOrder->id;
            $transaction->manual_payment_account_id = $account->id;
            $transaction->manual_payment_account_snapshot = $snapshot;
            $transaction->mode = 'transfer';
            $transaction->status = 'pending';
            $transaction->payment_token = null;
            $transaction->payment_url = null;
            $transaction->payment_expires_at = $expiresAt;
            $transaction->payment_approved_at = null;
            $transaction->payment_approved_by = null;
            $transaction->payment_details = json_encode([
                'stage' => self::WAITING_PAYMENT,
                'checkout_signature' => $checkoutSignature,
                'gross_amount' => (float) $lockedOrder->total,
                'payment_type' => 'manual_transfer',
                'requested_payment_type' => $requestedPaymentType,
                'requested_bank' => $requestedBank,
                'manual_payment' => true,
                'payment_info' => $this->paymentInfoFromValues($lockedOrder, $snapshot, $expiresAt, 'pending'),
                'coupon' => $coupon,
                'shipping_breakdown' => $shippingBreakdown,
                'superseded_attempts' => $history,
            ]);
            $transaction->save();

            $this->audit->record(
                $transaction,
                'payment_instruction_created',
                $fromStage,
                self::WAITING_PAYMENT,
                $lockedOrder->user_id,
                null,
                ['manual_payment_account_id' => $account->id, 'expires_at' => $expiresAt->toIso8601String()],
            );

            return $this->instructionResponse(
                $lockedOrder->fresh()->load(['transaction', 'items.product']),
                $transaction->fresh(),
                'Instruksi transfer manual berhasil dibuat.',
            );
        });
    }

    public function ensureInstructionForLegacyOrder(Order $order): bool
    {
        $order->loadMissing('transaction');
        $transaction = $order->transaction;
        if (! $transaction
            || $transaction->status !== 'pending'
            || is_array($transaction->manual_payment_account_snapshot)
            || in_array(strtolower((string) $order->status), ['canceled', 'cancelled'], true)) {
            return false;
        }

        $details = $this->details($transaction);
        $this->createInstruction(
            $order,
            (string) ($details['checkout_signature'] ?? 'legacy-order-'.$order->id),
            isset($details['payment_type']) ? (string) $details['payment_type'] : null,
            isset($details['bank']) ? (string) $details['bank'] : null,
        );

        return true;
    }

    public function submitProof(Order $order, array $data, UploadedFile $proof): ManualPaymentConfirmation
    {
        $this->expireIfDue($order);
        $path = null;

        try {
            return DB::transaction(function () use ($order, $data, $proof, &$path) {
                $lockedOrder = Order::with(['transaction.latestConfirmation'])->lockForUpdate()->findOrFail($order->id);
                $transaction = $lockedOrder->transaction;
                if (! $transaction || ! is_array($transaction->manual_payment_account_snapshot)) {
                    throw ValidationException::withMessages(['payment' => 'Instruksi pembayaran belum dibuat.']);
                }
                if (in_array(strtolower((string) $lockedOrder->status), ['canceled', 'cancelled'], true) || $transaction->status === 'declined') {
                    throw ValidationException::withMessages(['payment' => 'Pesanan sudah dibatalkan atau kedaluwarsa.']);
                }
                if (in_array($transaction->status, ['approved', 'settlement', 'capture'], true)) {
                    throw ValidationException::withMessages(['payment' => 'Pembayaran sudah disetujui.']);
                }
                if ($transaction->latestConfirmation?->status === 'submitted') {
                    throw ValidationException::withMessages(['payment' => 'Bukti pembayaran sebelumnya masih menunggu verifikasi.']);
                }
                if ($transaction->payment_expires_at && now()->greaterThanOrEqualTo($transaction->payment_expires_at)) {
                    throw ValidationException::withMessages(['payment' => 'Batas waktu pembayaran sudah berakhir.']);
                }

                $amount = round((float) $data['transferred_amount'], 2);
                if (abs($amount - (float) $lockedOrder->total) > 0.01) {
                    throw ValidationException::withMessages([
                        'transferred_amount' => 'Nominal transfer harus sama dengan total order.',
                    ]);
                }

                $extension = strtolower($proof->getClientOriginalExtension() ?: 'jpg');
                $extension = in_array($extension, ['jpg', 'jpeg', 'png', 'webp'], true) ? $extension : 'jpg';
                $filename = Str::uuid().'.'.$extension;
                $path = $proof->storeAs('manual-payment-proofs', $filename, 'local');
                if (! $path) {
                    throw ValidationException::withMessages(['proof' => 'Bukti pembayaran gagal disimpan.']);
                }

                $details = $this->details($transaction);
                $fromStage = $details['stage'] ?? self::WAITING_PAYMENT;
                $confirmation = ManualPaymentConfirmation::create([
                    'transaction_id' => $transaction->id,
                    'order_id' => $lockedOrder->id,
                    'user_id' => $lockedOrder->user_id,
                    'sender_name' => trim((string) $data['sender_name']),
                    'sender_bank' => trim((string) $data['sender_bank']),
                    'sender_account_number' => trim((string) $data['sender_account_number']),
                    'transferred_amount' => $amount,
                    'transferred_at' => $data['transferred_at'] ?? null,
                    'proof_path' => $path,
                    'note' => isset($data['note']) ? trim((string) $data['note']) : null,
                    'status' => 'submitted',
                    'submitted_at' => now(),
                ]);

                $details['stage'] = self::PROOF_SUBMITTED;
                $details['proof_submitted_at'] = now()->toIso8601String();
                $details['latest_confirmation_id'] = $confirmation->id;
                unset($details['rejection_reason']);
                $transaction->status = 'pending';
                $transaction->payment_details = json_encode($details);
                $transaction->save();

                $this->audit->record(
                    $transaction,
                    'payment_proof_submitted',
                    $fromStage,
                    self::PROOF_SUBMITTED,
                    $lockedOrder->user_id,
                    null,
                    ['confirmation_id' => $confirmation->id, 'transferred_amount' => $amount],
                );

                return $confirmation->fresh(['user', 'reviewer']);
            });
        } catch (\Throwable $e) {
            if ($path) {
                Storage::disk('local')->delete($path);
            }
            throw $e;
        }
    }

    public function approve(Order $order, int $adminId): Order
    {
        return DB::transaction(function () use ($order, $adminId) {
            $lockedOrder = Order::with(['transaction.latestConfirmation'])->lockForUpdate()->findOrFail($order->id);
            $transaction = $lockedOrder->transaction;
            $confirmation = $transaction?->latestConfirmation;
            if (! $transaction || ! $confirmation || $confirmation->status !== 'submitted') {
                throw ValidationException::withMessages(['payment' => 'Tidak ada bukti pembayaran yang menunggu verifikasi.']);
            }
            if (in_array(strtolower((string) $lockedOrder->status), ['canceled', 'cancelled'], true)) {
                throw ValidationException::withMessages(['payment' => 'Pesanan sudah dibatalkan.']);
            }

            $details = $this->details($transaction);
            $fromStage = $details['stage'] ?? self::PROOF_SUBMITTED;
            $confirmation->update([
                'status' => 'approved',
                'reviewed_by' => $adminId,
                'reviewed_at' => now(),
                'rejection_reason' => null,
            ]);
            $transaction->status = 'approved';
            $transaction->payment_approved_at = now();
            $transaction->payment_approved_by = $adminId;
            $details['stage'] = self::APPROVED;
            $details['approved_at'] = now()->toIso8601String();
            $details['approved_by'] = $adminId;
            $details['latest_confirmation_id'] = $confirmation->id;
            $transaction->payment_details = json_encode($details);
            $transaction->save();
            $this->markCouponUsed($details);

            $this->audit->record(
                $transaction,
                'payment_approved',
                $fromStage,
                self::APPROVED,
                $adminId,
                null,
                ['confirmation_id' => $confirmation->id],
            );

            return $lockedOrder->fresh()->load(['items.product', 'transaction.latestConfirmation']);
        });
    }

    public function reject(Order $order, int $adminId, string $reason, bool $extendDeadline = true): Order
    {
        return DB::transaction(function () use ($order, $adminId, $reason, $extendDeadline) {
            $lockedOrder = Order::with(['transaction.latestConfirmation'])->lockForUpdate()->findOrFail($order->id);
            $transaction = $lockedOrder->transaction;
            $confirmation = $transaction?->latestConfirmation;
            if (! $transaction || ! $confirmation || $confirmation->status !== 'submitted') {
                throw ValidationException::withMessages(['payment' => 'Tidak ada bukti pembayaran yang dapat ditolak.']);
            }
            if (in_array($transaction->status, ['approved', 'settlement', 'capture'], true)) {
                throw ValidationException::withMessages(['payment' => 'Pembayaran yang sudah disetujui tidak dapat ditolak.']);
            }

            $details = $this->details($transaction);
            $fromStage = $details['stage'] ?? self::PROOF_SUBMITTED;
            $confirmation->update([
                'status' => 'rejected',
                'rejection_reason' => $reason,
                'reviewed_by' => $adminId,
                'reviewed_at' => now(),
            ]);
            if ($extendDeadline && (! $transaction->payment_expires_at || now()->greaterThanOrEqualTo($transaction->payment_expires_at))) {
                $transaction->payment_expires_at = now()->addHours(24);
            }
            $details['stage'] = self::PROOF_REJECTED;
            $details['rejection_reason'] = $reason;
            $details['rejected_at'] = now()->toIso8601String();
            $details['rejected_by'] = $adminId;
            $details['payment_info'] = $this->paymentInfo($lockedOrder, $transaction);
            $transaction->status = 'pending';
            $transaction->payment_details = json_encode($details);
            $transaction->save();

            $this->audit->record(
                $transaction,
                'payment_proof_rejected',
                $fromStage,
                self::PROOF_REJECTED,
                $adminId,
                $reason,
                ['confirmation_id' => $confirmation->id, 'deadline_extended' => $extendDeadline],
            );

            return $lockedOrder->fresh()->load(['items.product', 'transaction.latestConfirmation']);
        });
    }

    public function expireIfDue(Order $order): bool
    {
        $transaction = $order->transaction ?: $order->load('transaction.latestConfirmation')->transaction;
        if (! $transaction || $transaction->status !== 'pending' || ! $transaction->payment_expires_at) {
            return false;
        }

        $stage = $this->details($transaction)['stage'] ?? null;
        if ($stage === self::PROOF_SUBMITTED || now()->lt($transaction->payment_expires_at)) {
            return false;
        }

        $this->cancellation->cancelPending(
            $order,
            self::EXPIRED,
            'Batas pembayaran 24 jam telah berakhir.',
            null,
            'payment_expired',
        );

        return true;
    }

    public function expireDuePayments(): int
    {
        $count = 0;
        Transaction::query()
            ->where('status', 'pending')
            ->whereNotNull('payment_expires_at')
            ->where('payment_expires_at', '<=', now())
            ->with('order')
            ->chunkById(100, function ($transactions) use (&$count) {
                foreach ($transactions as $transaction) {
                    if ($transaction->order && $this->expireIfDue($transaction->order)) {
                        $count++;
                    }
                }
            });

        return $count;
    }

    public function state(?Transaction $transaction): string
    {
        if (! $transaction) {
            return self::WAITING_PAYMENT;
        }
        if (in_array($transaction->status, ['approved', 'settlement', 'capture'], true)) {
            return self::APPROVED;
        }
        if ($transaction->status === 'declined') {
            return ($this->details($transaction)['stage'] ?? null) === self::EXPIRED ? self::EXPIRED : self::CANCELED;
        }

        return (string) ($this->details($transaction)['stage'] ?? self::WAITING_PAYMENT);
    }

    public function paymentInfo(Order $order, Transaction $transaction): array
    {
        $snapshot = is_array($transaction->manual_payment_account_snapshot)
            ? $transaction->manual_payment_account_snapshot
            : [];

        return $this->paymentInfoFromValues(
            $order,
            $snapshot,
            $transaction->payment_expires_at,
            $transaction->status,
        );
    }

    public function confirmationPayload(?ManualPaymentConfirmation $confirmation, bool $includeFullAccount = true): ?array
    {
        if (! $confirmation) {
            return null;
        }

        $accountNumber = (string) $confirmation->sender_account_number;
        if (! $includeFullAccount && strlen($accountNumber) > 4) {
            $accountNumber = str_repeat('•', max(4, strlen($accountNumber) - 4)).substr($accountNumber, -4);
        }

        return [
            'id' => $confirmation->id,
            'sender_name' => $confirmation->sender_name,
            'sender_bank' => $confirmation->sender_bank,
            'sender_account_number' => $accountNumber,
            'transferred_amount' => (float) $confirmation->transferred_amount,
            'transferred_at' => $confirmation->transferred_at?->toIso8601String(),
            'note' => $confirmation->note,
            'status' => $confirmation->status,
            'rejection_reason' => $confirmation->rejection_reason,
            'submitted_at' => $confirmation->submitted_at?->toIso8601String(),
            'reviewed_at' => $confirmation->reviewed_at?->toIso8601String(),
            'reviewed_by' => $confirmation->reviewer ? [
                'id' => $confirmation->reviewer->id,
                'name' => $confirmation->reviewer->name,
            ] : null,
            'proof_url' => url('/api/manual-payment-confirmations/'.$confirmation->id.'/proof'),
        ];
    }

    private function instructionResponse(Order $order, Transaction $transaction, string $message): array
    {
        $transaction->loadMissing('latestConfirmation.reviewer');
        $paymentInfo = $this->paymentInfo($order, $transaction);

        return [
            'success' => true,
            'message' => $message,
            'payment_info' => $paymentInfo,
            'manual_payment' => true,
            'payment_state' => $this->state($transaction),
            'latest_confirmation' => $this->confirmationPayload($transaction->latestConfirmation),
            'order' => $order->fresh()->load(['items.product', 'transaction'])->toArray(),
        ];
    }

    private function paymentInfoFromValues(Order $order, array $snapshot, $expiresAt, string $status): array
    {
        return [
            'va_number' => $snapshot['account_number'] ?? null,
            'account_number' => $snapshot['account_number'] ?? null,
            'account_name' => $snapshot['account_name'] ?? null,
            'account_type' => $snapshot['account_type'] ?? 'virtual_account',
            'bank_name' => $snapshot['bank_name'] ?? null,
            'label' => $snapshot['label'] ?? null,
            'instructions' => $snapshot['instructions'] ?? null,
            'expiry_time' => $expiresAt?->toIso8601String(),
            'transaction_status' => $status,
            'payment_type' => 'manual_transfer',
            'total' => (float) $order->total,
            'order_id' => $order->id,
        ];
    }

    private function accountSnapshot(ManualPaymentAccount $account): array
    {
        return [
            'id' => $account->id,
            'account_type' => $account->account_type,
            'bank_name' => $account->bank_name,
            'account_number' => $account->account_number,
            'account_name' => $account->account_name,
            'label' => $account->label,
            'instructions' => $account->instructions,
            'snapshotted_at' => now()->toIso8601String(),
        ];
    }

    private function markCouponUsed(array $details): void
    {
        $coupon = $details['coupon'] ?? null;
        $takeId = is_array($coupon) ? (int) ($coupon['coupon_take_id'] ?? 0) : 0;
        if ($takeId <= 0 || ! Schema::hasTable('cuppon_takes')) {
            return;
        }

        $payload = ['status' => 'used'];
        if (Schema::hasColumn('cuppon_takes', 'updated_at')) {
            $payload['updated_at'] = now();
        }
        DB::table('cuppon_takes')->where('id', $takeId)->where('status', 'take')->update($payload);
    }

    private function details(?Transaction $transaction): array
    {
        if (! $transaction || ! is_string($transaction->payment_details) || trim($transaction->payment_details) === '') {
            return [];
        }

        $decoded = json_decode($transaction->payment_details, true);

        return is_array($decoded) ? $decoded : [];
    }
}
