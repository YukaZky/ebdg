<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;

class ApiOrderCancelController extends Controller
{
    public function cancel($id)
    {
        $order = Order::with('items.product', 'transaction')->where('user_id', Auth::id())->find($id);

        if (! $order) {
            return response()->json(['success' => false, 'message' => 'Pesanan tidak ditemukan.'], 404);
        }

        if ($order->status === 'canceled') {
            return response()->json(['success' => true, 'message' => 'Pesanan sudah dibatalkan.', 'order' => $order], 200);
        }

        $transaction = $order->transaction;
        $details = [];
        if ($transaction && Schema::hasColumn('transactions', 'payment_details') && ! empty($transaction->payment_details)) {
            $decoded = json_decode($transaction->payment_details, true);
            $details = is_array($decoded) ? $decoded : [];
        }

        if ($transaction && in_array($transaction->status, ['approved', 'settlement', 'capture'], true) && (($details['stage'] ?? null) === 'checkout_completed')) {
            return response()->json(['success' => false, 'message' => 'Pesanan sudah selesai dan tidak bisa dibatalkan.'], 422);
        }

        $order->status = 'canceled';
        $order->save();

        if ($transaction) {
            if (! in_array($transaction->status, ['approved', 'settlement', 'capture'], true)) {
                $transaction->status = 'declined';
            }
            if (Schema::hasColumn('transactions', 'payment_details')) {
                $details['stage'] = 'canceled_by_user';
                $details['canceled_at'] = now()->toDateTimeString();
                $transaction->payment_details = json_encode($details);
            }
            $transaction->save();
        }

        return response()->json(['success' => true, 'message' => 'Pesanan berhasil dibatalkan.', 'order' => $order->fresh()->load('items.product', 'transaction')], 200);
    }
}
