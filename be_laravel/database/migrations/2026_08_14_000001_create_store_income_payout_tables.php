<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('user_super')) {
            Schema::create('user_super', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->unique();
                $table->string('keterangan')->default('Super Admin');
                $table->timestamps();
            });
        }

        DB::table('user_super')->updateOrInsert(
            ['user_id' => 1],
            [
                'keterangan' => 'Super Admin',
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        if (! Schema::hasTable('store_bank_accounts')) {
            Schema::create('store_bank_accounts', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
                $table->unsignedTinyInteger('slot')->default(1);
                $table->string('provider', 50);
                $table->string('account_number', 100);
                $table->string('account_name')->nullable();
                $table->timestamps();

                $table->unique(['user_id', 'slot']);
                $table->index(['user_id', 'provider']);
            });
        }

        if (! Schema::hasTable('store_payouts')) {
            Schema::create('store_payouts', function (Blueprint $table) {
                $table->id();
                $table->foreignId('seller_id')->constrained('users')->cascadeOnDelete();
                $table->foreignId('processed_by')->nullable()->constrained('users')->nullOnDelete();
                $table->date('income_date')->nullable();
                $table->date('payout_date');
                $table->decimal('amount', 15, 2)->default(0);
                $table->text('description')->nullable();
                $table->string('proof_photo')->nullable();
                $table->string('bank_provider', 50)->nullable();
                $table->string('account_number', 100)->nullable();
                $table->string('account_name')->nullable();
                $table->string('status', 30)->default('paid');
                $table->timestamps();

                $table->index(['seller_id', 'status']);
                $table->index(['seller_id', 'income_date']);
            });
        }

        if (! Schema::hasTable('store_payout_items')) {
            Schema::create('store_payout_items', function (Blueprint $table) {
                $table->id();
                $table->foreignId('payout_id')->constrained('store_payouts')->cascadeOnDelete();
                $table->foreignId('seller_id')->constrained('users')->cascadeOnDelete();
                $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
                $table->date('income_date');
                $table->decimal('amount', 15, 2)->default(0);
                $table->timestamps();

                $table->unique(['seller_id', 'order_id']);
                $table->index(['seller_id', 'income_date']);
            });
        }

        if (Schema::hasTable('orders') && ! Schema::hasColumn('orders', 'completed_at')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->timestamp('completed_at')->nullable()->after('delivered_date');
            });
        }

        if (Schema::hasTable('orders') && Schema::hasColumn('orders', 'completed_at')) {
            DB::table('orders')
                ->whereIn('status', ['done', 'completed', 'complete', 'selesai'])
                ->whereNull('completed_at')
                ->update(['completed_at' => DB::raw('updated_at')]);
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('orders') && Schema::hasColumn('orders', 'completed_at')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->dropColumn('completed_at');
            });
        }

        Schema::dropIfExists('store_payout_items');
        Schema::dropIfExists('store_payouts');
        Schema::dropIfExists('store_bank_accounts');
        Schema::dropIfExists('user_super');
    }
};
