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
        Schema::table('brands', function (Blueprint $table) {
            // Tambahkan baris ini untuk membuat kolom foreign key
            $table->foreignId('category_id')->constrained()->onDelete('cascade')->after('id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('brands', function (Blueprint $table) {
            // Tambahkan baris ini untuk menghapus foreign key dan kolomnya
            $table->dropForeign(['category_id']);
            $table->dropColumn('category_id');
        });
    }
};