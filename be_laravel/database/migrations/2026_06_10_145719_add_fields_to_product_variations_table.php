<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('product_variations', function (Blueprint $table) {
            // Cek jika kolom belum ada, baru tambahkan agar tidak bentrok
            if (!Schema::hasColumn('product_variations', 'regular_price')) {
                $table->decimal('regular_price', 15, 2)->default(0)->after('name');
            }
            if (!Schema::hasColumn('product_variations', 'sale_price')) {
                $table->decimal('sale_price', 15, 2)->nullable()->after('regular_price');
            }
            if (!Schema::hasColumn('product_variations', 'weight')) {
                $table->integer('weight')->default(0)->after('sale_price');
            }
            if (!Schema::hasColumn('product_variations', 'quantity')) {
                $table->integer('quantity')->default(0)->after('weight');
            }
        });
    }

    public function down(): void
    {
        Schema::table('product_variations', function (Blueprint $table) {
            $table->dropColumn(['regular_price', 'sale_price', 'weight', 'quantity']);
        });
    }
};