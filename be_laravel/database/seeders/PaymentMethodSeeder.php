<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PaymentMethodSeeder extends Seeder
{
    public function run(): void
    {
        // Mengosongkan data lama agar tidak duplikat saat dijalankan kembali
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        DB::table('payment_methods')->truncate();
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        DB::table('payment_methods')->insert([
            [
                'name' => 'BCA Virtual Account',
                'payment_type' => 'bank_transfer',
                'bank_code' => 'bca',
                'icon_path' => '1.png',
                'is_active' => true,
                'created_at' => now(), 'updated_at' => now()
            ],
            [
                'name' => 'BNI Virtual Account',
                'payment_type' => 'bank_transfer',
                'bank_code' => 'bni',
                'icon_path' => '2.png',
                'is_active' => true,
                'created_at' => now(), 'updated_at' => now()
            ],
            [
                'name' => 'BRI Virtual Account',
                'payment_type' => 'bank_transfer',
                'bank_code' => 'bri',
                'icon_path' => '3.png',
                'is_active' => true,
                'created_at' => now(), 'updated_at' => now()
            ],
            [
                'name' => 'Permata Virtual Account',
                'payment_type' => 'bank_transfer',
                'bank_code' => 'permata',
                'icon_path' => '4.png',
                'is_active' => true,
                'created_at' => now(), 'updated_at' => now()
            ],
            [
                'name' => 'Mandiri Bill / VA',
                'payment_type' => 'gopay', 
                'bank_code' => 'mandiri',
                'icon_path' => '5.png',
                'is_active' => true,
                'created_at' => now(), 'updated_at' => now()
            ],
            [
                'name' => 'QRIS (OVO, DANA, LinkAja, ShopeePay, dll)',
                'payment_type' => 'qris',
                'bank_code' => null,
                'icon_path' => '6.png',
                'is_active' => true,
                'created_at' => now(), 'updated_at' => now()
            ],
            [
                'name' => 'GoPay Instant Wallet',
                'payment_type' => 'gopay',
                'bank_code' => null,
                'icon_path' => '7.png',
                'is_active' => true,
                'created_at' => now(), 'updated_at' => now()
            ]
        ]);
    }
}