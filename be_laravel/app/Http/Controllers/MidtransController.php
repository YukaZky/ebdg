<?php

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class MidtransController extends Controller
{
    public function notificationHandler(Request $request)
    {
        $serverKey = (string) config('midtrans.server_key');
        if ($serverKey === '') {
            return response()->json(['message' => 'Midtrans server key is not configured.'], 500);
        }

        $midtransOrderId = trim((string) $request->input('order_id'));
        $statusCode = trim((string) $request->input('status_code'));
        $grossAmount = trim((string) $request->input('gross_amount'));
        $signatureKey = trim((string) $request->input('signature_key'));
        $status = strtolower(trim((string) $request->input('transaction_status')));
        $type = strtolower(trim((string) $request->input('payment_type')));
        $fraud = strtolower(trim((string) $request->input('fraud_status')));

        if (
            $midtransOrderId === '' ||
            $statusCode === '' ||
            $grossAmount === '' ||
            $signatureKey === '' ||
            $status === ''
        ) {
            return response()->json(['message' => 'Invalid Midtrans notification payload.'], 400);
        }

        // Validasi signature resmi Midtrans:
        // SHA512(order_id + status_code + gross_amount + ServerKey)
        $expectedSignature = hash(
            'sha512',
            $midtransOrderId . $statusCode . $grossAmount . $serverKey
        );

        if (! hash_equals($expectedSignature, $signatureKey)) {
            return response()->json(['message' => 'Invalid Midtrans signature.'], 403);
        }

        // Dashboard Midtrans mengirim order_id sintetis saat tombol
        // "Tes URL notifikasi" dijalankan, misalnya:
        // payment_notif_test_Gxxxx_...
        // Setelah signature valid, test ini boleh dibalas 200 tanpa
        // mencari atau mengubah order/transaksi di database.
        if ($this->isDashboardTestNotification($request, $midtransOrderId)) {
            return response()->json([
                'message' => 'Midtrans notification endpoint test received successfully.',
            ], 200);
        }

        $orderId = $this->extractInternalOrderId($midtransOrderId);
        if (! $orderId) {
            return response()->json(['message' => 'Invalid Midtrans order ID.'], 400);
        }

        $order = Order::with('transaction')->find($orderId);
        if (! $order) {
            return response()->json(['message' => 'Order not found.'], 404);
        }

        $transaction = $order->transaction;
        if (! $transaction) {
            return response()->json(['message' => 'Transaction record not found for this order.'], 404);
        }

        // Jangan biarkan callback dari percobaan pembayaran lama mengubah
        // transaksi yang sudah dibuat ulang dengan Midtrans order_id baru.
        $currentMidtransOrderId = $this->currentMidtransOrderId($transaction);
        if (
            $currentMidtransOrderId !== null &&
            ! hash_equals($currentMidtransOrderId, $midtransOrderId)
        ) {
            return response()->json([
                'message' => 'Stale Midtrans notification ignored.',
            ]);
        }

        // Nilai dari Midtrans harus sama dengan total order di server.
        if (abs(((float) $grossAmount) - ((float) $order->total)) > 0.01) {
            return response()->json(['message' => 'Gross amount mismatch.'], 422);
        }

        if ($status === 'capture') {
            if ($type === 'credit_card' && $fraud === 'challenge') {
                $transaction->status = 'challenge';
            } elseif ($fraud === 'deny') {
                $transaction->status = 'declined';
                $order->status = 'canceled';
            } else {
                $transaction->status = 'approved';
                $order->status = 'ordered';
            }
        } elseif ($status === 'settlement') {
            $transaction->status = 'approved';
            $order->status = 'ordered';
        } elseif ($status === 'pending') {
            $transaction->status = 'pending';
            $order->status = 'ordered';
        } elseif (in_array($status, ['deny', 'expire', 'cancel'], true)) {
            $transaction->status = 'declined';
            $order->status = 'canceled';
        }

        $this->storeNotificationSnapshot(
            $transaction,
            $request,
            $midtransOrderId,
            $status
        );

        $transaction->save();
        $order->save();

        return response()->json(['message' => 'Notification handled successfully.']);
    }

    private function isDashboardTestNotification(Request $request, string $midtransOrderId): bool
    {
        if (! str_starts_with($midtransOrderId, 'payment_notif_test_')) {
            return false;
        }

        $configuredMerchantId = trim((string) config('midtrans.merchant_id'));
        $payloadMerchantId = trim((string) $request->input('merchant_id'));

        return $configuredMerchantId !== ''
            && $payloadMerchantId !== ''
            && hash_equals($configuredMerchantId, $payloadMerchantId);
    }

    private function extractInternalOrderId(string $midtransOrderId): ?int
    {
        // Format baru web + Flutter/API:
        // ORDER-{ID_ORDER}-{...}
        if (preg_match('/^ORDER-(\d+)(?:-|$)/i', $midtransOrderId, $matches) === 1) {
            return (int) $matches[1];
        }

        // Kompatibilitas transaksi web lama:
        // {ID_ORDER}-{TIMESTAMP}
        if (preg_match('/^(\d+)-\d+$/', $midtransOrderId, $matches) === 1) {
            return (int) $matches[1];
        }

        // Fallback jika Midtrans order_id hanya berupa ID numerik.
        if (ctype_digit($midtransOrderId)) {
            return (int) $midtransOrderId;
        }

        return null;
    }

    private function currentMidtransOrderId($transaction): ?string
    {
        if (
            ! Schema::hasColumn('transactions', 'payment_details') ||
            empty($transaction->payment_details)
        ) {
            return null;
        }

        $details = json_decode($transaction->payment_details, true);
        if (! is_array($details)) {
            return null;
        }

        $value = $details['midtrans_order_id']
            ?? data_get($details, 'midtrans_response.order_id');

        $value = trim((string) $value);
        return $value !== '' ? $value : null;
    }

    private function storeNotificationSnapshot(
        $transaction,
        Request $request,
        string $midtransOrderId,
        string $status
    ): void {
        if (! Schema::hasColumn('transactions', 'payment_details')) {
            return;
        }

        $details = [];
        if (! empty($transaction->payment_details)) {
            $decoded = json_decode($transaction->payment_details, true);
            if (is_array($decoded)) {
                $details = $decoded;
            }
        }

        // Pertahankan data checkout/Core API yang sudah ada dan tambahkan
        // snapshot webhook terakhir untuk audit/debugging.
        $details['midtrans_order_id'] = $midtransOrderId;
        $details['last_notification'] = [
            'transaction_status' => $status,
            'status_code' => (string) $request->input('status_code'),
            'payment_type' => $request->input('payment_type'),
            'fraud_status' => $request->input('fraud_status'),
            'transaction_id' => $request->input('transaction_id'),
            'gross_amount' => $request->input('gross_amount'),
            'received_at' => now()->toDateTimeString(),
        ];

        $transaction->payment_details = json_encode($details);
    }
}
