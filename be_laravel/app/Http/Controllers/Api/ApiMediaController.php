<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

class ApiMediaController extends Controller
{
    public function productImage(string $filename)
    {
        return $this->serveUploadImage('uploads/products', $filename);
    }

    public function profileImage(string $filename)
    {
        return $this->serveUploadImage('uploads/profiles', $filename);
    }

    private function serveUploadImage(string $directory, string $filename)
    {
        $safeName = basename($filename);
        $path = public_path($directory . '/' . $safeName);

        if (is_file($path)) {
            return response()->file($path, [
                'Cache-Control' => 'public, max-age=31536000',
            ]);
        }

        return $this->placeholderPng();
    }

    private function placeholderPng()
    {
        $png = base64_decode('iVBORw0KGgoAAAANSUhEUgAAAHgAAAB4CAIAAAC2BqGFAAAAAXNSR0IArs4c6QAAAgxJREFUeF7t1LENgDAQRVGf/VcwhOgBkWQF7z3Zc0gq8nmmw1o7M9k/7QH8Au0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAm0C7QJtAu0CbQLtAv0Dx1HCOsttfQwAAAAASUVORK5CYII=');

        return response($png, 200, [
            'Content-Type' => 'image/png',
            'Cache-Control' => 'public, max-age=300',
        ]);
    }
}
