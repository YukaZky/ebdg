<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('product_variations')) {
            Schema::create('product_variations', function (Blueprint $table) {
                $table->id();
                $table->foreignId('product_id')->constrained('products')->cascadeOnDelete();
                $table->string('name');
                $table->text('description')->nullable();
                $table->decimal('regular_price', 15, 2)->default(0);
                $table->decimal('sale_price', 15, 2)->nullable();
                $table->integer('weight')->default(0);
                $table->integer('quantity')->default(0);
                $table->string('image')->nullable();
                $table->timestamps();
            });

            return;
        }

        Schema::table('product_variations', function (Blueprint $table) {
            if (! Schema::hasColumn('product_variations', 'description')) {
                $table->text('description')->nullable()->after('name');
            }

            if (! Schema::hasColumn('product_variations', 'regular_price')) {
                $table->decimal('regular_price', 15, 2)->default(0)->after('description');
            }

            if (! Schema::hasColumn('product_variations', 'sale_price')) {
                $table->decimal('sale_price', 15, 2)->nullable()->after('regular_price');
            }

            if (! Schema::hasColumn('product_variations', 'weight')) {
                $table->integer('weight')->default(0)->after('sale_price');
            }

            if (! Schema::hasColumn('product_variations', 'quantity')) {
                $table->integer('quantity')->default(0)->after('weight');
            }

            if (! Schema::hasColumn('product_variations', 'image')) {
                $table->string('image')->nullable()->after('quantity');
            }
        });
    }

    public function down(): void
    {
        // Migration ini bersifat pengaman struktur tabel lama/restore database.
        // Kolom tidak dihapus agar data variasi produk yang sudah ada tetap aman.
    }
};
