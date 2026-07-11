<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private const PRECISION = 20;
    private const SCALE = 2;

    public function up(): void
    {
        if (Schema::hasTable('cart_items') && Schema::hasColumn('cart_items', 'price')) {
            Schema::table('cart_items', function (Blueprint $table) {
                $table->decimal('price', self::PRECISION, self::SCALE)->change();
            });
        }

        if (Schema::hasTable('orders')) {
            $hasSubtotal = Schema::hasColumn('orders', 'subtotal');
            $hasDiscount = Schema::hasColumn('orders', 'discount');
            $hasTax = Schema::hasColumn('orders', 'tax');
            $hasTotal = Schema::hasColumn('orders', 'total');
            $hasShippingCost = Schema::hasColumn('orders', 'ongkir');

            Schema::table('orders', function (Blueprint $table) use (
                $hasSubtotal,
                $hasDiscount,
                $hasTax,
                $hasTotal,
                $hasShippingCost
            ) {
                if ($hasSubtotal) {
                    $table->decimal('subtotal', self::PRECISION, self::SCALE)->change();
                }

                if ($hasDiscount) {
                    $table->decimal('discount', self::PRECISION, self::SCALE)
                        ->default(0)
                        ->change();
                }

                if ($hasTax) {
                    $table->decimal('tax', self::PRECISION, self::SCALE)->change();
                }

                if ($hasTotal) {
                    $table->decimal('total', self::PRECISION, self::SCALE)->change();
                }

                if ($hasShippingCost) {
                    $table->decimal('ongkir', self::PRECISION, self::SCALE)
                        ->default(0)
                        ->change();
                }
            });
        }

        if (Schema::hasTable('order_items') && Schema::hasColumn('order_items', 'price')) {
            Schema::table('order_items', function (Blueprint $table) {
                $table->decimal('price', self::PRECISION, self::SCALE)->change();
            });
        }
    }

    public function down(): void
    {
        // Tidak diperkecil kembali agar nominal besar yang sudah tersimpan tidak terpotong.
    }
};
