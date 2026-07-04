<?php

namespace App\Http\Controllers;

use App\Models\AppStartupAd;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\File;

class AppStartupAdController extends BaseController
{
    public function index()
    {
        $startupAds = AppStartupAd::orderBy('created_at', 'DESC')->paginate(10);
        return view('admin.startup-ads.index', compact('startupAds'));
    }

    public function create()
    {
        return view('admin.startup-ads.form', [
            'startupAd' => new AppStartupAd(),
            'mode' => 'create',
        ]);
    }

    public function store(Request $request)
    {
        $validated = $this->validateRequest($request, true);

        $startupAd = new AppStartupAd($validated);
        $startupAd->is_active = $request->boolean('is_active');
        $startupAd->image = $this->storeImage($request);
        $startupAd->save();

        if ($startupAd->is_active) {
            $this->deactivateOtherAds($startupAd->id);
        }

        return redirect()->route('admin.startup-ads.index')->with('status', 'Iklan pembuka aplikasi berhasil ditambahkan.');
    }

    public function edit($id)
    {
        $startupAd = AppStartupAd::findOrFail($id);
        return view('admin.startup-ads.form', [
            'startupAd' => $startupAd,
            'mode' => 'edit',
        ]);
    }

    public function update(Request $request, $id)
    {
        $startupAd = AppStartupAd::findOrFail($id);
        $validated = $this->validateRequest($request, false);

        $startupAd->fill($validated);
        $startupAd->is_active = $request->boolean('is_active');

        if ($request->hasFile('image')) {
            $this->deleteImage($startupAd->image);
            $startupAd->image = $this->storeImage($request);
        }

        $startupAd->save();

        if ($startupAd->is_active) {
            $this->deactivateOtherAds($startupAd->id);
        }

        return redirect()->route('admin.startup-ads.index')->with('status', 'Iklan pembuka aplikasi berhasil diperbarui.');
    }

    public function destroy($id)
    {
        $startupAd = AppStartupAd::findOrFail($id);
        $this->deleteImage($startupAd->image);
        $startupAd->delete();

        return redirect()->route('admin.startup-ads.index')->with('status', 'Iklan pembuka aplikasi berhasil dihapus.');
    }

    private function validateRequest(Request $request, bool $imageRequired): array
    {
        return $request->validate([
            'title' => 'nullable|string|max:120',
            'subtitle' => 'nullable|string|max:180',
            'button_text' => 'nullable|string|max:50',
            'target_url' => 'nullable|url|max:255',
            'start_at' => 'nullable|date',
            'end_at' => 'nullable|date|after_or_equal:start_at',
            'image' => ($imageRequired ? 'required' : 'nullable') . '|image|mimes:jpg,jpeg,png,webp|max:4096',
        ]);
    }

    private function storeImage(Request $request): string
    {
        $destinationPath = public_path('uploads/startup-ads');
        if (!File::isDirectory($destinationPath)) {
            File::makeDirectory($destinationPath, 0755, true, true);
        }

        $image = $request->file('image');
        $fileName = 'startup-ad-' . Carbon::now()->timestamp . '-' . uniqid() . '.' . $image->extension();
        $image->move($destinationPath, $fileName);

        return $fileName;
    }

    private function deleteImage(?string $image): void
    {
        if (!$image) return;

        $path = public_path('uploads/startup-ads/' . $image);
        if (File::exists($path)) {
            File::delete($path);
        }
    }

    private function deactivateOtherAds(int $activeAdId): void
    {
        AppStartupAd::where('id', '!=', $activeAdId)->update(['is_active' => false]);
    }
}
