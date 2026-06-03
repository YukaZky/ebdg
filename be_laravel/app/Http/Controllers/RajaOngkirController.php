<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class RajaOngkirController extends Controller
{
    /**
     * GET /destination/province
     */
    public function getProvinces()
    {
        try {
            $response = Http::withHeaders([
                'Accept' => 'application/json',
                'key'    => config('rajaongkir.api_key'),
            ])->get(config('rajaongkir.base_url') . '/destination/province');

            if ($response->successful()) {
                return response()->json($response->json()['data'] ?? []);
            }
            return response()->json(['error' => 'Gagal mengambil provinsi'], 502);
        } catch (\Throwable $e) {
            return response()->json(['error' => 'Error server'], 500);
        }
    }

    /**
     * GET /destination/city/{provinceId}
     */
    public function getCities($provinceId)
    {
        try {
            $response = Http::withHeaders([
                'Accept' => 'application/json',
                'key'    => config('rajaongkir.api_key'),
            ])->get(config('rajaongkir.base_url') . "/destination/city/{$provinceId}");

            if ($response->successful()) {
                return response()->json($response->json()['data'] ?? []);
            }
            return response()->json(['error' => 'Gagal mengambil kota'], 502);
        } catch (\Throwable $e) {
            return response()->json(['error' => 'Error server'], 500);
        }
    }

    /**
     * GET /destination/district/{cityId}
     */
    public function getDistricts($cityId)
    {
        try {
            $response = Http::withHeaders([
                'Accept' => 'application/json',
                'key'    => config('rajaongkir.api_key'),
            ])->get(config('rajaongkir.base_url') . "/destination/district/{$cityId}");

            if ($response->successful()) {
                return response()->json($response->json()['data'] ?? []);
            }
            return response()->json(['error' => 'Gagal mengambil kecamatan'], 502);
        } catch (\Throwable $e) {
            return response()->json(['error' => 'Error server'], 500);
        }
    }

    /**
     * POST /calculate/domestic-cost
     * Body: origin, destination, weight, courier
     */
    public function checkOngkir(Request $request)
    {
        $validated = $request->validate([
            'district_id' => ['required'],
            'weight'      => ['required', 'integer', 'min:1'],
            'courier'     => ['required', 'string'],
        ]);

        $origin = config('rajaongkir.origin_subdistrict_id');
        if (!$origin) {
            return response()->json([
                'error'   => true,
                'message' => 'Origin kecamatan belum diset di .env (RO_ORIGIN_SUBDISTRICT_ID)',
            ], 422);
        }

        try {
            $response = Http::asForm()->withHeaders([
                'Accept' => 'application/json',
                'key'    => config('rajaongkir.api_key'),
            ])->post(config('rajaongkir.base_url') . '/calculate/domestic-cost', [
                'origin'      => (int) $origin,                       // subdistrict asal (kecamatan)
                'destination' => (int) $validated['district_id'],     // subdistrict tujuan (kecamatan)
                'weight'      => (int) $validated['weight'],          // gram (WAJIB > 0)
                'courier'     => strtolower($validated['courier']),   // jne|jnt|sicepat|pos|anteraja|tiki|ninja|wahana|lion
            ]);

            if (!$response->successful()) {
                return response()->json([
                    'error'   => true,
                    'message' => 'Gagal menghitung ongkir',
                    'detail'  => $response->json(),
                ], 502);
            }

            $data = $response->json()['data'] ?? [];

            // 🔁 Transform -> samakan dengan yang dibaca di JS:
            // value.service, value.description, value.etd, value.cost
            $results = collect($data)->map(function ($row) {
                return [
                    'service'     => $row['service']      ?? ($row['code'] ?? ''),         // ex: REG / YES
                    'description' => $row['description']  ?? ($row['name'] ?? ''),         // ex: Layanan Reguler
                    'etd'         => $row['etd']          ?? ($row['etd_from_to'] ?? ''),  // ex: 2-3 HARI
                    'cost'        => (int) ($row['cost']  ?? ($row['price'] ?? 0)),        // ex: 15000
                ];
            })->values();

            // 👇 Frontend kamu mengharapkan array langsung (bukan dibungkus objek)
            // DIGANTI JADI
            return response()->json([
                'error'   => false,
                'results' => $results,   // <-- frontend kamu baca dari response.results
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'error'   => true,
                'message' => 'Error server: ' . $e->getMessage(),
            ], 500);
        }
    }
}
