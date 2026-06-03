<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ProductSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('products')->insert([
            [
                'id' => 1, 'name' => 'minyak Kita', 'slug' => 'minyak-kita', 'short_description' => 'hgfgdgfdtgrdtrdgf', 'description' => 'gfxdfserserseerserserser', 'regular_price' => 30000.00, 'sale_price' => 20000.00, 'SKU' => '21313', 'stock_status' => 'instock', 'featured' => 0, 'quantity' => 112, 'image' => '1757405970.png', 'images' => '1757390853-1.png', 'category_id' => 1, 'brand_id' => 1, 'weight_gram' => 1000, 'exp_date' => '2026-11-21', 'created_at' => '2025-09-08 21:07:34', 'updated_at' => '2025-09-09 01:19:30'
            ],
            [
                'id' => 2, 'name' => 'cabe', 'slug' => 'cabe', 'short_description' => 'Hadirkan ledakan rasa pedas yang menggugah selera. Kualitas terbaik untuk setiap masakan Anda!', 'description' => 'Tingkatkan level setiap hidangan Anda dengan produk cabe berkualitas premium dari kami...', 'regular_price' => 30000.00, 'sale_price' => 20000.00, 'SKU' => '21313', 'stock_status' => 'instock', 'featured' => 0, 'quantity' => 123, 'image' => '1757406226.jpg', 'images' => '1757406226-1.jpeg', 'category_id' => 2, 'brand_id' => 2, 'weight_gram' => 500, 'exp_date' => '2026-05-15', 'created_at' => '2025-09-09 01:23:46', 'updated_at' => '2025-09-09 01:23:46'
            ],
            [
                'id' => 3, 'name' => 'kubis', 'slug' => 'kubis', 'short_description' => 'Hadirkan ledakan rasa pedas yang menggugah selera. Kualitas terbaik untuk setiap masakan Anda!', 'description' => 'Tingkatkan level setiap hidangan Anda dengan produk cabe berkualitas premium dari kami...', 'regular_price' => 30000.00, 'sale_price' => 20000.00, 'SKU' => '21313', 'stock_status' => 'instock', 'featured' => 0, 'quantity' => 123, 'image' => '1757406286.jpg', 'images' => '1757406286-1.jpeg', 'category_id' => 2, 'brand_id' => 2, 'weight_gram' => 800, 'exp_date' => '2027-01-10', 'created_at' => '2025-09-09 01:24:47', 'updated_at' => '2025-09-09 01:24:47'
            ],
            [
                'id' => 4, 'name' => 'kacang panjang', 'slug' => 'kacang-panjang', 'short_description' => 'Hadirkan ledakan rasa pedas yang menggugah selera. Kualitas terbaik untuk setiap masakan Anda!', 'description' => 'Tingkatkan level setiap hidangan Anda dengan produk cabe berkualitas premium dari kami...', 'regular_price' => 30000.00, 'sale_price' => 20000.00, 'SKU' => '21313', 'stock_status' => 'instock', 'featured' => 0, 'quantity' => 123, 'image' => '1757406348.jpg', 'images' => '1757406348-1.jpeg', 'category_id' => 2, 'brand_id' => 2, 'weight_gram' => 250, 'exp_date' => '2026-09-03', 'created_at' => '2025-09-09 01:25:48', 'updated_at' => '2025-09-09 01:25:48'
            ],
            [
                'id' => 5, 'name' => 'bawang putih', 'slug' => 'bawang-putih', 'short_description' => 'Hadirkan ledakan rasa pedas yang menggugah selera. Kualitas terbaik untuk setiap masakan Anda!', 'description' => 'Tingkatkan level setiap hidangan Anda dengan produk cabe berkualitas premium dari kami...', 'regular_price' => 30000.00, 'sale_price' => 20000.00, 'SKU' => '21313', 'stock_status' => 'instock', 'featured' => 0, 'quantity' => 123, 'image' => '1757406545.jpg', 'images' => '', 'category_id' => 3, 'brand_id' => 4, 'weight_gram' => 100, 'exp_date' => '2027-04-18', 'created_at' => '2025-09-09 01:29:06', 'updated_at' => '2025-09-09 01:29:06'
            ],
            [
                'id' => 6, 'name' => 'bawang merah', 'slug' => 'bawang-merah', 'short_description' => 'Hadirkan ledakan rasa pedas yang menggugah selera. Kualitas terbaik untuk setiap masakan Anda!', 'description' => 'Tingkatkan level setiap hidangan Anda dengan produk cabe berkualitas premium dari kami...', 'regular_price' => 30000.00, 'sale_price' => 20000.00, 'SKU' => '21313', 'stock_status' => 'instock', 'featured' => 0, 'quantity' => 123, 'image' => '1757406595.jpg', 'images' => '', 'category_id' => 3, 'brand_id' => 3, 'weight_gram' => 100, 'exp_date' => '2027-03-22', 'created_at' => '2025-09-09 01:29:55', 'updated_at' => '2025-09-09 01:29:55'
            ],
            [
                'id' => 7, 'name' => 'kemiri', 'slug' => 'kemiri', 'short_description' => 'Hadirkan ledakan rasa pedas yang menggugah selera. Kualitas terbaik untuk setiap masakan Anda!', 'description' => 'Tingkatkan level setiap hidangan Anda dengan produk cabe berkualitas premium dari kami...', 'regular_price' => 30000.00, 'sale_price' => 20000.00, 'SKU' => '21313', 'stock_status' => 'instock', 'featured' => 0, 'quantity' => 123, 'image' => '1757406649.jpg', 'images' => '', 'category_id' => 3, 'brand_id' => 4, 'weight_gram' => 100, 'exp_date' => '2027-08-01', 'created_at' => '2025-09-09 01:30:49', 'updated_at' => '2025-09-09 01:30:49'
            ],
            [
                'id' => 8, 'name' => 'biji pala', 'slug' => 'biji-pala', 'short_description' => 'Hadirkan ledakan rasa pedas yang menggugah selera. Kualitas terbaik untuk setiap masakan Anda!', 'description' => 'Tingkatkan level setiap hidangan Anda dengan produk cabe berkualitas premium dari kami...', 'regular_price' => 30000.00, 'sale_price' => 20000.00, 'SKU' => '21313', 'stock_status' => 'instock', 'featured' => 1, 'quantity' => 122, 'image' => '1757406891.jpg', 'images' => '1757406891-1.jpeg', 'category_id' => 4, 'brand_id' => 5, 'weight_gram' => 50, 'exp_date' => '2027-07-14', 'created_at' => '2025-09-09 01:34:51', 'updated_at' => '2025-09-10 21:40:08'
            ],
            [
                'id' => 9, 'name' => 'jagung pipil 1kg', 'slug' => 'jagung-pipil-1kg', 'short_description' => 'Tingkatkan level setiap hidangan Anda dengan produk cabe berkualitas premium dari kami.', 'description' => 'Tingkatkan level setiap hidangan Anda dengan produk cabe berkualitas premium dari kami...', 'regular_price' => 30000.00, 'sale_price' => 20000.00, 'SKU' => '21313', 'stock_status' => 'instock', 'featured' => 1, 'quantity' => 123, 'image' => '1757406966.jpg', 'images' => '1757406966-1.jpeg', 'category_id' => 4, 'brand_id' => 5, 'weight_gram' => 1000, 'exp_date' => '2026-12-25', 'created_at' => '2025-09-09 01:36:06', 'updated_at' => '2025-09-09 01:36:06'
            ],
            [
                'id' => 10, 'name' => 'kacang hijau', 'slug' => 'kacang-hijau', 'short_description' => 'Tingkatkan level setiap hidangan Anda dengan produk cabe berkualitas premium dari kami.', 'description' => 'Tingkatkan level setiap hidangan Anda dengan produk cabe berkualitas premium dari kami...', 'regular_price' => 30000.00, 'sale_price' => 20000.00, 'SKU' => '21313', 'stock_status' => 'instock', 'featured' => 1, 'quantity' => 123, 'image' => '1757407056.jpg', 'images' => '1757407056-1.jpeg', 'category_id' => 4, 'brand_id' => 5, 'weight_gram' => 1000, 'exp_date' => '2027-09-30', 'created_at' => '2025-09-09 01:37:37', 'updated_at' => '2025-09-09 01:37:37'
            ],
            [
                'id' => 11, 'name' => 'Nescafe Ice Black', 'slug' => 'nescafe-ice-black', 'short_description' => 'Sensasi es kopi hitam ala kafe yang praktis! Rasa kopi mantap menyegarkan untuk bangkitkan mood.', 'description' => 'Nikmati pengalaman minum es kopi hitam berkualitas kafe di mana saja dan kapan saja dengan Nescafé Ice Black...', 'regular_price' => 20000.00, 'sale_price' => 15000.00, 'SKU' => 'N1', 'stock_status' => 'instock', 'featured' => 0, 'quantity' => 60, 'image' => '1757407432.jpg', 'images' => '', 'category_id' => 5, 'brand_id' => 6, 'weight_gram' => 250, 'exp_date' => '2026-08-17', 'created_at' => '2025-09-09 01:43:52', 'updated_at' => '2025-09-09 02:01:49'
            ],
            [
                'id' => 12, 'name' => 'Nescafe Caramel', 'slug' => 'nescafe-caramel', 'short_description' => 'Perpaduan kopi, susu, dan saus karamel mewah. Manjakan dirimu dengan sensasi kopi ala kafe!', 'description' => 'Hadirkan kenikmatan kopi ala kafe langsung ke genggaman Anda dengan Nescafé Gold Caramel Macchiato...', 'regular_price' => 19000.00, 'sale_price' => 17000.00, 'SKU' => 'N2', 'stock_status' => 'instock', 'featured' => 1, 'quantity' => 50, 'image' => '1757407545.jpg', 'images' => '', 'category_id' => 5, 'brand_id' => 6, 'weight_gram' => 250, 'exp_date' => '2026-07-07', 'created_at' => '2025-09-09 01:45:45', 'updated_at' => '2025-09-09 02:01:39'
            ],
            [
                'id' => 13, 'name' => 'Nescafe Clasico', 'slug' => 'nescafe-clasico', 'short_description' => '100% kopi murni dengan rasa intens dan aroma kaya. Awali harimu dengan secangkir semangat sejati!', 'description' => 'Temukan kembali cita rasa kopi hitam yang otentik dengan Nescafé Clásico...', 'regular_price' => 25000.00, 'sale_price' => 20000.00, 'SKU' => 'NC', 'stock_status' => 'instock', 'featured' => 1, 'quantity' => 52, 'image' => '1757407678.jpg', 'images' => '', 'category_id' => 5, 'brand_id' => 6, 'weight_gram' => 200, 'exp_date' => '2027-02-14', 'created_at' => '2025-09-09 01:47:59', 'updated_at' => '2025-09-12 20:25:22'
            ],
        ]);
    }
}