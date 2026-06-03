<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Transaction;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;         // <-- Ditambahkan
use Illuminate\Validation\Rules\Password;     // <-- Ditambahkan

class UserController extends Controller
{
    public function index()
    {
        return view('user.index');
    }

    public function orders()
    {
        $orders = Order::where('user_id', Auth::user()->id)->orderBy('created_at', 'DESC')->paginate(10);
        return view('user.orders', compact('orders'));
    }

    public function order_details($order_id)
    {
        $order = Order::where('user_id', Auth::user()->id)->where('id', $order_id)->first();
        if ($order) {
            $orderItems = OrderItem::where('order_id', $order_id)->orderBy('id')->paginate(12);
            $transaction = Transaction::where('order_id', $order_id)->first();
            return view('user.order-details', compact('order', 'orderItems', 'transaction'));
        } else {
            return redirect()->route('login');
        }
    }

    public function order_cancel(Request $request)
    {
        $order = Order::find($request->order_id);
        $order->status = 'canceled';
        $order->canceled_date = Carbon::now();
        $order->save();
        return back()->with('status', 'Pesanan telah dibatalkan!');
    }

    // =======================================================
    // METODE BARU DITAMBAHKAN DI BAWAH INI
    // =======================================================

    /**
     * Menampilkan halaman detail akun.
     */
    public function details()
    {
        return view('user.account-details');
    }

    /**
     * Memperbarui informasi profil pengguna.
     */
    public function updateProfile(Request $request)
    {
        // Validasi input
        $request->validate([
            'name' => 'required|string|max:255',
        ]);

        // Ambil pengguna yang sedang login
        $user = Auth::user();
        // Update nama
        $user->name = $request->name;
        // Simpan perubahan
        $user->save();

        // Kembali ke halaman sebelumnya dengan pesan sukses
        return back()->with('profile_status', 'Profil berhasil diperbarui!');
    }

    /**
     * Memperbarui kata sandi pengguna.
     */
    public function updatePassword(Request $request)
    {
        // Validasi input
        $request->validate([
            'current_password' => 'required|string',
            'new_password' => ['required', 'string', 'confirmed', Password::min(8)],
        ]);

        $user = Auth::user();

        // Cek apakah kata sandi saat ini cocok
        if (!Hash::check($request->current_password, $user->password)) {
            // Jika tidak cocok, kembali dengan pesan error
            return back()->withErrors(['current_password' => 'Kata sandi saat ini tidak cocok.']);
        }

        // Update kata sandi dengan yang baru (sudah di-hash)
        $user->password = Hash::make($request->new_password);
        $user->save();

        // Kembali ke halaman sebelumnya dengan pesan sukses
        return back()->with('password_status', 'Kata sandi berhasil diubah!');
    }
}