<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
{
    Schema::table('addresses', function (Blueprint $table) {
        if (!Schema::hasColumn('addresses','district_id')) {
            $table->unsignedInteger('district_id')->nullable()->after('city_id');
        }
        if (!Schema::hasColumn('addresses','district_name')) {
            $table->string('district_name')->nullable()->after('district_id');
        }
    });
}

public function down(): void
{
    Schema::table('addresses', function (Blueprint $table) {
        $table->dropColumn(['district_id','district_name']);
    });
}


};