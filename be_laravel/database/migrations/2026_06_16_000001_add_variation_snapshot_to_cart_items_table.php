<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cart_items', function (Blueprint $table) {
            if (! Schema::hasColumn('cart_items', 'variation_id')) {
                $table->unsignedBigInteger('variation_id')->nullable()->after('product_id');
            }

            if (! Schema::hasColumn('cart_items', 'variation_name')) {
                $table->string('variation_name')->nullable()->after('variation_id');
            }

            if (! Schema::hasColumn('cart_items', 'selected_image')) {
                $table->string('selected_image')->nullable()->after('price');
            }

            if (! Schema::hasColumn('cart_items', 'weight')) {
                $table->integer('weight')->default(0)->after('selected_image');
            }
        });
    }

    public function down(): void
    {
        Schema::table('cart_items', function (Blueprint $table) {
            if (Schema::hasColumn('cart_items', 'weight')) {
                $table->dropColumn('weight');
            }

            if (Schema::hasColumn('cart_items', 'selected_image')) {
                $table->dropColumn('selected_image');
            }

            if (Schema::hasColumn('cart_items', 'variation_name')) {
                $table->dropColumn('variation_name');
            }

            if (Schema::hasColumn('cart_items', 'variation_id')) {
                $table->dropColumn('variation_id');
            }
        });
    }
};
