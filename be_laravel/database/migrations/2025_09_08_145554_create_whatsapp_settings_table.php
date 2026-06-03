<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB; // <-- Tambahkan ini untuk menggunakan DB facade

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('whatsapp_settings', function (Blueprint $table) {
            $table->id();
            // Kolom untuk menyimpan nama pengaturan, contoh: 'whatsapp_number'
            // Dibuat unik agar tidak ada nama pengaturan yang sama.
            $table->string('key')->unique(); 
            
            // Kolom untuk menyimpan nilai dari pengaturan, yaitu nomor WhatsApp-nya.
            $table->text('value')->nullable(); 

            $table->timestamps();
        });

        // Menambahkan data awal (nomor WhatsApp default) ke dalam tabel
        // Ini penting agar ada nilai awal yang bisa digunakan oleh aplikasi.
        DB::table('whatsapp_settings')->insert([
            'key' => 'whatsapp_number',
            'value' => '62895623110888', // Nomor default Anda
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('whatsapp_settings');
    }
};

