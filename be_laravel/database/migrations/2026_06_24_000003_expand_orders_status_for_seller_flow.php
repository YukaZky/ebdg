<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('orders')) {
            DB::statement("ALTER TABLE orders MODIFY status ENUM('ordered','paid','packing','processing','shipped','delivered','done','completed','canceled') NOT NULL DEFAULT 'ordered'");
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('orders')) {
            DB::table('orders')->whereIn('status', ['paid', 'packing', 'processing', 'shipped'])->update(['status' => 'ordered']);
            DB::table('orders')->whereIn('status', ['done', 'completed'])->update(['status' => 'delivered']);
            DB::statement("ALTER TABLE orders MODIFY status ENUM('ordered','delivered','canceled') NOT NULL DEFAULT 'ordered'");
        }
    }
};
