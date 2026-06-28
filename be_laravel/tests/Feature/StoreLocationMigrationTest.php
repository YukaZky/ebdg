<?php

namespace Tests\Feature;

use Illuminate\Database\QueryException;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class StoreLocationMigrationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config()->set('database.default', 'store_location_migration_testing');
        config()->set('database.connections.store_location_migration_testing', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => true,
        ]);

        DB::purge('store_location_migration_testing');
        DB::setDefaultConnection('store_location_migration_testing');

        Schema::create('addresses', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->boolean('isdefault')->default(false);
            $table->boolean('is_store_address')->default(false);
            $table->timestamps();
        });
    }

    public function test_migration_repairs_duplicates_and_adds_the_unique_store_slot(): void
    {
        $olderId = DB::table('addresses')->insertGetId([
            'user_id' => 10,
            'isdefault' => false,
            'is_store_address' => true,
            'created_at' => now()->subDay(),
            'updated_at' => now()->subDay(),
        ]);
        $mainId = DB::table('addresses')->insertGetId([
            'user_id' => 10,
            'isdefault' => true,
            'is_store_address' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $migration = require database_path('migrations/2026_06_28_000001_enforce_one_store_location_per_user.php');
        $migration->up();

        $this->assertTrue(Schema::hasColumns('addresses', ['store_owner_id', 'latitude', 'longitude']));
        $this->assertDatabaseHas('addresses', [
            'id' => $mainId,
            'store_owner_id' => 10,
            'is_store_address' => true,
        ]);
        $this->assertDatabaseHas('addresses', [
            'id' => $olderId,
            'store_owner_id' => null,
            'is_store_address' => false,
        ]);

        try {
            DB::table('addresses')->where('id', $olderId)->update([
                'store_owner_id' => 10,
                'is_store_address' => true,
            ]);
            $this->fail('Unique index lokasi toko tidak diterapkan.');
        } catch (QueryException) {
            $this->assertTrue(true);
        }

        $migration->down();
        $this->assertFalse(Schema::hasColumn('addresses', 'store_owner_id'));
    }

    public function test_migration_accepts_existing_coordinate_columns(): void
    {
        Schema::table('addresses', function (Blueprint $table) {
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
        });

        $migration = require database_path('migrations/2026_06_28_000001_enforce_one_store_location_per_user.php');
        $migration->up();

        $this->assertTrue(Schema::hasColumns('addresses', ['store_owner_id', 'latitude', 'longitude']));
    }
}
