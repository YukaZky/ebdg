<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ManualPaymentConfirmation;
use App\Services\SuperAdminService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ApiManualPaymentProofController extends Controller
{
    public function __construct(private readonly SuperAdminService $superAdmins) {}

    public function show(Request $request, ManualPaymentConfirmation $confirmation)
    {
        $isOwner = (int) $confirmation->user_id === (int) $request->user()->id;
        if (! $isOwner && ! $this->superAdmins->check($request->user())) {
            return response()->json(['success' => false, 'message' => 'Anda tidak memiliki akses ke bukti ini.'], 403);
        }

        if (! Storage::disk('local')->exists($confirmation->proof_path)) {
            return response()->json(['success' => false, 'message' => 'File bukti pembayaran tidak ditemukan.'], 404);
        }

        return response()->file(Storage::disk('local')->path($confirmation->proof_path), [
            'Cache-Control' => 'private, no-store, max-age=0',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }
}
