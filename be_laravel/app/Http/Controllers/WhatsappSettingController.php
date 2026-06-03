<?php

// Namespace diubah agar sesuai dengan lokasi file Anda
namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\WhatsappSetting;
use App\Models\Contact; // <-- [BARU] Import model Contact
use App\Models\Order;   // <-- [BARU] Import model Order

class WhatsappSettingController extends Controller
{
    /**
     * Menampilkan form untuk mengedit nomor WhatsApp.
     */
    public function edit()
    {
        // Cari atau buat record pengaturan WhatsApp
        $whatsappSetting = WhatsappSetting::firstOrCreate(
            ['key' => 'whatsapp_number'],
            ['value' => '6281234567890'] // Nilai default jika baru dibuat
        );

        // [BARU] Ambil data notifikasi yang dibutuhkan oleh layout admin
        $totalContacts = Contact::whereNull('read_at')->count();
        $totalOrdered = Order::where('status', 'ordered')->count();
        $dashboardDatas = collect([(object)['TotalOrdered' => $totalOrdered]]);

        // Kirim semua data yang dibutuhkan ke view
        return view('admin.whatsapp-edit', compact('whatsappSetting', 'totalContacts', 'dashboardDatas'));
    }

    /**
     * Menyimpan perubahan nomor WhatsApp ke database.
     */
    public function update(Request $request)
    {
        // Validasi input
        $request->validate([
            'whatsapp_number' => 'required|numeric',
        ]);

        // Perbarui atau buat record di database
        WhatsappSetting::updateOrCreate(
            ['key'   => 'whatsapp_number'],
            ['value' => $request->whatsapp_number]
        );

        // Kembali dengan pesan sukses
        return redirect()->back()->with('success', 'Nomor WhatsApp berhasil diperbarui.');
    }
}
