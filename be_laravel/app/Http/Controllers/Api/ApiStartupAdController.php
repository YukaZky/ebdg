<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppStartupAd;

class ApiStartupAdController extends Controller
{
    public function show()
    {
        $item = AppStartupAd::currentlyActive()
            ->latest('updated_at')
            ->first();

        if (!$item) {
            return response()->json(['data' => null]);
        }

        return response()->json([
            'data' => [
                'id' => $item->id,
                'title' => $item->title,
                'subtitle' => $item->subtitle,
                'image_url' => $item->image_url,
                'button_text' => $item->button_text ?: 'Belanja Sekarang',
                'target_url' => $item->target_url,
            ],
        ]);
    }
}
