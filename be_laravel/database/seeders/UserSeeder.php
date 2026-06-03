<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Membuat user admin
        User::create([
            'name' => 'Admin',
            'email' => 'admin@gmail.com',
            'password' => Hash::make('password'), // Password di-hash untuk keamanan
            'utype' => 'ADM', // Sesuai permintaan untuk user admin
            'email_verified_at' => now(), // Langsung set email sebagai terverifikasi
        ]);

        // Opsional: Membuat user biasa sebagai contoh
        User::create([
            'name' => 'User Biasa',
            'email' => 'user@gmail.com',
            'password' => Hash::make('password123'),
            'utype' => 'USR', // Nilai default untuk user/pelanggan
            'email_verified_at' => now(),
        ]);
    }
}