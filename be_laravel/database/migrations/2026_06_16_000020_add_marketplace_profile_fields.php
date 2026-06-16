<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'avatar')) {
                $table->string('avatar')->nullable()->after('email');
            }
        });

        Schema::table('store_profiles', function (Blueprint $table) {
            if (! Schema::hasColumn('store_profiles', 'maps_url')) {
                $table->text('maps_url')->nullable()->after('address');
            }

            if (! Schema::hasColumn('store_profiles', 'instagram')) {
                $table->string('instagram')->nullable()->after('city_name');
            }

            if (! Schema::hasColumn('store_profiles', 'tiktok')) {
                $table->string('tiktok')->nullable()->after('instagram');
            }

            if (! Schema::hasColumn('store_profiles', 'facebook')) {
                $table->string('facebook')->nullable()->after('tiktok');
            }

            if (! Schema::hasColumn('store_profiles', 'website')) {
                $table->string('website')->nullable()->after('facebook');
            }
        });
    }

    public function down(): void
    {
        Schema::table('store_profiles', function (Blueprint $table) {
            foreach (['website', 'facebook', 'tiktok', 'instagram', 'maps_url'] as $column) {
                if (Schema::hasColumn('store_profiles', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'avatar')) {
                $table->dropColumn('avatar');
            }
        });
    }
};
