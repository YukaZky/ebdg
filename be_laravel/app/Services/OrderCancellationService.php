<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Product;
use App\Models\ProductVariation;
use App\Models\Transaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;

class OrderCancellationService
{
    public function __construct(private readonly ManualPaymentAuditService $audit) {}

    public function cancelPending(
        Order $order,
        string $stage,
        string $reason,
        ?int $actorId = null,
        string $action = 'order_canceled',
    ): Order {
        return DB::transaction(function () use ($order, $stage, $reason, $actorId, $action) {
            $lockedOrder = Order::with(['items', 'transaction'])
                ->lockForUpdate()
                ->findOrFail($order->id);
            $transaction = $lockedOrder->transaction;

            if ($transaction && in_array(strtolower((string) $transaction->status), ['approved', 'settlement', 'capture'], true)) {
                throw ValidationException::withMessages([
                    'order' => 'Pesanan yang sudah dibayar tidak dapat dibatalkan tanpa proses refund.',
                ]);
            }

            if (in_array(strtolower((string) $lockedOrder->status), ['canceled', 'cancelled'], true)) {
                return $lockedOrder;
            }

            $fromStage = $this->details($transaction)['stage'] ?? $transaction?->status;
            $lockedOrder->status = 'canceled';
            if (Schema::hasColumn('orders', 'canceled_date')) {
                $lockedOrder->canceled_date = now()->toDateString();
            }
            $lockedOrder->save();

            if ($transaction) {
                $details = $this->details($transaction);
                $this->restoreStock($lockedOrder, $details);
                $details['stage'] = $stage;
                $details['cancel_reason'] = $reason;
                $details['canceled_at'] = now()->toIso8601String();
                $details['canceled_by'] = $actorId;
                $transaction->status = 'declined';
                $transaction->payment_details = json_encode($details);
                $transaction->save();
                $this->releaseCoupon($details);
                $this->audit->record($transaction, $action, $fromStage, $stage, $actorId, $reason);
            }

            return $lockedOrder->fresh()->load(['items.product', 'transaction']);
        });
    }

    private function restoreStock(Order $order, array &$details): void
    {
        if (! empty($details['stock_restored_at'])) {
            return;
        }

        foreach ($order->items as $item) {
            $quantity = max(0, (int) $item->quantity);
            if ($quantity === 0) {
                continue;
            }

            $option = is_array($item->option) ? $item->option : json_decode((string) $item->option, true);
            $variationId = is_array($option) ? (int) ($option['variation_id'] ?? 0) : 0;

            if ($variationId > 0) {
                $variation = ProductVariation::lockForUpdate()->find($variationId);
                if ($variation) {
                    $variation->quantity = (int) $variation->quantity + $quantity;
                    $variation->save();

                    $product = Product::lockForUpdate()->find($item->product_id);
                    if ($product) {
                        $product->quantity = (int) ProductVariation::where('product_id', $product->id)->sum('quantity');
                        $product->stock_status = $product->quantity > 0 ? 'instock' : 'outofstock';
                        $product->save();
                    }

                    continue;
                }
            }

            $product = Product::lockForUpdate()->find($item->product_id);
            if ($product) {
                $product->quantity = (int) $product->quantity + $quantity;
                $product->stock_status = 'instock';
                $product->save();
            }
        }

        $details['stock_restored_at'] = now()->toIso8601String();
    }

    private function releaseCoupon(array $details): void
    {
        $coupon = $details['coupon'] ?? null;
        $takeId = is_array($coupon) ? (int) ($coupon['coupon_take_id'] ?? 0) : 0;
        if ($takeId <= 0 || ! Schema::hasTable('cuppon_takes')) {
            return;
        }

        $payload = ['status' => 'take'];
        if (Schema::hasColumn('cuppon_takes', 'updated_at')) {
            $payload['updated_at'] = now();
        }
        DB::table('cuppon_takes')->where('id', $takeId)->where('status', 'used')->update($payload);
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
