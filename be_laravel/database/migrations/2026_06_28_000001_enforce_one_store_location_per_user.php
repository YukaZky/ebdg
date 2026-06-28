<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private const UNIQUE_INDEX = 'addresses_one_store_location_per_user_unique';

    public function up(): void
    {
        $needsStoreOwner = ! Schema::hasColumn('addresses', 'store_owner_id');
        $needsLatitude = ! Schema::hasColumn('addresses', 'latitude');
        $needsLongitude = ! Schema::hasColumn('addresses', 'longitude');

        Schema::table('addresses', function (Blueprint $table) use ($needsStoreOwner, $needsLatitude, $needsLongitude) {
            if ($needsStoreOwner) {
                $table->unsignedBigInteger('store_owner_id')->nullable()->after('user_id');
            }
            if ($needsLatitude) {
                $table->decimal('latitude', 10, 7)->nullable();
            }
            if ($needsLongitude) {
                $table->decimal('longitude', 10, 7)->nullable();
            }
        });

        $seenUsers = [];
        $storeAddresses = DB::table('addresses')
            ->where('is_store_address', true)
            ->orderBy('user_id')
            ->orderByDesc('isdefault')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->get(['id', 'user_id']);

        foreach ($storeAddresses as $address) {
            if (isset($seenUsers[$address->user_id])) {
                DB::table('addresses')
                    ->where('id', $address->id)
                    ->update(['is_store_address' => false]);

                continue;
            }

            $seenUsers[$address->user_id] = true;
            DB::table('addresses')
                ->where('id', $address->id)
                ->update(['store_owner_id' => $address->user_id]);
        }

        if (! Schema::hasIndex('addresses', self::UNIQUE_INDEX)) {
            Schema::table('addresses', function (Blueprint $table) {
                $table->unique('store_owner_id', self::UNIQUE_INDEX);
            });
        }
    }

    public function down(): void
    {
        $hasUniqueIndex = Schema::hasIndex('addresses', self::UNIQUE_INDEX);
        $columns = collect(['store_owner_id', 'latitude', 'longitude'])
            ->filter(fn (string $column) => Schema::hasColumn('addresses', $column))
            ->values()
            ->all();

        Schema::table('addresses', function (Blueprint $table) use ($hasUniqueIndex, $columns) {
            if ($hasUniqueIndex) {
                $table->dropUnique(self::UNIQUE_INDEX);
            }
            if (! empty($columns)) {
                $table->dropColumn($columns);
            }
        });
    }
};
