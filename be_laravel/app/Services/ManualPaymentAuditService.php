<?php

namespace App\Services;

use App\Models\ManualPaymentAudit;
use App\Models\Transaction;

class ManualPaymentAuditService
{
    public function record(
        ?Transaction $transaction,
        string $action,
        ?string $fromStatus,
        ?string $toStatus,
        ?int $actorId = null,
        ?string $reason = null,
        array $metadata = [],
    ): ManualPaymentAudit {
        $request = app()->bound('request') ? request() : null;

        return ManualPaymentAudit::create([
            'transaction_id' => $transaction?->id,
            'order_id' => $transaction?->order_id,
            'actor_id' => $actorId,
            'action' => $action,
            'from_status' => $fromStatus,
            'to_status' => $toStatus,
            'reason' => $reason,
            'metadata' => $metadata ?: null,
            'ip_address' => $request?->ip(),
            'user_agent' => $request?->userAgent(),
        ]);
    }
}
