<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_methods', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // Contoh: BCA Virtual Account
            $table->string('payment_type'); // bank_transfer, qris, gopay
            $table->string('bank_code')->nullable(); // bca, bri, bni, permata (null jika qris/gopay)
            $table->string('icon_path'); // Tempat menyimpan nama file foto (1.png, 2.jpg, dll)
            $table->boolean('is_active')->default(true); // Untuk kontrol on/off dari admin
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_methods');
    }
};