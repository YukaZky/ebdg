<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('store_profiles', function (Blueprint $table) {
            if (! Schema::hasColumn('store_profiles', 'bank_name')) {
                $table->string('bank_name')->nullable()->after('website');
            }

            if (! Schema::hasColumn('store_profiles', 'bank_account_number')) {
                $table->string('bank_account_number', 50)->nullable()->after('bank_name');
            }

            if (! Schema::hasColumn('store_profiles', 'bank_account_name')) {
                $table->string('bank_account_name', 150)->nullable()->after('bank_account_number');
            }
        });
    }

    public function down(): void
    {
        Schema::table('store_profiles', function (Blueprint $table) {
            foreach (['bank_account_name', 'bank_account_number', 'bank_name'] as $column) {
                if (Schema::hasColumn('store_profiles', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
