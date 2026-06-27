<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('coupons')) {
            Schema::create('coupons', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('id_user')->nullable()->index();
                $table->string('name');
                $table->string('code')->index();
                $table->string('type')->default('fixed');
                $table->decimal('value', 14, 2)->default(0);
                $table->decimal('min_purchase', 14, 2)->default(0);
                $table->decimal('max_discount', 14, 2)->nullable();
                $table->integer('usage_limit')->nullable();
                $table->integer('used_count')->default(0);
                $table->text('description')->nullable();
                $table->string('status')->default('active');
                $table->timestamp('starts_at')->nullable();
                $table->timestamp('expires_at')->nullable();
                $table->timestamps();
            });
        } else {
            Schema::table('coupons', function (Blueprint $table) {
                if (! Schema::hasColumn('coupons', 'id_user')) $table->unsignedBigInteger('id_user')->nullable()->index()->after('id');
                if (! Schema::hasColumn('coupons', 'name')) $table->string('name')->nullable()->after('id_user');
                if (! Schema::hasColumn('coupons', 'code')) $table->string('code')->nullable()->index()->after('name');
                if (! Schema::hasColumn('coupons', 'type')) $table->string('type')->default('fixed')->after('code');
                if (! Schema::hasColumn('coupons', 'value')) $table->decimal('value', 14, 2)->default(0)->after('type');
                if (! Schema::hasColumn('coupons', 'min_purchase')) $table->decimal('min_purchase', 14, 2)->default(0)->after('value');
                if (! Schema::hasColumn('coupons', 'max_discount')) $table->decimal('max_discount', 14, 2)->nullable()->after('min_purchase');
                if (! Schema::hasColumn('coupons', 'usage_limit')) $table->integer('usage_limit')->nullable()->after('max_discount');
                if (! Schema::hasColumn('coupons', 'used_count')) $table->integer('used_count')->default(0)->after('usage_limit');
                if (! Schema::hasColumn('coupons', 'description')) $table->text('description')->nullable()->after('used_count');
                if (! Schema::hasColumn('coupons', 'status')) $table->string('status')->default('active')->after('description');
                if (! Schema::hasColumn('coupons', 'starts_at')) $table->timestamp('starts_at')->nullable()->after('status');
                if (! Schema::hasColumn('coupons', 'expires_at')) $table->timestamp('expires_at')->nullable()->after('starts_at');
            });
        }

        if (! Schema::hasTable('cuppon_takes')) {
            Schema::create('cuppon_takes', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('id_cuppon')->index();
                $table->unsignedBigInteger('id_user')->index();
                $table->string('status')->default('take');
                $table->timestamps();
                $table->unique(['id_cuppon', 'id_user']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('cuppon_takes');

        if (Schema::hasTable('coupons')) {
            Schema::table('coupons', function (Blueprint $table) {
                foreach (['id_user', 'name', 'code', 'type', 'value', 'min_purchase', 'max_discount', 'usage_limit', 'used_count', 'description', 'status', 'starts_at', 'expires_at'] as $column) {
                    if (Schema::hasColumn('coupons', $column)) {
                        $table->dropColumn($column);
                    }
                }
            });
        }
    }
};
