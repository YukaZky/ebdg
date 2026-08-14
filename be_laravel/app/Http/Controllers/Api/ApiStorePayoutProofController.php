<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StorePayout;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ApiStorePayoutProofController extends Controller
{
    public function show(Request $request, int $id)
    {
        $payout = StorePayout::find($id);
        if (! $payout) {
            return response()->json(['success' => false, 'message' => 'Data pencairan tidak ditemukan.'], 404);
        }

        $userId = (int) $request->user()->id;
        $isOwner = (int) $payout->seller_id === $userId;
        $isSuperAdmin = Schema::hasTable('user_super')
            && DB::table('user_super')->where('user_id', $userId)->exists();

        if (! $isOwner && ! $isSuperAdmin) {
            return response()->json(['success' => false, 'message' => 'Anda tidak memiliki akses ke bukti pencairan ini.'], 403);
        }

        if (! $payout->proof_photo) {
            return response()->json(['success' => false, 'message' => 'Bukti pencairan belum tersedia.'], 404);
        }

        $filename = basename((string) $payout->proof_photo);
        $path = storage_path('app/private/payouts/' . $filename);
        if (! is_file($path)) {
            return response()->json(['success' => false, 'message' => 'File bukti pencairan tidak ditemukan.'], 404);
        }

        return response()->file($path, [
            'Cache-Control' => 'private, max-age=300',
        ]);
    }
}
