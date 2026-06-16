<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('addresses', function (Blueprint $table) {
            if (! Schema::hasColumn('addresses', 'name')) {
                $table->string('name')->nullable(); // Nama Penerima
            }

            if (! Schema::hasColumn('addresses', 'phone')) {
                $table->string('phone')->nullable(); // Nomor HP
            }

            if (! Schema::hasColumn('addresses', 'label')) {
                $table->string('label')->default('Rumah'); // Label (Rumah/Kantor)
            }

            if (! Schema::hasColumn('addresses', 'note')) {
                $table->text('note')->nullable(); // Catatan untuk Kurir
            }

            if (! Schema::hasColumn('addresses', 'is_store_address')) {
                $table->boolean('is_store_address')->default(false); // Penanda apakah ini alamat toko
            }
        });
    }

    public function down(): void
    {
        Schema::table('addresses', function (Blueprint $table) {
            if (Schema::hasColumn('addresses', 'label')) {
                $table->dropColumn('label');
            }

            if (Schema::hasColumn('addresses', 'note')) {
                $table->dropColumn('note');
            }

            if (Schema::hasColumn('addresses', 'is_store_address')) {
                $table->dropColumn('is_store_address');
            }
        });
    }
};