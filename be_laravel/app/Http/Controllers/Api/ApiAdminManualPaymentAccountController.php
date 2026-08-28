<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ManualPaymentAccount;
use App\Services\SuperAdminService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ApiAdminManualPaymentAccountController extends Controller
{
    public function __construct(private readonly SuperAdminService $superAdmins) {}

    public function index(Request $request)
    {
        $this->authorizeSuperAdmin($request);

        return response()->json([
            'success' => true,
            'data' => ManualPaymentAccount::query()
                ->orderByDesc('is_primary')
                ->orderByDesc('is_active')
                ->latest('updated_at')
                ->get(),
        ]);
    }

    public function store(Request $request)
    {
        $this->authorizeSuperAdmin($request);
        $validated = $this->validateAccount($request);

        $account = DB::transaction(function () use ($request, $validated) {
            $isActive = $request->boolean('is_active', true);
            $makePrimary = $isActive && (
                $request->boolean('is_primary')
                || ! ManualPaymentAccount::where('is_active', true)->where('is_primary', true)->exists()
            );
            if ($makePrimary) {
                ManualPaymentAccount::query()->update(['is_primary' => false]);
            }

            return ManualPaymentAccount::create([
                ...$validated,
                'is_active' => $isActive,
                'is_primary' => $makePrimary,
                'created_by' => $request->user()->id,
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Rekening/VA tujuan berhasil ditambahkan.',
            'data' => $account,
        ], 201);
    }

    public function update(Request $request, ManualPaymentAccount $account)
    {
        $this->authorizeSuperAdmin($request);
        $validated = $this->validateAccount($request);

        DB::transaction(function () use ($request, $validated, $account) {
            $isActive = $request->boolean('is_active', $account->is_active);
            $isPrimary = $isActive && $request->boolean('is_primary', $account->is_primary);

            if ($isPrimary) {
                ManualPaymentAccount::where('id', '!=', $account->id)->update(['is_primary' => false]);
            }
            $account->update([
                ...$validated,
                'is_active' => $isActive,
                'is_primary' => $isPrimary,
            ]);
            if (! ManualPaymentAccount::where('is_active', true)->where('is_primary', true)->exists()) {
                ManualPaymentAccount::where('is_active', true)
                    ->latest('updated_at')
                    ->first()
                    ?->update(['is_primary' => true]);
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Rekening/VA tujuan berhasil diperbarui.',
            'data' => $account->fresh(),
        ]);
    }

    public function setPrimary(Request $request, ManualPaymentAccount $account)
    {
        $this->authorizeSuperAdmin($request);

        DB::transaction(function () use ($account) {
            ManualPaymentAccount::query()->update(['is_primary' => false]);
            $account->update(['is_primary' => true, 'is_active' => true]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Rekening/VA utama berhasil ditetapkan.',
            'data' => $account->fresh(),
        ]);
    }

    private function validateAccount(Request $request): array
    {
        return $request->validate([
            'account_type' => ['required', Rule::in(['virtual_account', 'bank_account'])],
            'bank_name' => 'required|string|max:100',
            'account_number' => ['required', 'string', 'max:100', 'regex:/^[0-9 .-]{4,100}$/'],
            'account_name' => 'required|string|max:150',
            'label' => 'nullable|string|max:100',
            'instructions' => 'nullable|string|max:2000',
            'is_active' => 'sometimes|boolean',
            'is_primary' => 'sometimes|boolean',
        ]);
    }

    private function authorizeSuperAdmin(Request $request): void
    {
        abort_unless($this->superAdmins->check($request->user()), 403, 'Menu ini khusus Super Admin.');
    }
}
