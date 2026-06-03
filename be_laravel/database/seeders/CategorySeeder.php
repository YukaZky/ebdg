<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('categories')->insert([
            ['id' => 1, 'name' => 'minyak', 'slug' => 'minyak', 'image' => '1757405850.png', 'parent_id' => null, 'created_at' => '2025-09-08 21:04:17', 'updated_at' => '2025-09-09 01:17:30'],
            ['id' => 2, 'name' => 'sayur', 'slug' => 'sayur', 'image' => '1757406068.jpg', 'parent_id' => null, 'created_at' => '2025-09-09 01:21:08', 'updated_at' => '2025-09-09 01:21:08'],
            ['id' => 3, 'name' => 'bumbu dapur', 'slug' => 'bumbu-dapur', 'image' => '1757406443.jpg', 'parent_id' => null, 'created_at' => '2025-09-09 01:27:23', 'updated_at' => '2025-09-09 01:27:23'],
            ['id' => 4, 'name' => 'biji-bijian', 'slug' => 'biji-bijian', 'image' => '1757406778.jpg', 'parent_id' => null, 'created_at' => '2025-09-09 01:32:58', 'updated_at' => '2025-09-09 01:32:58'],
            ['id' => 5, 'name' => 'Kopi', 'slug' => 'kopi', 'image' => '1757407177.jpg', 'parent_id' => null, 'created_at' => '2025-09-09 01:39:37', 'updated_at' => '2025-09-09 01:39:37'],
            ['id' => 6, 'name' => 'sirup', 'slug' => 'sirup', 'image' => '1757408645.jpg', 'parent_id' => null, 'created_at' => '2025-09-09 02:04:05', 'updated_at' => '2025-09-09 02:04:05'],
            ['id' => 7, 'name' => 'boncabe', 'slug' => 'boncabe', 'image' => '1757408663.jpg', 'parent_id' => null, 'created_at' => '2025-09-09 02:04:23', 'updated_at' => '2025-09-09 02:04:23'],
            ['id' => 8, 'name' => 'beras', 'slug' => 'beras', 'image' => '1757408680.png', 'parent_id' => null, 'created_at' => '2025-09-09 02:04:41', 'updated_at' => '2025-09-09 02:04:41'],
        ]);
    }
}