<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ProductVariation;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Throwable;

class ApiProductVariationImageController extends Controller
{
    private function safeExtension($filename): string
    {
        $extension = strtolower(preg_replace('/[^a-zA-Z0-9]/', '', pathinfo((string) $filename, PATHINFO_EXTENSION) ?: 'jpg'));
        return in_array($extension, ['jpg', 'jpeg', 'png', 'webp', 'gif'], true) ? $extension : 'jpg';
    }

    private function productImageDirectory(): string
    {
        $directory = public_path('uploads/products');
        if (! is_dir($directory)) {
            mkdir($directory, 0775, true);
        }

        if (! is_writable($directory)) {
            throw new \RuntimeException('Folder uploads/products tidak bisa ditulis: ' . $directory);
        }

        return $directory;
    }

    public function update(Request $request, int $id)
    {
        $request->validate([
            'image_base64' => 'required|string',
            'filename' => 'nullable|string|max:255',
        ]);

        try {
            $variation = ProductVariation::whereHas('product', function ($query) {
                $query->where('user_id', auth()->id());
            })->findOrFail($id);

            $base64 = trim((string) $request->input('image_base64'));
            if (str_contains($base64, ',')) {
                $base64 = substr($base64, strpos($base64, ',') + 1);
            }

            $bytes = base64_decode($base64, true);
            if ($bytes === false || strlen($bytes) === 0) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Data gambar variasi tidak valid.',
                ], 422);
            }

            $extension = $this->safeExtension($request->input('filename'));
            $imageName = time() . '_variation_' . $variation->id . '_' . Str::random(10) . '.' . $extension;
            $path = $this->productImageDirectory() . DIRECTORY_SEPARATOR . $imageName;

            $written = file_put_contents($path, $bytes);
            if ($written === false || ! is_file($path)) {
                throw new \RuntimeException('Gagal menulis file gambar variasi.');
            }

            $variation->image = $imageName;
            $variation->save();
            $variation->refresh();

            return response()->json([
                'status' => 'success',
                'message' => 'Gambar variasi berhasil disimpan.',
                'data' => $variation,
            ], 200);
        } catch (Throwable $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal menyimpan gambar variasi: ' . $e->getMessage(),
            ], 500);
        }
    }
}
