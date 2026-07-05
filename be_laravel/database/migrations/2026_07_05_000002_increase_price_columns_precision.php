<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('products')) {
            DB::statement('ALTER TABLE products MODIFY regular_price DECIMAL(15,2) NOT NULL DEFAULT 0');
            DB::statement('ALTER TABLE products MODIFY sale_price DECIMAL(15,2) NULL');
        }

        if (Schema::hasTable('product_variations')) {
            DB::statement('ALTER TABLE product_variations MODIFY regular_price DECIMAL(15,2) NOT NULL DEFAULT 0');
            DB::statement('ALTER TABLE product_variations MODIFY sale_price DECIMAL(15,2) NULL');
        }

        if (Schema::hasTable('orders')) {
            DB::statement('ALTER TABLE orders MODIFY subtotal DECIMAL(15,2) NOT NULL DEFAULT 0');
            DB::statement('ALTER TABLE orders MODIFY discount DECIMAL(15,2) NOT NULL DEFAULT 0');
            DB::statement('ALTER TABLE orders MODIFY tax DECIMAL(15,2) NOT NULL DEFAULT 0');
            DB::statement('ALTER TABLE orders MODIFY total DECIMAL(15,2) NOT NULL DEFAULT 0');
        }

        if (Schema::hasTable('order_items')) {
            DB::statement('ALTER TABLE order_items MODIFY price DECIMAL(15,2) NOT NULL DEFAULT 0');
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('products')) {
            DB::statement('ALTER TABLE products MODIFY regular_price DECIMAL(8,2) NOT NULL DEFAULT 0');
            DB::statement('ALTER TABLE products MODIFY sale_price DECIMAL(8,2) NULL');
        }

        if (Schema::hasTable('product_variations')) {
            DB::statement('ALTER TABLE product_variations MODIFY regular_price DECIMAL(15,2) NOT NULL DEFAULT 0');
            DB::statement('ALTER TABLE product_variations MODIFY sale_price DECIMAL(15,2) NULL');
        }

        if (Schema::hasTable('orders')) {
            DB::statement('ALTER TABLE orders MODIFY subtotal DECIMAL(8,2) NOT NULL DEFAULT 0');
            DB::statement('ALTER TABLE orders MODIFY discount DECIMAL(8,2) NOT NULL DEFAULT 0');
            DB::statement('ALTER TABLE orders MODIFY tax DECIMAL(8,2) NOT NULL DEFAULT 0');
            DB::statement('ALTER TABLE orders MODIFY total DECIMAL(8,2) NOT NULL DEFAULT 0');
        }

        if (Schema::hasTable('order_items')) {
            DB::statement('ALTER TABLE order_items MODIFY price DECIMAL(8,2) NOT NULL DEFAULT 0');
        }
    }
};
