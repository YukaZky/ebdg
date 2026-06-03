<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            CategorySeeder::class,
            BrandSeeder::class,
            ProductSeeder::class,
            // Anda juga bisa menambahkan UserSeeder dan MonthSeeder di sini jika perlu
            UserSeeder::class,
            MonthSeeder::class,
        ]);
    }
}