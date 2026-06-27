<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('coupons') && ! Schema::hasColumn('coupons', 'id_user')) {
            Schema::table('coupons', function (Blueprint $table) {
                $table->unsignedBigInteger('id_user')->nullable()->index()->after('id');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('coupons') && Schema::hasColumn('coupons', 'id_user')) {
            Schema::table('coupons', function (Blueprint $table) {
                $table->dropColumn('id_user');
            });
        }
    }
};
