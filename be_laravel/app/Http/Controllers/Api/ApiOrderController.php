<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
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
        $transactionStatus = $transaction ? (string) $transaction->status : 'no_transaction';
        $orderStatus = strtolower((string) $order->status);

        $frontendStatus = $this->frontendStatus($orderStatus, $transactionStatus, $paymentInfo);
        $data['frontend_status'] = $frontendStatus;
        $data['frontend_status_label'] = $this->statusLabel($frontendStatus);
        $data['transaction_status'] = $transactionStatus;
        $data['payment_info'] = $paymentInfo;
        $data['payment_deadline'] = is_array($paymentInfo) ? ($paymentInfo['expiry_time'] ?? null) : null;
        $data['payment_stage'] = $details['stage'] ?? null;
        $data['payment_type'] = $details['payment_type'] ?? null;
        $data['payment_bank'] = $details['bank'] ?? null;
        $data['payment_transaction_id'] = is_array($paymentInfo) ? ($paymentInfo['transaction_id'] ?? null) : null;

        return $data;
    }

    private function frontendStatus(string $orderStatus, string $transactionStatus, ?array $paymentInfo): string
    {
        if (in_array($orderStatus, ['canceled', 'cancelled'], true) || in_array($transactionStatus, ['declined', 'cancel', 'canceled', 'expire', 'expired'], true)) {
            return 'canceled';
        }

        if (in_array($orderStatus, ['done', 'completed', 'complete'], true)) {
            return 'done';
        }

        if (in_array($orderStatus, ['delivered', 'deliver'], true)) {
            return 'delivered';
        }

        if (in_array($orderStatus, ['packing', 'processing', 'shipped'], true)) {
            return 'packing';
        }

        if (in_array($transactionStatus, ['approved', 'settlement', 'capture'], true)) {
            return 'paid_not_checked_out';
        }

        if ($transactionStatus === 'pending' || is_array($paymentInfo)) {
            return 'pending_payment';
        }

        return 'pending_payment';
    }

    private function statusLabel(string $status): string
    {
        return match ($status) {
            'pending_payment' => 'Pending Payment',
            'paid_not_checked_out' => 'Dibayar',
            'packing' => 'Packing',
            'delivered' => 'Delivered',
            'done' => 'Done',
            'canceled' => 'Canceled',
            default => 'Pending Payment',
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
