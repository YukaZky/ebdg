<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
{
    Schema::table('products', function (Blueprint $table) {
        if (!Schema::hasColumn('products', 'weight')) {
            $table->string('weight')->nullable();
        }
        if (!Schema::hasColumn('products', 'exp_date')) {
            $table->date('exp_date')->nullable();
        }
    });
}

public function down(): void
{
    Schema::table('products', function (Blueprint $table) {
        $table->dropColumn(['weight', 'exp_date']);
    });
}
};
