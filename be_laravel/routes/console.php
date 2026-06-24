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

$createSellerBalanceForOrderItem = function ($order, $item, float $commissionRate, int $holdWeekdays, &$createdCount, &$skippedCount) {
    if (! $item->product || ! $item->product->user_id) {
        $skippedCount++;
        return;
    }

    if (SellerBalance::where('order_item_id', $item->id)->exists()) {
        $skippedCount++;
        return;
    }

    $grossAmount = (float) $item->price * (int) $item->quantity;
    if ($grossAmount <= 0) {
        $skippedCount++;
        return;
    }

    // Di project ini kepemilikan toko/barang berasal dari products.user_id.
    // StoreProfile hanya profil toko untuk user pemilik produk tersebut.
    $productOwnerId = (int) $item->product->user_id;
    $store = StoreProfile::firstOrCreate(
        ['user_id' => $productOwnerId],
        [
            'name' => 'Toko ' . $productOwnerId,
            'slug' => Str::slug('toko-' . $productOwnerId),
            'status' => 'active',
        ]
    );

    $paidAt = $order->transaction?->updated_at ?? $order->updated_at ?? now();
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
        'available_at' => $paidAt->copy()->addWeekdays($holdWeekdays),
    ]);

    $createdCount++;
};

Artisan::command('seller-balance:backfill {--order_id=} {--store_user_id=} {--dry-run}', function () use ($createSellerBalanceForOrderItem) {
    $orderId = $this->option('order_id');
    $storeUserId = $this->option('store_user_id');
    $isDryRun = (bool) $this->option('dry-run');
    $commissionRate = (float) env('MARKETPLACE_COMMISSION_RATE', 10);
    $holdWeekdays = (int) env('SELLER_BALANCE_HOLD_WEEKDAYS', 3);

    $query = Order::with(['items.product', 'transaction'])
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

    if ($storeUserId) {
        $query->whereHas('items.product', fn ($productQuery) => $productQuery->where('user_id', $storeUserId));
    }

    $orders = $query->get();
    $createdCount = 0;
    $skippedCount = 0;

    $runner = function () use ($orders, $storeUserId, $commissionRate, $holdWeekdays, $createSellerBalanceForOrderItem, &$createdCount, &$skippedCount) {
        foreach ($orders as $order) {
            foreach ($order->items as $item) {
                if ($storeUserId && (! $item->product || (int) $item->product->user_id !== (int) $storeUserId)) {
                    $skippedCount++;
                    continue;
                }

                $createSellerBalanceForOrderItem($order, $item, $commissionRate, $holdWeekdays, $createdCount, $skippedCount);
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
})->purpose('Backfill saldo toko dari order yang sudah dibayar berdasarkan products.user_id');

Artisan::command('seller-balance:repair-store {--dry-run}', function () {
    $isDryRun = (bool) $this->option('dry-run');
    $fixedCount = 0;
    $skippedCount = 0;

    $balances = SellerBalance::with('orderItem.product')->get();

    $runner = function () use ($balances, &$fixedCount, &$skippedCount) {
        foreach ($balances as $balance) {
            $product = $balance->orderItem?->product;

            if (! $product || ! $product->user_id) {
                $skippedCount++;
                continue;
            }

            $productOwnerId = (int) $product->user_id;
            $correctStore = StoreProfile::firstOrCreate(
                ['user_id' => $productOwnerId],
                [
                    'name' => 'Toko ' . $productOwnerId,
                    'slug' => Str::slug('toko-' . $productOwnerId),
                    'status' => 'active',
                ]
            );

            if ((int) $balance->store_id === (int) $correctStore->id) {
                $skippedCount++;
                continue;
            }

            $balance->store_id = $correctStore->id;
            $balance->save();
            $fixedCount++;
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
    $this->info($prefix . "Saldo diperbaiki store_id-nya: {$fixedCount}");
    $this->info($prefix . "Saldo dilewati: {$skippedCount}");
})->purpose('Perbaiki seller_balances.store_id agar mengikuti products.user_id');
