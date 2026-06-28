<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('orders', 'shipping_breakdown')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->json('shipping_breakdown')->nullable()->after('ongkir');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('orders', 'shipping_breakdown')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->dropColumn('shipping_breakdown');
            });
        }
    }
};
