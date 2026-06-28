<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class PaymentMethodMigrationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config()->set('database.default', 'payment_method_migration_testing');
        config()->set('database.connections.payment_method_migration_testing', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => true,
        ]);

        DB::purge('payment_method_migration_testing');
        DB::setDefaultConnection('payment_method_migration_testing');
    }

    public function test_migration_creates_payment_methods_when_missing(): void
    {
        $migration = require database_path('migrations/2026_06_19_131310_create_payment_methods_table.php');
        $migration->up();

        $this->assertTrue(Schema::hasTable('payment_methods'));
        $this->assertTrue(Schema::hasColumns('payment_methods', [
            'id',
            'name',
            'payment_type',
            'bank_code',
            'icon_path',
            'is_active',
            'created_at',
            'updated_at',
        ]));
    }

    public function test_migration_is_safe_when_payment_methods_already_exists(): void
    {
        Schema::create('payment_methods', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('payment_type');
            $table->string('bank_code')->nullable();
            $table->string('icon_path');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        DB::table('payment_methods')->insert([
            'name' => 'BCA Virtual Account',
            'payment_type' => 'bank_transfer',
            'bank_code' => 'bca',
            'icon_path' => 'bca.png',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $migration = require database_path('migrations/2026_06_19_131310_create_payment_methods_table.php');
        $migration->up();

        $this->assertDatabaseCount('payment_methods', 1);
        $this->assertDatabaseHas('payment_methods', [
            'name' => 'BCA Virtual Account',
            'bank_code' => 'bca',
        ]);
    }
}
