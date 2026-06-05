<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class ApiRajaOngkirController extends Controller
{
    protected $apiKey;
    protected $origin;

    public function __construct()
    {
        // Pastikan Anda sudah mengatur RAJAONGKIR_API_KEY di file .env Anda
        $this->apiKey = env('RAJAONGKIR_API_KEY');
        // ID 399 adalah ID kota Semarang. Ganti sesuai dengan kota toko Anda jika berbeda
        $this->origin = env('RAJAONGKIR_ORIGIN', '399'); 
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
            'destination' => 'required', // ID Kota tujuan
            'weight' => 'required|numeric', // Berat dalam gram
            'courier' => 'required' // jne, pos, atau tiki
        ]);

        $response = Http::withHeaders(['key' => $this->apiKey])
            ->post('https://api.rajaongkir.com/starter/cost', [
                'origin' => $this->origin,
                'destination' => $request->destination,
                'weight' => $request->weight,
                'courier' => $request->courier
            ]);

        return response()->json($response->json()['rajaongkir']['results'][0]['costs'] ?? []);
    }
}