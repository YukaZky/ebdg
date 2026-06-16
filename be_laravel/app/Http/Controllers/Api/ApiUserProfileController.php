<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

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
}
