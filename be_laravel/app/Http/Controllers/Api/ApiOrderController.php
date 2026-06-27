<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\ProductReview;
use Illuminate\Http\Request;

class ApiOrderController extends Controller
{
    public function index(Request $request)
    {
        $orders = Order::with('items.product', 'transaction')
            ->where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(fn ($order) => $this->formatOrder($order))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Berhasil mengambil riwayat pesanan',
            'data' => $orders,
        ], 200);
    }

    private function formatOrder(Order $order): array
    {
        $order->loadMissing('items.product', 'transaction');

        $data = $order->toArray();
        $transaction = $order->transaction;
        $details = $this->transactionDetails($transaction);
        $paymentInfo = $details['payment_info'] ?? null;
        $transactionStatus = $transaction ? strtolower((string) $transaction->status) : 'no_transaction';
        $orderStatus = strtolower((string) $order->status);

        $frontendStatus = $this->frontendStatus($orderStatus, $transactionStatus, $details, is_array($paymentInfo) ? $paymentInfo : null);
        $data['frontend_status'] = $frontendStatus;
        $data['frontend_status_label'] = $this->statusLabel($frontendStatus);
        $data['transaction_status'] = $transactionStatus;
        $data['payment_info'] = $paymentInfo;
        $data['payment_deadline'] = is_array($paymentInfo) ? ($paymentInfo['expiry_time'] ?? null) : null;
        $data['payment_stage'] = $details['stage'] ?? null;
        $data['payment_type'] = $details['payment_type'] ?? null;
        $data['payment_bank'] = $details['bank'] ?? null;
        $data['payment_transaction_id'] = is_array($paymentInfo) ? ($paymentInfo['transaction_id'] ?? null) : null;

        $data['reviewed_product_ids'] = ProductReview::where('user_id', $order->user_id)
            ->where('order_id', $order->id)
            ->pluck('product_id')
            ->map(fn ($id) => (int) $id)
            ->values();
        $data['can_review'] = in_array($frontendStatus, ['delivered', 'done'], true);

        return $data;
    }

    private function frontendStatus(string $orderStatus, string $transactionStatus, array $details, ?array $paymentInfo): string
    {
        if (in_array($orderStatus, ['canceled', 'cancelled'], true) || in_array($transactionStatus, ['declined', 'cancel', 'canceled', 'expire', 'expired'], true)) {
            return 'canceled';
        }

        if (in_array($orderStatus, ['done', 'completed', 'complete', 'selesai'], true)) {
            return 'done';
        }

        if (in_array($orderStatus, ['delivered', 'deliver', 'dikirim'], true)) {
            return 'delivered';
        }

        if (in_array($orderStatus, ['packing', 'processing', 'shipped', 'dikemas'], true)) {
            return 'packing';
        }

        if (in_array($transactionStatus, ['approved', 'settlement', 'capture'], true)) {
            return (($details['stage'] ?? null) === 'checkout_completed') ? 'packing' : 'paid_not_checked_out';
        }

        if ($transactionStatus === 'pending' || is_array($paymentInfo)) {
            return 'pending_payment';
        }

        return 'pending_payment';
    }

    private function statusLabel(string $status): string
    {
        return match ($status) {
            'pending_payment' => 'Belum Dibayar',
            'paid_not_checked_out' => 'Dibayar',
            'packing' => 'Dikemas',
            'delivered' => 'Dikirim',
            'done' => 'Selesai',
            'canceled' => 'Dibatalkan',
            default => 'Belum Dibayar',
        };
    }

    private function transactionDetails($transaction): array
    {
        if (! $transaction || empty($transaction->payment_details)) {
            return [];
        }

        $details = json_decode($transaction->payment_details, true);
        return is_array($details) ? $details : [];
    }
}
