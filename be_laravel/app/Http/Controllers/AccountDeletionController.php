<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\AccountDeletionService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\View\View;

class AccountDeletionController extends Controller
{
    public function index(): View
    {
        return view('legal.account-deletion');
    }

    public function destroy(Request $request, AccountDeletionService $service): View|RedirectResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'confirmation' => ['accepted'],
        ]);

        $user = User::query()->where('email', strtolower(trim($validated['email'])))->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return back()
                ->withInput($request->only('email'))
                ->withErrors(['email' => 'Email atau password tidak sesuai.']);
        }

        $service->delete($user);

        return view('legal.account-deletion-complete');
    }
}
