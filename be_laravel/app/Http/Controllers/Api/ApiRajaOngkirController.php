<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\About;

class ApiRajaOngkirController extends Controller
{
    protected $apiKey;
    protected $baseUrl;
    protected $origin;

    public function __construct()
    {
        // Membaca dari config/rajaongkir.php
        $this->apiKey = config('rajaongkir.api_key');
        $this->baseUrl = config('rajaongkir.base_url', 'https://api.rajaongkir.com/starter');
        $this->origin = config('rajaongkir.origin', '399');
    }

    public function getProvinces()
    {
        try {
            $endpoint = rtrim($this->baseUrl, '/') . '/destination/province';

            // TAMBAHAN ->withoutVerifying() UNTUK MENGATASI CURL ERROR 60
            $response = Http::withoutVerifying()->withHeaders([
                'Accept' => 'application/json',
                'key' => $this->apiKey
            ])->get($endpoint);

            if ($response->successful()) {
                // Support Komerce API ['data'] ATAU RajaOngkir Starter ['rajaongkir']['results']
                $data = $response->json()['data'] ?? $response->json()['rajaongkir']['results'] ?? [];
                return response()->json($data);
            }

            return response()->json(['error' => 'Gagal mengambil provinsi', 'detail' => $response->json()], 502);
        } catch (\Throwable $e) {
            \Log::error("API Mobile Provinces Error: " . $e->getMessage());
            return response()->json(['error' => 'Server Error: ' . $e->getMessage()], 500);
        }
    }

    public function getCities($provinceId)
    {
        try {
            $endpoint = rtrim($this->baseUrl, '/') . "/destination/city/{$provinceId}";

            // TAMBAHAN ->withoutVerifying() UNTUK MENGATASI CURL ERROR 60
            $response = Http::withoutVerifying()->withHeaders([
                'Accept' => 'application/json',
                'key' => $this->apiKey
            ])->get($endpoint);

            if ($response->successful()) {
                $data = $response->json()['data'] ?? $response->json()['rajaongkir']['results'] ?? [];
                return response()->json($data);
            }

            return response()->json(['error' => 'Gagal mengambil kota', 'detail' => $response->json()], 502);
        } catch (\Throwable $e) {
            \Log::error("API Mobile Cities Error: " . $e->getMessage());
            return response()->json(['error' => 'Server Error: ' . $e->getMessage()], 500);
        }
    }

    // FUNGSI KECAMATAN YANG DISAMAKAN PERSIS DENGAN VERSI WEB
    public function getSubdistricts($cityId)
    {
        try {
            // Menggunakan URL yang sama persis dengan fungsi getDistricts() di Web
            $endpoint = rtrim($this->baseUrl, '/') . "/destination/district/{$cityId}";

            $response = Http::withoutVerifying()->withHeaders([
                'Accept' => 'application/json',
                'key' => $this->apiKey
            ])->get($endpoint);

            if ($response->successful()) {
                // Support Komerce API ['data'] ATAU RajaOngkir Starter ['rajaongkir']['results']
                $data = $response->json()['data'] ?? $response->json()['rajaongkir']['results'] ?? [];
                return response()->json($data);
            }

            return response()->json([
                'error' => 'Gagal mengambil data kecamatan', 
                'detail' => $response->json()
            ], 502);

        } catch (\Throwable $e) {
            \Log::error("API Mobile Subdistricts Error: " . $e->getMessage());
            return response()->json(['error' => 'Server Error: ' . $e->getMessage()], 500);
        }
    }

    public function checkCost(Request $request)
    {
        $request->validate([
            'destination' => 'required', 
            'weight' => 'required|numeric', 
            'courier' => 'required' 
        ]);

        $about = About::first();
        $originCity = ($about && $about->city_id) ? $about->city_id : $this->origin;

        try {
            $isKomerce = str_contains($this->baseUrl, 'komerce');
            $endpoint = $isKomerce 
                ? rtrim($this->baseUrl, '/') . '/calculate/domestic-cost'
                : rtrim($this->baseUrl, '/') . '/cost';

            // TAMBAHAN ->withoutVerifying() UNTUK MENGATASI CURL ERROR 60
            $response = Http::withoutVerifying()->asForm()->withHeaders([
                'Accept' => 'application/json',
                'key' => $this->apiKey
            ])->post($endpoint, [
                'origin' => $originCity,
                'destination' => $request->destination,
                'weight' => $request->weight,
                'courier' => strtolower($request->courier)
            ]);

            if ($response->successful()) {
                if ($isKomerce) {
                    // Konversi response Komerce agar cocok dengan format bacaan Flutter (Starter)
                    $data = $response->json()['data'] ?? [];
                    $mapped = collect($data)->map(function($item) {
                        return [
                            'service' => $item['service'] ?? ($item['code'] ?? ''),
                            'description' => $item['description'] ?? ($item['name'] ?? ''),
                            'cost' => [
                                [
                                    'value' => (int) ($item['cost'] ?? ($item['price'] ?? 0)),
                                    'etd' => $item['etd'] ?? '',
                                    'note' => ''
                                ]
                            ]
                        ];
                    })->values()->toArray();
                    
                    return response()->json($mapped);
                } else {
                    $results = $response->json()['rajaongkir']['results'][0]['costs'] ?? [];
                    return response()->json($results);
                }
            }

            return response()->json(['error' => 'Gagal hitung ongkir', 'detail' => $response->json()], 502);
        } catch (\Throwable $e) {
            \Log::error("API Mobile checkCost Error: " . $e->getMessage());
            return response()->json(['error' => 'Server Error: ' . $e->getMessage()], 500);
        }
    }
}