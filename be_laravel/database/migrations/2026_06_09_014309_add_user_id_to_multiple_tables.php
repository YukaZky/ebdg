<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private array $tables = [
        'brands',
        'abouts',
        'orders',
        'transactions',
        'whatsapp_settings'
    ];

    public function up(): void
    {
        foreach ($this->tables as $tableName) {
            // Cek apakah tabelnya ada DAN kolom user_id BELUM ada
            if (Schema::hasTable($tableName) && !Schema::hasColumn($tableName, 'user_id')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->foreignId('user_id')->nullable()->constrained('users')->cascadeOnDelete();
                });
            }
        }
    }

    public function down(): void
    {
        foreach ($this->tables as $tableName) {
            // Cek apakah tabelnya ada DAN kolom user_id ADA (untuk di-drop)
            if (Schema::hasTable($tableName) && Schema::hasColumn($tableName, 'user_id')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->dropForeign(['user_id']);
                    $table->dropColumn('user_id');
                });
            }
        }
    }
};