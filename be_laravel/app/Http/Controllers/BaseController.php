<?php

namespace App\Http\Controllers;

use App\Models\About;
use App\Models\Contact;
use App\Models\Order;
use Illuminate\Support\Facades\View;

class BaseController extends Controller
{
    public function __construct()
    {
        // Bentuk data dipertahankan agar tetap kompatibel dengan layout admin.
        // Menggunakan model Order mencegah masalah perbedaan huruf besar-kecil
        // nama tabel pada server Linux/MySQL (Orders berbeda dengan orders).
        $dashboardDatas = [
            (object) [
                'TotalOrdered' => Order::where('status', 'ordered')->count(),
            ],
        ];
        View::share('dashboardDatas', $dashboardDatas);

        $totalContacts = Contact::count();
        View::share('totalContacts', $totalContacts);

        $about_us_data = About::first();
        View::share('about_us_data', $about_us_data);
    }
}
