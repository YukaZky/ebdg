<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ManualPaymentAccount;
use App\Models\PaymentMethod;
use Illuminate\Support\Facades\Schema;

class ApiPaymentMethodController extends Controller
{
    public function index()
    {
        if (Schema::hasTable('manual_payment_accounts')) {
            $account = ManualPaymentAccount::query()
                ->where('is_active', true)
                ->orderByDesc('is_primary')
                ->latest('updated_at')
                ->first();

            $methods = $account ? [[
                'id' => $account->id,
                'name' => ($account->account_type === 'virtual_account' ? 'Virtual Account ' : 'Transfer Bank ').$account->bank_name,
                'payment_type' => 'bank_transfer',
                'bank_code' => strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $account->bank_name)),
                'icon_url' => asset('assets/images/payment/1.png'),
                'is_active' => true,
            ]] : [];

            return response()->json([
                'success' => true,
                'message' => $account
                    ? 'Metode transfer manual berhasil diambil.'
                    : 'Rekening/VA belum diatur oleh Super Admin.',
                'data' => $methods,
            ], 200);
        }

        // Hanya mengambil metode pembayaran yang is_active bernilai true
        $methods = PaymentMethod::where('is_active', true)->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar metode pembayaran berhasil diambil',
            'data' => $methods,
        ], 200);
    }
}
