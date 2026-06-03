<?php

namespace App\Http\Controllers;

use App\Models\Address;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AddressController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth'); // pastikan user login
    }

    /** LIST alamat (halaman index) */
    public function index()
    {
        $addresses = Address::where('user_id', Auth::id())
            ->orderByDesc('isdefault')
            ->orderByDesc('created_at')
            ->get();

        return view('user.address', compact('addresses')); // file yg sudah kamu punya
    }

    /** FORM tambah alamat */
    public function address_add()
    {
        return view('user.address-add');
    }

    /** SIMPAN alamat baru */
    public function address_store(Request $request)
    {
        $request->validate([
    'name'          => 'required|string|max:255',
    'phone'         => 'required|string|max:20',
    'province_id'   => 'required|integer',
    'state'         => 'required|string|max:255',  // nama provinsi
    'city_id'       => 'required|integer',
    'city'          => 'required|string|max:255',  // nama kota
    'district_id'   => 'required|integer',
    'district_name' => 'required|string|max:255',
    'zip'           => 'required|string|max:10',   // ← WAJIB
    'address'       => 'required|string',
    'locality'      => 'nullable|string|max:255',
    'landmark'      => 'nullable|string|max:255',
    'type'          => 'required|string|in:Rumah,Kantor,Lainnya',
    'isdefault'     => 'nullable|in:1',
]);


       $addr = new Address();
$addr->user_id = Auth::id();

$addr->name     = $request->name;
$addr->phone    = $request->phone;
$addr->address  = $request->address;
$addr->locality = $request->locality;
$addr->landmark = $request->landmark;
$addr->type     = $request->type;
$addr->isdefault = $request->boolean('isdefault') ? 1 : 0;

// --- sinkron RajaOngkir + kolom lama ---
$addr->province_id   = (int) $request->province_id;
$addr->province_name = $request->state;   // simpan nama provinsi
$addr->state         = $request->state;   // ← PENTING: isi kolom lama

$addr->city_id   = (int) $request->city_id;
$addr->city_name = $request->city;        // simpan nama kota
$addr->city      = $request->city;        // ← PENTING: isi kolom lama

$zip = $request->zip;                     // form kirim 'zip'
$addr->postal_code = $zip;                // sinkron ke kolom tambahan
$addr->zip         = $zip;                // ← PENTING: isi kolom lama

$addr->district_id   = (int) $request->district_id;
$addr->district_name = $request->district_name;

$addr->country = 'Indonesia';

$addr->save();


        return redirect()->route('user.address.index')->with('success', 'Alamat berhasil ditambahkan.');
    }

    /** EDIT alamat */
    public function address_edit($id)
    {
        $address = Address::where('id', $id)
            ->where('user_id', Auth::id())
            ->firstOrFail();

        return view('user.address-edit', compact('address'));
    }

    /** UPDATE alamat */
    public function address_update(Request $request, $id)
    {
        $request->validate([
    'name'          => 'required|string|max:255',
    'phone'         => 'required|string|max:20',
    'province_id'   => 'required|integer',
    'state'         => 'required|string|max:255',   // nama provinsi
    'city_id'       => 'required|integer',
    'city'          => 'required|string|max:255',   // nama kota
    'district_id'   => 'required|integer',
    'district_name' => 'required|string|max:255',
    'zip'           => 'required|string|max:10',    // ← WAJIB (bukan postal_code)
    'address'       => 'required|string',
    'locality'      => 'nullable|string|max:255',
    'landmark'      => 'nullable|string|max:255',
    'type'          => 'required|string|in:Rumah,Kantor,Lainnya',
    'isdefault'     => 'nullable|in:1',
]);


       $addr = Address::where('id', $id)->where('user_id', Auth::id())->firstOrFail();

$addr->name     = $request->name;
$addr->phone    = $request->phone;
$addr->address  = $request->address;
$addr->locality = $request->locality;
$addr->landmark = $request->landmark;
$addr->type     = $request->type;
$addr->isdefault = $request->boolean('isdefault') ? 1 : 0;

// --- sinkron RajaOngkir + kolom lama ---
$addr->province_id   = (int) $request->province_id;
$addr->province_name = $request->state;
$addr->state         = $request->state;          // ← penting

$addr->city_id   = (int) $request->city_id;
$addr->city_name = $request->city;
$addr->city      = $request->city;               // ← penting

$zip = $request->zip;
$addr->postal_code = $zip;                       // simpan juga ke postal_code
$addr->zip         = $zip;                       // ← penting

$addr->district_id   = (int) $request->district_id;
$addr->district_name = $request->district_name;

$addr->country = 'Indonesia';

$addr->save();

        return redirect()->route('user.address.index')->with('success', 'Alamat berhasil diperbarui.');
    }

    /** HAPUS alamat */
    public function address_delete($id)
    {
        $addr = Address::where('id', $id)
            ->where('user_id', Auth::id())
            ->firstOrFail();

        $addr->delete();

        return redirect()->route('user.address.index')->with('success', 'Alamat berhasil dihapus.');
    }
}
