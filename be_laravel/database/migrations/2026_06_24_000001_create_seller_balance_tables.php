<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('seller_withdrawals')) {
            Schema::create('seller_withdrawals', function (Blueprint $table) {
                $table->id();
                $table->foreignId('store_id')->constrained('store_profiles')->onDelete('cascade');
                $table->decimal('amount', 15, 2)->default(0);
                $table->string('bank_name')->nullable();
                $table->string('bank_account_number')->nullable();
                $table->string('bank_account_name')->nullable();
                $table->string('status')->default('pending')->index();
                $table->text('note')->nullable();
                $table->timestamp('paid_at')->nullable();
                $table->timestamps();
            });
        }

        if (! Schema::hasTable('seller_balances')) {
            Schema::create('seller_balances', function (Blueprint $table) {
                $table->id();
                $table->foreignId('store_id')->constrained('store_profiles')->onDelete('cascade');
                $table->foreignId('order_id')->nullable()->constrained('orders')->onDelete('cascade');
                $table->foreignId('order_item_id')->nullable()->unique()->constrained('order_items')->onDelete('set null');
                $table->foreignId('seller_withdrawal_id')->nullable()->constrained('seller_withdrawals')->onDelete('set null');
                $table->decimal('gross_amount', 15, 2)->default(0);
                $table->decimal('platform_fee', 15, 2)->default(0);
                $table->decimal('amount', 15, 2)->default(0);
                $table->string('type')->default('credit')->index();
                $table->string('status')->default('pending')->index();
                $table->timestamp('available_at')->nullable();
                $table->timestamp('withdrawn_at')->nullable();
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('seller_balances');
        Schema::dropIfExists('seller_withdrawals');
    }
};
