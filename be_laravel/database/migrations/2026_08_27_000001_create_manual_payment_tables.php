<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('manual_payment_accounts', function (Blueprint $table) {
            $table->id();
            $table->string('account_type', 30)->default('virtual_account');
            $table->string('bank_name', 100);
            $table->string('account_number', 100);
            $table->string('account_name', 150);
            $table->string('label', 100)->nullable();
            $table->text('instructions')->nullable();
            $table->boolean('is_active')->default(true);
            $table->boolean('is_primary')->default(false);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['is_active', 'is_primary']);
        });

        Schema::table('transactions', function (Blueprint $table) {
            $table->foreignId('manual_payment_account_id')
                ->nullable()
                ->after('order_id')
                ->constrained('manual_payment_accounts')
                ->nullOnDelete();
            $table->json('manual_payment_account_snapshot')->nullable()->after('payment_details');
            $table->timestamp('payment_expires_at')->nullable()->after('manual_payment_account_snapshot');
            $table->timestamp('payment_approved_at')->nullable()->after('payment_expires_at');
            $table->foreignId('payment_approved_by')
                ->nullable()
                ->after('payment_approved_at')
                ->constrained('users')
                ->nullOnDelete();
        });

        Schema::create('manual_payment_confirmations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transaction_id')->constrained('transactions')->cascadeOnDelete();
            $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('sender_name', 150);
            $table->string('sender_bank', 100);
            $table->string('sender_account_number', 100);
            $table->decimal('transferred_amount', 15, 2);
            $table->timestamp('transferred_at')->nullable();
            $table->string('proof_path');
            $table->text('note')->nullable();
            $table->string('status', 30)->default('submitted');
            $table->text('rejection_reason')->nullable();
            $table->timestamp('submitted_at');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();

            $table->index(['order_id', 'status']);
            $table->index(['transaction_id', 'submitted_at']);
        });

        Schema::create('manual_payment_audits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transaction_id')->nullable()->constrained('transactions')->nullOnDelete();
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action', 60);
            $table->string('from_status', 60)->nullable();
            $table->string('to_status', 60)->nullable();
            $table->text('reason')->nullable();
            $table->json('metadata')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamps();

            $table->index(['order_id', 'created_at']);
            $table->index(['transaction_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('manual_payment_audits');
        Schema::dropIfExists('manual_payment_confirmations');

        Schema::table('transactions', function (Blueprint $table) {
            $table->dropConstrainedForeignId('payment_approved_by');
            $table->dropConstrainedForeignId('manual_payment_account_id');
            $table->dropColumn([
                'manual_payment_account_snapshot',
                'payment_expires_at',
                'payment_approved_at',
            ]);
        });

        Schema::dropIfExists('manual_payment_accounts');
    }
};
