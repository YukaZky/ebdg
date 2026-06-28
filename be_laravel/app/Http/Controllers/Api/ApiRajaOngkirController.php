<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\StoreLocationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class ApiRajaOngkirController extends Controller
{
    protected $apiKey;
    protected $baseUrl;

    public function __construct(private readonly StoreLocationService $storeLocations)
    {
        // Membaca dari config/rajaongkir.php
        $this->apiKey = config('rajaongkir.api_key');
        $this->baseUrl = config('rajaongkir.base_url', 'https://api.rajaongkir.com/starter');
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
            'seller_id' => 'required|integer|exists:users,id',
            'destination' => 'required|string',
            'destination_district' => 'nullable|string',
            'weight' => 'required|numeric|min:1',
            'courier' => 'required|string',
        ]);

        try {
            $isKomerce = str_contains($this->baseUrl, 'komerce');
            $storeLocation = $this->storeLocations->findForUser((int) $request->seller_id);

            if (! $storeLocation) {
                return response()->json([
                    'error' => 'Lokasi toko belum diatur oleh penjual.',
                ], 422);
            }

            if ($isKomerce && (empty($storeLocation->district_id) || $storeLocation->district_id === '0')) {
                return response()->json([
                    'error' => 'Kecamatan lokasi toko belum lengkap.',
                ], 422);
            }

            if ($isKomerce && ! $request->filled('destination_district')) {
                return response()->json([
                    'error' => 'Kecamatan alamat tujuan belum lengkap.',
                ], 422);
            }

            $origin = $isKomerce ? $storeLocation->district_id : $storeLocation->city_id;
            $destination = $isKomerce ? $request->destination_district : $request->destination;
            $originMeta = [
                'seller_id' => (int) $request->seller_id,
                'province' => $storeLocation->province_name,
                'city' => $storeLocation->city_name,
                'district' => $storeLocation->district_name,
                'location_id' => (string) $origin,
            ];
            $endpoint = $isKomerce
                ? rtrim($this->baseUrl, '/') . '/calculate/district/domestic-cost'
                : rtrim($this->baseUrl, '/') . '/cost';

            // TAMBAHAN ->withoutVerifying() UNTUK MENGATASI CURL ERROR 60
            $response = Http::withoutVerifying()->asForm()->withHeaders([
                'Accept' => 'application/json',
                'key' => $this->apiKey
            ])->post($endpoint, [
                'origin' => $origin,
                'destination' => $destination,
                'weight' => $request->weight,
                'courier' => strtolower($request->courier)
            ]);

            if ($response->successful()) {
                if ($isKomerce) {
                    // Konversi response Komerce agar cocok dengan format bacaan Flutter (Starter)
                    $data = $response->json()['data'] ?? [];
                    $mapped = collect($data)->map(function ($item) use ($originMeta) {
                        return [
                            'service' => $item['service'] ?? ($item['code'] ?? ''),
                            'description' => $item['description'] ?? ($item['name'] ?? ''),
                            'cost' => [
                                [
                                    'value' => (int) ($item['cost'] ?? ($item['price'] ?? 0)),
                                    'etd' => $item['etd'] ?? '',
                                    'note' => ''
                                ]
                            ],
                            'origin' => $originMeta,
                        ];
                    })->values()->toArray();

                    return response()->json($mapped)->header('Cache-Control', 'no-store');
                } else {
                    $results = $response->json()['rajaongkir']['results'][0]['costs'] ?? [];
                    $results = collect($results)
                        ->map(fn ($item) => array_merge($item, ['origin' => $originMeta]))
                        ->values()
                        ->all();

                    return response()->json($results)->header('Cache-Control', 'no-store');
                }
            }

            return response()->json(['error' => 'Gagal hitung ongkir', 'detail' => $response->json()], 502);
        } catch (\Throwable $e) {
            \Log::error("API Mobile checkCost Error: " . $e->getMessage());
            return response()->json(['error' => 'Server Error: ' . $e->getMessage()], 500);
        }
    }
}
