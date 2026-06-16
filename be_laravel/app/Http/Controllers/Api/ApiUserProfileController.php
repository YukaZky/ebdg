<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class ApiUserProfileController extends Controller
{
    public function updatePhoto(Request $request)
    {
        $request->validate([
            'avatar' => 'required|image|max:2048',
        ]);

        $user = $request->user();
        $directory = public_path('uploads/profiles');
        if (! is_dir($directory)) {
            mkdir($directory, 0755, true);
        }

        $avatarName = time() . '_' . $user->id . '_avatar.' . $request->avatar->extension();
        $request->avatar->move($directory, $avatarName);

        $user->avatar = $avatarName;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Foto profil berhasil diperbarui',
            'data' => $user,
        ]);
    }

    public function updateAccount(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'name' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:30',
            'email' => ['required', 'email', Rule::unique('users', 'email')->ignore($user->id)],
            'current_password' => 'nullable|string',
            'password' => 'nullable|string|min:8|confirmed',
        ]);

        if ($request->filled('password')) {
            if (! $request->filled('current_password') || ! Hash::check($request->current_password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Password lama tidak sesuai.',
                ], 422);
            }
            $user->password = $request->password;
        }

        $user->name = $request->name ?: $user->name;
        $user->phone = $request->phone;
        $user->email = $request->email;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Pengaturan akun berhasil diperbarui',
            'data' => $user,
        ]);
    }
}
