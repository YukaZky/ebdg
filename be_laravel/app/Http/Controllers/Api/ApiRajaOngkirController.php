<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\About;

class ApiRajaOngkirController extends Controller
{
    protected $apiKey;
    protected $origin;

    public function __construct()
    {
        $this->apiKey = env('RAJAONGKIR_API_KEY');
        $this->origin = env('RAJAONGKIR_ORIGIN', '399'); // Fallback ke .env jika belum di-set
    }

    public function getProvinces()
    {
        $response = Http::withHeaders(['key' => $this->apiKey])
            ->get('https://api.rajaongkir.com/starter/province');

        return response()->json($response->json()['rajaongkir']['results'] ?? []);
    }

    public function getCities($provinceId)
    {
        $response = Http::withHeaders(['key' => $this->apiKey])
            ->get('https://api.rajaongkir.com/starter/city', [
                'province' => $provinceId
            ]);

        return response()->json($response->json()['rajaongkir']['results'] ?? []);
    }

    public function checkCost(Request $request)
    {
        $request->validate([
            'destination' => 'required', 
            'weight' => 'required|numeric', 
            'courier' => 'required' 
        ]);

        // Mengambil origin kota dari Manajemen Toko (Tabel About)
        $about = About::first();
        
        // API Starter RajaOngkir membutuhkan parameter 'city_id'
        $originCity = ($about && $about->city_id) ? $about->city_id : $this->origin;

        $response = Http::withHeaders(['key' => $this->apiKey])
            ->post('https://api.rajaongkir.com/starter/cost', [
                'origin' => $originCity,
                'destination' => $request->destination,
                'weight' => $request->weight,
                'courier' => $request->courier
            ]);

        return response()->json($response->json()['rajaongkir']['results'][0]['costs'] ?? []);
    }
}