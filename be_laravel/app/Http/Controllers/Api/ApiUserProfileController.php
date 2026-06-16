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
        $avatarName = time() . '_' . $user->id . '_avatar.' . $request->avatar->extension();
        $request->avatar->move(public_path('uploads/profiles'), $avatarName);

        $user->avatar = $avatarName;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Foto profil berhasil diperbarui',
            'data' => $user,
        ]);
    }
}
