<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Brand;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class ApiAdminBrandController extends Controller
{
    private function brandDirectory(): string
    {
        $directory = public_path('uploads/brands');
        if (! is_dir($directory)) {
            mkdir($directory, 0775, true);
        }
        return $directory;
    }

    private function extension($file): string
    {
        $original = method_exists($file, 'getClientOriginalName') ? (string) $file->getClientOriginalName() : '';
        $extension = method_exists($file, 'getClientOriginalExtension') ? (string) $file->getClientOriginalExtension() : '';
        if ($extension === '' && $original !== '') {
            $extension = pathinfo($original, PATHINFO_EXTENSION);
        }
        $extension = strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $extension ?: 'jpg'));
        return in_array($extension, ['jpg', 'jpeg', 'png', 'webp', 'gif'], true) ? $extension : 'jpg';
    }

    private function uniqueSlug(string $name, int $userId, ?int $ignoreId = null): string
    {
        $base = Str::slug($name) ?: 'brand';
        $slug = $base . '-' . $userId;
        $counter = 2;

        while (Brand::where('slug', $slug)
            ->when($ignoreId, fn ($query) => $query->where('id', '!=', $ignoreId))
            ->exists()) {
            $slug = $base . '-' . $userId . '-' . $counter;
            $counter++;
        }

        return $slug;
    }

    private function assignCategoryIfAvailable(Brand $brand, Request $request): void
    {
        if (! Schema::hasColumn('brands', 'category_id')) return;
        $categoryId = $request->input('category_id');
        if ($categoryId === null || $categoryId === '' || strtolower((string) $categoryId) === 'null') {
            $brand->category_id = null;
            return;
        }
        $brand->category_id = $categoryId;
    }

    private function saveImageIfAny(Brand $brand, Request $request): void
    {
        if (! $request->hasFile('image')) return;
        $image = $request->file('image');
        if (method_exists($image, 'isValid') && ! $image->isValid()) return;

        $fileName = time() . '_brand_' . Str::random(8) . '.' . $this->extension($image);
        $image->move($this->brandDirectory(), $fileName);
        $brand->image = $fileName;
    }

    public function index()
    {
        $brands = Brand::where('user_id', auth()->id())->latest()->get();
        return response()->json(['success' => true, 'data' => $brands], 200);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'category_id' => 'nullable|integer|exists:categories,id',
            'image' => 'nullable|image|mimes:jpg,jpeg,png,webp,gif|max:4096',
        ]);

        $brand = new Brand();
        $brand->user_id = auth()->id();
        $brand->name = trim((string) $request->name);
        $brand->slug = $this->uniqueSlug($brand->name, auth()->id());
        $this->assignCategoryIfAvailable($brand, $request);
        $this->saveImageIfAny($brand, $request);
        $brand->save();

        return response()->json(['success' => true, 'message' => 'Brand berhasil ditambahkan', 'data' => $brand], 201);
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'category_id' => 'nullable|integer|exists:categories,id',
            'image' => 'nullable|image|mimes:jpg,jpeg,png,webp,gif|max:4096',
        ]);

        $brand = Brand::where('user_id', auth()->id())->findOrFail($id);
        $brand->name = trim((string) $request->name);
        $brand->slug = $this->uniqueSlug($brand->name, auth()->id(), $brand->id);
        $this->assignCategoryIfAvailable($brand, $request);
        $this->saveImageIfAny($brand, $request);
        $brand->save();

        return response()->json(['success' => true, 'message' => 'Brand berhasil diupdate', 'data' => $brand], 200);
    }

    public function destroy($id)
    {
        Brand::where('user_id', auth()->id())->findOrFail($id)->delete();
        return response()->json(['success' => true, 'message' => 'Brand berhasil dihapus'], 200);
    }
}
