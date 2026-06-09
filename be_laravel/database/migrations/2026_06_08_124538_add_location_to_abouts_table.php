<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('abouts', function (Blueprint $table) {
            // Mengecek dan menambahkan kolom agar tidak error jika sudah ada
            if (!Schema::hasColumn('abouts', 'province_id')) {
                $table->string('province_id')->nullable()->after('id');
            }
            if (!Schema::hasColumn('abouts', 'city_id')) {
                $table->string('city_id')->nullable()->after('province_id');
            }
            if (!Schema::hasColumn('abouts', 'district_id')) {
                $table->string('district_id')->nullable()->after('city_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('abouts', function (Blueprint $table) {
            $table->dropColumn(['province_id', 'city_id', 'district_id']);
        });
    }
};