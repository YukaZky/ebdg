<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StorePayout;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ApiStorePayoutDetailController extends Controller
{
    public function show(Request $request, int $id)
    {
        $payout = StorePayout::with([
            'seller:id,name,email',
            'processor:id,name,email',
            'items.order.transaction',
            'items.order.items.product:id,user_id,name',
        ])->find($id);

        if (! $payout) {
            return response()->json([
                'success' => false,
                'message' => 'Data pencairan tidak ditemukan.',
            ], 404);
        }

        $userId = (int) $request->user()->id;
        $isOwner = (int) $payout->seller_id === $userId;
        $isSuperAdmin = Schema::hasTable('user_super')
            && DB::table('user_super')->where('user_id', $userId)->exists();

        if (! $isOwner && ! $isSuperAdmin) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke detail pencairan ini.',
            ], 403);
        }

        $sellerId = (int) $payout->seller_id;
        $orders = $payout->items->map(function ($payoutItem) use ($sellerId) {
            $order = $payoutItem->order;
            if (! $order) {
                return [
                    'id' => $payoutItem->order_id,
                    'order_number' => 'ORD-' . str_pad((string) $payoutItem->order_id, 6, '0', STR_PAD_LEFT),
                    'buyer_name' => '-',
                    'status' => '-',
                    'payment_status' => '-',
                    'payment_approved_at' => null,
                    'income_date' => $payoutItem->income_date?->toDateString(),
                    'amount' => (float) $payoutItem->amount,
                    'items' => [],
                ];
            }

            $sellerItems = $order->items
                ->filter(fn ($item) => $item->product && (int) $item->product->user_id === $sellerId)
                ->values();

            return [
                'id' => $order->id,
                'order_number' => 'ORD-' . str_pad((string) $order->id, 6, '0', STR_PAD_LEFT),
                'buyer_name' => $order->name,
                'status' => $order->status,
                'payment_status' => $order->transaction?->status,
                'payment_approved_at' => $order->transaction?->updated_at?->toDateTimeString()
                    ?? $order->transaction?->created_at?->toDateTimeString(),
                'income_date' => $payoutItem->income_date?->toDateString(),
                'amount' => (float) $payoutItem->amount,
                'items' => $sellerItems->map(function ($item) {
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
        })->values();

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $payout->id,
                'seller_id' => $payout->seller_id,
                'seller_name' => $payout->seller?->name,
                'processed_by' => $payout->processor ? [
                    'id' => $payout->processor->id,
                    'name' => $payout->processor->name,
                ] : null,
                'income_date' => $payout->income_date?->toDateString(),
                'payout_date' => $payout->payout_date?->toDateString(),
                'amount' => (float) $payout->amount,
                'description' => $payout->description,
                'status' => $payout->status,
                'bank_provider' => $payout->bank_provider,
                'account_number' => $payout->account_number,
                'account_name' => $payout->account_name,
                'proof_photo' => $payout->proof_photo,
                'proof_url' => $payout->proof_photo
                    ? url('/api/marketplace/payouts/' . $payout->id . '/proof')
                    : null,
                'order_count' => $orders->count(),
                'orders' => $orders->all(),
                'created_at' => $payout->created_at?->toDateTimeString(),
            ],
        ]);
    }
}
