<?php

namespace App\Http\Controllers;

use App\Models\User;
use Exception; // <-- Tambahkan baris ini
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Laravel\Socialite\Facades\Socialite;

class GoogleController extends Controller
{
    /**
     * Redirect the user to the Google authentication page.
     *
     * @return \Illuminate\Http\Response
     */
    public function redirectToGoogle()
    {
        return Socialite::driver('google')->redirect();
    }

    /**
     * Obtain the user information from Google.
     *
     * @return \Illuminate\Http\Response
     */
    public function handleGoogleCallback()
    {
        try {
            $user = Socialite::driver('google')->user();

            $finduser = User::where('google_id', $user->id)->first();

            if($finduser){
                Auth::login($finduser);
                return redirect()->intended('home');
            } else {
                $newUser = User::create([
                    'name' => $user->name,
                    'email' => $user->email,
                    'google_id'=> $user->id,
                    'password' => encrypt('123456dummy') // Anda bisa mengisinya dengan password acak
                ]);

                Auth::login($newUser);
                return redirect()->intended('home');
            }

        } catch (Exception $e) {
            // Jika terjadi error, kembalikan ke halaman login
            return redirect('/login')->with('error', 'Terjadi kesalahan saat otentikasi dengan Google.');
        }
    }
}