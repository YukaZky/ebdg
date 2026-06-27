<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

class ApiMediaController extends Controller
{
    public function productImage(string $filename)
    {
        $safeName = basename($filename);
        $path = public_path('uploads/products/' . $safeName);

        if (! is_file($path)) {
            abort(404);
        }

        return response()->file($path, [
            'Cache-Control' => 'public, max-age=31536000',
        ]);
    }
}
