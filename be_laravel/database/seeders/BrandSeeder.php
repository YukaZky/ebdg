<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class BrandSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('brands')->insert([
            ['id' => 1, 'name' => 'minyak Kita', 'slug' => 'minyak-kita', 'image' => '1757405951.png', 'created_at' => '2025-09-08 21:05:04', 'updated_at' => '2025-09-09 01:19:11', 'category_id' => 1],
            ['id' => 2, 'name' => 'fresh', 'slug' => 'fresh', 'image' => '1757406089.jpeg', 'created_at' => '2025-09-09 01:21:29', 'updated_at' => '2025-09-09 01:21:29', 'category_id' => 2],
            ['id' => 3, 'name' => 'desamu', 'slug' => 'desamu', 'image' => '1757406464.jpeg', 'created_at' => '2025-09-09 01:27:44', 'updated_at' => '2025-09-09 01:27:44', 'category_id' => 3],
            ['id' => 4, 'name' => 'desakita', 'slug' => 'desakita', 'image' => '1757406485.jpeg', 'created_at' => '2025-09-09 01:28:05', 'updated_at' => '2025-09-09 01:28:05', 'category_id' => 3],
            ['id' => 5, 'name' => 'kacang-kacangan', 'slug' => 'kacang-kacangan', 'image' => '1757406806.jpeg', 'created_at' => '2025-09-09 01:33:26', 'updated_at' => '2025-09-09 01:33:26', 'category_id' => 4],
            ['id' => 6, 'name' => 'Nescafe', 'slug' => 'nescafe', 'image' => '1757407239.jpeg', 'created_at' => '2025-09-09 01:40:39', 'updated_at' => '2025-09-09 01:40:39', 'category_id' => 5],
        ]);
    }
}