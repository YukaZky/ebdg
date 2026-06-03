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
        Schema::table('products', function (Blueprint $table) {
            // Menambahkan kolom exp_date setelah kolom quantity
            // Kolom ini bisa kosong (nullable) jika ada produk yang tidak memiliki tanggal kadaluarsa.
            $table->date('exp_date')->nullable()->after('quantity');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            // Menghapus kolom exp_date jika migration di-rollback
            $table->dropColumn('exp_date');
        });
    }
};