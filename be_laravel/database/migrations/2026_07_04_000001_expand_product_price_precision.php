<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->decimal('regular_price', 15, 2)->default(0)->change();
            $table->decimal('sale_price', 15, 2)->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->decimal('regular_price', 8, 2)->change();
            $table->decimal('sale_price', 8, 2)->nullable()->change();
        });
    }
};
