<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\ManualPaymentService;
use Illuminate\Http\Request;

class ApiManualPaymentController extends Controller
{
    public function __construct(private readonly ManualPaymentService $payments) {}

    public function submitProof(Request $request, int $id)
    {
        $order = Order::with(['transaction.latestConfirmation'])
            ->where('user_id', $request->user()->id)
            ->find($id);

        if (! $order) {
            return response()->json(['success' => false, 'message' => 'Pesanan tidak ditemukan.'], 404);
        }

        $validated = $request->validate([
            'sender_name' => 'required|string|max:150',
            'sender_bank' => 'required|string|max:100',
            'sender_account_number' => ['required', 'string', 'max:100', 'regex:/^[0-9 .-]{4,100}$/'],
            'transferred_amount' => 'required|numeric|min:1',
            'transferred_at' => 'nullable|date|before_or_equal:now',
            'note' => 'nullable|string|max:1000',
            'proof' => 'required|image|mimes:jpg,jpeg,png,webp|max:5120',
        ]);

        $confirmation = $this->payments->submitProof($order, $validated, $request->file('proof'));

        return response()->json([
            'success' => true,
            'message' => 'Bukti pembayaran berhasil dikirim dan menunggu verifikasi Super Admin.',
            'payment_state' => ManualPaymentService::PROOF_SUBMITTED,
            'confirmation' => $this->payments->confirmationPayload($confirmation),
        ], 201);
    }
}
