<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
{
    Schema::table('products', function (Blueprint $table) {
        if (!Schema::hasColumn('products', 'weight_gram')) {
            $table->unsignedInteger('weight_gram')->default(0)->after('regular_price');
        }
    });
}

public function down(): void
{
    Schema::table('products', function (Blueprint $table) {
        if (Schema::hasColumn('products','weight_gram')) {
            $table->dropColumn('weight_gram');
        }
    });
}

};
