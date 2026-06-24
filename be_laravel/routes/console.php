<?php

use App\Models\Order;
use App\Models\SellerBalance;
use App\Models\StoreProfile;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote')->hourly();

Artisan::command('seller-balance:backfill {--order_id=} {--dry-run}', function () {
    $orderId = $this->option('order_id');
    $isDryRun = (bool) $this->option('dry-run');
    $commissionRate = (float) env('MARKETPLACE_COMMISSION_RATE', 10);
    $holdWeekdays = (int) env('SELLER_BALANCE_HOLD_WEEKDAYS', 3);

    $query = Order::with(['items.product.store', 'transaction'])
        ->whereHas('transaction', function ($transactionQuery) {
            $transactionQuery->whereIn('status', [
                'approved',
                'paid',
                'settlement',
                'capture',
                'success',
            ]);
        })
        ->whereNotIn('status', ['canceled', 'cancelled', 'deny', 'expire', 'failed']);

    if ($orderId) {
        $query->where('id', $orderId);
    }

    $orders = $query->get();
    $createdCount = 0;
    $skippedCount = 0;

    $runner = function () use ($orders, $commissionRate, $holdWeekdays, &$createdCount, &$skippedCount) {
        foreach ($orders as $order) {
            $paidAt = $order->transaction?->updated_at ?? $order->updated_at ?? now();
            $availableAt = $paidAt->copy()->addWeekdays($holdWeekdays);

            foreach ($order->items as $item) {
                if (! $item->product) {
                    $skippedCount++;
                    continue;
                }

                if (SellerBalance::where('order_item_id', $item->id)->exists()) {
                    $skippedCount++;
                    continue;
                }

                $grossAmount = (float) $item->price * (int) $item->quantity;
                if ($grossAmount <= 0) {
                    $skippedCount++;
                    continue;
                }

                $product = $item->product;
                $store = $product->store ?: StoreProfile::firstOrCreate(
                    ['user_id' => $product->user_id],
                    [
                        'name' => 'Toko ' . $product->user_id,
                        'slug' => Str::slug('toko-' . $product->user_id),
                        'status' => 'active',
                    ]
                );

                $platformFee = round($grossAmount * ($commissionRate / 100), 2);
                $sellerNetAmount = round($grossAmount - $platformFee, 2);

                SellerBalance::create([
                    'store_id' => $store->id,
                    'order_id' => $order->id,
                    'order_item_id' => $item->id,
                    'gross_amount' => $grossAmount,
                    'platform_fee' => $platformFee,
                    'amount' => $sellerNetAmount,
                    'type' => 'credit',
                    'status' => 'pending',
                    'available_at' => $availableAt,
                ]);

                $createdCount++;
            }
        }
    };

    if ($isDryRun) {
        DB::beginTransaction();
        $runner();
        DB::rollBack();
    } else {
        DB::transaction($runner);
    }

    $prefix = $isDryRun ? '[DRY RUN] ' : '';
    $this->info($prefix . "Order dicek: {$orders->count()}");
    $this->info($prefix . "Saldo dibuat: {$createdCount}");
    $this->info($prefix . "Item dilewati: {$skippedCount}");
})->purpose('Backfill saldo toko dari order yang sudah dibayar');
