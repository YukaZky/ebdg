<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Session;
use Symfony\Component\HttpFoundation\Response;

class AuthAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        // 1. Cek apakah user sudah login
        if (!Auth::check()) {
            return $this->unauthorizedResponse($request, 'Anda harus login terlebih dahulu.');
        }

        // 2. Cek apakah role user adalah Admin
        if (Auth::user()->utype === 'ADM') {
            return $next($request);
        }

        // 3. Jika bukan admin, handle sesuai tipe request
        Session::flush();
        return $this->unauthorizedResponse($request, 'Akses ditolak: Anda bukan admin.');
    }

    /**
     * Memilih format respon berdasarkan asal request (API atau Web)
     */
    private function unauthorizedResponse(Request $request, $message)
    {
        // Jika request berasal dari API (Flutter), kirim JSON
        if ($request->expectsJson() || $request->is('api/*')) {
            return response()->json(['status' => 'error', 'message' => $message], 403);
        }

        // Jika request berasal dari Web, redirect ke login
        return redirect()->route('login');
    }
}