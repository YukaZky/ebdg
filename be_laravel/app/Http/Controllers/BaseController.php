<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\View;
use App\Models\Contact;
use App\Models\About; // 1. Tambahkan model About di sini

class BaseController extends Controller
{
    public function __construct()
    {
        // Data dashboard (struktur ini tidak diubah)
        $dashboardDatas = DB::select("
            SELECT SUM(IF(status='ordered', 1, 0)) AS TotalOrdered 
            FROM Orders
        ");
        View::share('dashboardDatas', $dashboardDatas);

        // Data kontak (struktur ini tidak diubah)
        $totalContacts = Contact::count();
        View::share('totalContacts', $totalContacts);

        // --- TAMBAHKAN BLOK DI BAWAH INI ---
        // 2. Mengambil data profil usaha (About Us)
        $about_us_data = About::first();
        
        // 3. Membagikan data profil usaha ke semua view
        View::share('about_us_data', $about_us_data);
        // --- AKHIR BLOK TAMBAHAN ---
    }
}