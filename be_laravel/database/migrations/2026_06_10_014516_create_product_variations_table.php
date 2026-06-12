<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_variations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->string('name'); 
            $table->text('description')->nullable(); 
            
            // Tambahan Kolom Baru Agar Sinkron dengan Form Dinamis Flutter
            $table->decimal('regular_price', 15, 2)->default(0); // Harga reguler variasi
            $table->decimal('sale_price', 15, 2)->nullable();    // Harga promo variasi
            $table->integer('weight')->default(0);               // Berat gram variasi
            $table->integer('quantity')->default(0);             // Kuantitas stok variasi
            
            $table->string('image')->nullable(); 
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_variations');
    }
};