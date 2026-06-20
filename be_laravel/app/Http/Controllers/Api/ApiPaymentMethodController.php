<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PaymentMethod;
use Illuminate\Http\Request;

class ApiPaymentMethodController extends Controller
{
    public function index()
    {
        // Hanya mengambil metode pembayaran yang is_active bernilai true
        $methods = PaymentMethod::where('is_active', true)->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar metode pembayaran berhasil diambil',
            'data' => $methods
        ], 200);
    }
}