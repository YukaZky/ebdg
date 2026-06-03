<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            // Mengubah kolom 'status' untuk menambahkan 'shipping'
            // Nilai yang ada di dalam array harus sama persis dengan yang sudah ada di database Anda, plus 'shipping'
            $table->enum('status', ['ordered', 'shipping', 'delivered', 'canceled'])->default('ordered')->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            // Ini akan mengembalikan struktur kolom ke semula jika Anda ingin membatalkan migrasi
            $table->enum('status', ['ordered', 'delivered', 'canceled'])->default('ordered')->change();
        });
    }
};