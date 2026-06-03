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
            // Menambahkan kolom setelah kolom 'total'
            $table->string('mode_pengiriman')->nullable()->after('total');
            $table->string('jenis_pengiriman')->nullable()->after('mode_pengiriman');
            $table->decimal('ongkir', 10, 2)->default(0.00)->after('jenis_pengiriman');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('mode_pengiriman');
            $table->dropColumn('jenis_pengiriman');
            $table->dropColumn('ongkir');
        });
    }
};