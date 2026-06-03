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
        Schema::table('contacts', function (Blueprint $table) {
            // Tambahkan kolom baru untuk menandai pesan yang sudah dibaca
            // Kolom ini bisa berisi tanggal dan waktu kapan pesan dibaca
            $table->timestamp('read_at')->nullable()->after('comment');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('contacts', function (Blueprint $table) {
            // Hapus kolom jika migrasi di-rollback
            $table->dropColumn('read_at');
        });
    }
};

