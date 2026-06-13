<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('addresses', function (Blueprint $table) {
            $table->string('name')->nullable(); // Nama Penerima
            $table->string('phone')->nullable(); // Nomor HP
            $table->string('label')->default('Rumah'); // Label (Rumah/Kantor)
            $table->text('note')->nullable(); // Catatan untuk Kurir
            $table->boolean('is_store_address')->default(false); // Penanda apakah ini alamat toko
            
            // Note: Pastikan kolom province_id dan city_id sudah ada di tabel ini sebelumnya. 
            // Jika belum ada, tambahkan juga di sini:
            // $table->string('province_id')->nullable();
            // $table->string('city_id')->nullable();
        });
    }

    public function down()
    {
        Schema::table('addresses', function (Blueprint $table) {
            $table->dropColumn(['name', 'phone', 'label', 'note', 'is_store_address']);
        });
    }
};