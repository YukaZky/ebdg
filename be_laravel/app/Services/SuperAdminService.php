<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class SuperAdminService
{
    public function check(User|int|null $user): bool
    {
        $userModel = $user instanceof User ? $user : User::find($user);
        $userId = $userModel?->id;

        return $userId !== null
            && strtoupper((string) $userModel->utype) === 'ADM'
            && Schema::hasTable('user_super')
            && DB::table('user_super')->where('user_id', $userId)->exists();
    }
}
