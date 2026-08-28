<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\ManualPaymentService;
use App\Services\OrderCancellationService;
use Illuminate\Support\Facades\Auth;

class ApiOrderCancelController extends Controller
{
    public function __construct(private readonly OrderCancellationService $cancellation) {}

    public function cancel($id)
    {
        $order = Order::with('items.product', 'transaction')->where('user_id', Auth::id())->find($id);

        if (! $order) {
            return response()->json(['success' => false, 'message' => 'Pesanan tidak ditemukan.'], 404);
        }

        if ($order->status === 'canceled') {
            return response()->json(['success' => true, 'message' => 'Pesanan sudah dibatalkan.', 'order' => $order], 200);
        }

        $details = json_decode((string) $order->transaction?->payment_details, true);
        if (is_array($details) && ($details['stage'] ?? null) === ManualPaymentService::PROOF_SUBMITTED) {
            return response()->json([
                'success' => false,
                'message' => 'Pesanan tidak dapat dibatalkan saat bukti pembayaran sedang diverifikasi.',
            ], 422);
        }

        $updated = $this->cancellation->cancelPending(
            $order,
            ManualPaymentService::CANCELED,
            'Pesanan dibatalkan oleh user.',
            Auth::id(),
            'order_canceled_by_user',
        );

        return response()->json([
            'success' => true,
            'message' => 'Pesanan berhasil dibatalkan dan stok dikembalikan.',
            'order' => $updated,
        ], 200);
    }
}
