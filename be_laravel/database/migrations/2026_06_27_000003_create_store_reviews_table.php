<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('store_reviews')) {
            Schema::create('store_reviews', function (Blueprint $table) {
                $table->id();
                $table->foreignId('store_id')->constrained('store_profiles')->onDelete('cascade');
                $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
                $table->unsignedTinyInteger('rating');
                $table->text('review')->nullable();
                $table->timestamps();
                $table->unique(['store_id', 'user_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('store_reviews');
    }
};
