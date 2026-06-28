<?php

namespace Tests\Feature;

use App\Models\Address;
use App\Models\StoreProfile;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StoreLocationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config()->set('database.default', 'store_location_testing');
        config()->set('database.connections.store_location_testing', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => true,
        ]);

        DB::purge('store_location_testing');
        DB::setDefaultConnection('store_location_testing');

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('store_owner_id')->nullable()->unique();
            $table->string('name');
            $table->string('phone');
            $table->string('locality');
            $table->text('address');
            $table->string('city_id');
            $table->string('city');
            $table->string('city_name');
            $table->string('province_id');
            $table->string('province_name');
            $table->string('district_id');
            $table->string('district_name');
            $table->string('state');
            $table->string('postal_code');
            $table->string('country');
            $table->string('landmark')->nullable();
            $table->string('zip');
            $table->string('type')->default('Rumah');
            $table->boolean('isdefault')->default(false);
            $table->string('label')->default('Rumah');
            $table->text('note')->nullable();
            $table->boolean('is_store_address')->default(false);
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->timestamps();
        });

        Schema::create('store_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('logo')->nullable();
            $table->string('banner')->nullable();
            $table->string('phone')->nullable();
            $table->text('description')->nullable();
            $table->text('address')->nullable();
            $table->text('maps_url')->nullable();
            $table->string('province_name')->nullable();
            $table->string('city_name')->nullable();
            $table->string('instagram')->nullable();
            $table->string('tiktok')->nullable();
            $table->string('facebook')->nullable();
            $table->string('website')->nullable();
            $table->string('status')->default('active');
            $table->decimal('rating_average', 3, 2)->default(0);
            $table->unsignedInteger('rating_count')->default(0);
            $table->timestamps();
        });
    }

    public function test_selecting_a_store_location_replaces_the_previous_location(): void
    {
        $user = $this->user();
        Sanctum::actingAs($user);

        $firstId = $this->postJson('/api/user/addresses', $this->addressPayload([
            'detail_address' => 'Jalan Toko Lama 1',
            'is_store' => 1,
        ]))->assertOk()->json('data.id');

        $secondId = $this->postJson('/api/user/addresses', $this->addressPayload([
            'detail_address' => 'Jalan Toko Baru 2',
            'city_id' => '22',
            'city_name' => 'Bandung',
            'is_store' => 1,
        ]))->assertOk()->json('data.id');

        $this->assertDatabaseHas('addresses', [
            'id' => $firstId,
            'is_store_address' => 0,
            'store_owner_id' => null,
        ]);
        $this->assertDatabaseHas('addresses', [
            'id' => $secondId,
            'is_store_address' => 1,
            'store_owner_id' => $user->id,
        ]);
        $this->assertSame(1, Address::where('user_id', $user->id)->whereNotNull('store_owner_id')->count());

        $this->getJson('/api/admin/store-location')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $secondId);

        $this->assertDatabaseHas('store_profiles', [
            'user_id' => $user->id,
            'city_name' => 'Bandung',
        ]);
    }

    public function test_a_regular_address_is_never_used_as_the_store_location(): void
    {
        $user = $this->user();
        Sanctum::actingAs($user);

        $this->postJson('/api/user/addresses', $this->addressPayload())
            ->assertOk()
            ->assertJsonPath('data.is_store_address', false);

        $this->getJson('/api/admin/store-location')
            ->assertOk()
            ->assertJson([
                'success' => false,
                'data' => null,
            ]);
    }

    public function test_setting_an_existing_address_as_store_location_is_atomic_and_unique(): void
    {
        $user = $this->user();
        Sanctum::actingAs($user);

        $firstId = $this->postJson('/api/user/addresses', $this->addressPayload())
            ->assertOk()
            ->json('data.id');
        $secondId = $this->postJson('/api/user/addresses', $this->addressPayload([
            'detail_address' => 'Jalan Kedua',
        ]))->assertOk()->json('data.id');

        $this->putJson("/api/user/addresses/{$firstId}/set-store")->assertOk();
        $this->putJson("/api/user/addresses/{$secondId}/set-store")->assertOk();

        $this->assertDatabaseHas('addresses', [
            'id' => $firstId,
            'store_owner_id' => null,
        ]);
        $this->assertDatabaseHas('addresses', [
            'id' => $secondId,
            'store_owner_id' => $user->id,
        ]);

        try {
            Address::whereKey($firstId)->update([
                'store_owner_id' => $user->id,
                'is_store_address' => true,
            ]);
            $this->fail('Database harus menolak dua lokasi toko untuk akun yang sama.');
        } catch (QueryException) {
            $this->assertTrue(true);
        }
    }

    public function test_deleting_the_store_location_clears_stale_store_profile_location(): void
    {
        $user = $this->user();
        Sanctum::actingAs($user);

        $addressId = $this->postJson('/api/user/addresses', $this->addressPayload([
            'is_store' => 1,
        ]))->assertOk()->json('data.id');

        $this->deleteJson("/api/user/addresses/{$addressId}")->assertOk();

        $this->assertNull(StoreProfile::where('user_id', $user->id)->value('address'));
        $this->assertNull(StoreProfile::where('user_id', $user->id)->value('maps_url'));
        $this->getJson('/api/admin/store-location')
            ->assertOk()
            ->assertJsonPath('success', false);
    }

    public function test_dedicated_store_location_endpoint_updates_instead_of_duplicating(): void
    {
        $user = $this->user();
        Sanctum::actingAs($user);

        $firstId = $this->postJson('/api/admin/store-location', $this->addressPayload([
            'detail_address' => 'Lokasi Awal',
        ]))->assertOk()->json('data.id');

        $secondId = $this->postJson('/api/admin/store-location', $this->addressPayload([
            'detail_address' => 'Lokasi Diperbarui',
        ]))->assertOk()->json('data.id');

        $this->assertSame($firstId, $secondId);
        $this->assertDatabaseCount('addresses', 1);
        $this->assertDatabaseHas('addresses', [
            'id' => $firstId,
            'address' => 'Lokasi Diperbarui',
            'store_owner_id' => $user->id,
        ]);
    }

    public function test_rajaongkir_uses_the_sellers_store_district_as_origin(): void
    {
        config()->set('rajaongkir.base_url', 'https://rajaongkir.komerce.id/api/v1');
        config()->set('rajaongkir.api_key', 'test-key');

        $seller = $this->user();
        Sanctum::actingAs($seller);
        $this->postJson('/api/user/addresses', $this->addressPayload([
            'district_id' => '3201010',
            'is_store' => 1,
        ]))->assertOk();

        $buyer = $this->user();
        Sanctum::actingAs($buyer);
        Http::fake([
            '*' => Http::response([
                'data' => [[
                    'service' => 'REG',
                    'description' => 'Reguler',
                    'cost' => 12000,
                    'etd' => '1-2 day',
                ]],
            ]),
        ]);

        $this->postJson('/api/rajaongkir/cost', [
            'seller_id' => $seller->id,
            'destination' => '3273',
            'destination_district' => '3273010',
            'weight' => 1000,
            'courier' => 'jne',
        ])->assertOk()
            ->assertJsonPath('0.service', 'REG')
            ->assertJsonPath('0.cost.0.value', 12000);

        Http::assertSent(function ($request) {
            return $request->url() === 'https://rajaongkir.komerce.id/api/v1/calculate/district/domestic-cost'
                && $request['origin'] === '3201010'
                && $request['destination'] === '3273010'
                && $request['weight'] === 1000
                && $request['courier'] === 'jne';
        });
    }

    public function test_rajaongkir_does_not_fall_back_to_a_global_origin(): void
    {
        config()->set('rajaongkir.base_url', 'https://rajaongkir.komerce.id/api/v1');

        $sellerWithoutStoreLocation = $this->user();
        $buyer = $this->user();
        Sanctum::actingAs($buyer);
        Http::fake();

        $this->postJson('/api/rajaongkir/cost', [
            'seller_id' => $sellerWithoutStoreLocation->id,
            'destination' => '3273',
            'destination_district' => '3273010',
            'weight' => 1000,
            'courier' => 'jne',
        ])->assertUnprocessable()
            ->assertJsonPath('error', 'Lokasi toko belum diatur oleh penjual.');

        Http::assertNothingSent();
    }

    private function user(): User
    {
        return User::create([
            'name' => 'Penjual Uji',
            'email' => fake()->unique()->safeEmail(),
            'password' => 'password',
        ]);
    }

    private function addressPayload(array $overrides = []): array
    {
        return array_merge([
            'name' => 'Penjual Uji',
            'phone' => '08123456789',
            'province_id' => '9',
            'province_name' => 'Jawa Barat',
            'city_id' => '21',
            'city_name' => 'Bogor',
            'district_id' => '2101',
            'kecamatan' => 'Cibinong',
            'postal_code' => '16911',
            'detail_address' => 'Jalan Pasar 1',
            'label' => 'Toko',
            'latitude' => -6.4858000,
            'longitude' => 106.8420000,
            'is_main' => 0,
            'is_store' => 0,
        ], $overrides);
    }
}
