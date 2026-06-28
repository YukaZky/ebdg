<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MultiStoreCheckoutTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config()->set('database.default', 'multi_store_checkout_testing');
        config()->set('database.connections.multi_store_checkout_testing', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => true,
        ]);
        config()->set('rajaongkir.base_url', 'https://rajaongkir.komerce.id/api/v1');

        DB::purge('multi_store_checkout_testing');
        DB::setDefaultConnection('multi_store_checkout_testing');

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('store_owner_id')->nullable()->unique();
            $table->string('city_id');
            $table->string('district_id');
            $table->string('province_name');
            $table->string('city_name');
            $table->string('district_name');
            $table->timestamps();
        });

        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description');
            $table->decimal('regular_price', 15, 2);
            $table->decimal('sale_price', 15, 2)->nullable();
            $table->string('SKU');
            $table->string('stock_status')->default('instock');
            $table->unsignedInteger('quantity')->default(10);
            $table->unsignedInteger('weight')->default(1000);
            $table->timestamps();
        });

        Schema::create('product_variations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->decimal('regular_price', 15, 2)->default(0);
            $table->decimal('sale_price', 15, 2)->nullable();
            $table->integer('quantity')->default(0);
            $table->timestamps();
        });

        Schema::create('product_reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('rating');
            $table->timestamps();
        });

        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->decimal('subtotal', 15, 2);
            $table->decimal('discount', 15, 2)->default(0);
            $table->decimal('tax', 15, 2)->default(0);
            $table->decimal('total', 15, 2);
            $table->string('mode_pengiriman')->nullable();
            $table->string('jenis_pengiriman')->nullable();
            $table->decimal('ongkir', 15, 2)->default(0);
            $table->json('shipping_breakdown')->nullable();
            $table->string('name');
            $table->string('phone');
            $table->string('locality');
            $table->text('address');
            $table->string('city');
            $table->string('state');
            $table->string('country');
            $table->string('zip');
            $table->string('status')->default('ordered');
            $table->timestamps();
        });

        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->decimal('price', 15, 2);
            $table->integer('quantity');
            $table->longText('option')->nullable();
            $table->timestamps();
        });

        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->string('mode');
            $table->string('status')->default('pending');
            $table->string('payment_token')->nullable();
            $table->text('payment_url')->nullable();
            $table->text('payment_details')->nullable();
            $table->timestamps();
        });
    }

    public function test_checkout_persists_a_distinct_shipping_rate_for_each_store(): void
    {
        [$bandungSeller, $bandungProduct] = $this->sellerWithProduct('Bandung', '3273010', 25000);
        [$mataramSeller, $mataramProduct] = $this->sellerWithProduct('Mataram', '5271010', 40000);
        $buyer = $this->user('Pembeli');
        Sanctum::actingAs($buyer);

        $this->postJson('/api/checkout/finalize', $this->checkoutPayload(
            $bandungSeller,
            $bandungProduct,
            $mataramSeller,
            $mataramProduct,
        ))->assertOk()
            ->assertJsonPath('order.ongkir', 65000)
            ->assertJsonPath('order.total', 130000)
            ->assertJsonPath('order.mode_pengiriman', 'MULTI_TOKO')
            ->assertJsonPath('order.shipping_breakdown.0.seller_id', $bandungSeller->id)
            ->assertJsonPath('order.shipping_breakdown.0.shipping_cost', 18000)
            ->assertJsonPath('order.shipping_breakdown.0.origin.location_id', '3273010')
            ->assertJsonPath('order.shipping_breakdown.1.seller_id', $mataramSeller->id)
            ->assertJsonPath('order.shipping_breakdown.1.shipping_cost', 47000)
            ->assertJsonPath('order.shipping_breakdown.1.origin.location_id', '5271010');

        $this->assertDatabaseHas('orders', [
            'ongkir' => 65000,
            'total' => 130000,
            'mode_pengiriman' => 'MULTI_TOKO',
            'jenis_pengiriman' => '2 pengiriman',
        ]);
    }

    public function test_checkout_rejects_missing_or_stale_store_shipping_details(): void
    {
        [$bandungSeller, $bandungProduct] = $this->sellerWithProduct('Bandung', '3273010', 25000);
        [$mataramSeller, $mataramProduct] = $this->sellerWithProduct('Mataram', '5271010', 40000);
        $buyer = $this->user('Pembeli');
        Sanctum::actingAs($buyer);

        $payload = $this->checkoutPayload($bandungSeller, $bandungProduct, $mataramSeller, $mataramProduct);
        array_pop($payload['shipments']);
        $payload['shipping_cost'] = 18000;

        $this->postJson('/api/checkout/finalize', $payload)
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Gagal finalisasi order: Rincian ongkir tidak sesuai dengan toko pemilik produk.');
        $this->assertDatabaseCount('orders', 0);

        $payload = $this->checkoutPayload($bandungSeller, $bandungProduct, $mataramSeller, $mataramProduct);
        $payload['shipments'][0]['origin']['location_id'] = '501';

        $this->postJson('/api/checkout/finalize', $payload)
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Gagal finalisasi order: Asal ongkir sudah tidak sesuai dengan lokasi toko terbaru. Hitung ulang ongkir.');
        $this->assertDatabaseCount('orders', 0);
    }

    private function checkoutPayload(User $firstSeller, Product $firstProduct, User $secondSeller, Product $secondProduct): array
    {
        return [
            'address' => 'Asemrowo, Surabaya',
            'phone' => '08123456789',
            'province_name' => 'Jawa Timur',
            'city_name' => 'Surabaya',
            'courier' => 'MULTI_TOKO - 2 pengiriman',
            'shipping_cost' => 65000,
            'shipments' => [
                [
                    'seller_id' => $firstSeller->id,
                    'store_name' => 'Toko Bandung',
                    'courier' => 'JNE - REG',
                    'shipping_cost' => 18000,
                    'weight' => 1000,
                    'origin' => ['seller_id' => $firstSeller->id, 'location_id' => '3273010'],
                ],
                [
                    'seller_id' => $secondSeller->id,
                    'store_name' => 'Toko Mataram',
                    'courier' => 'JNE - REG',
                    'shipping_cost' => 47000,
                    'weight' => 1000,
                    'origin' => ['seller_id' => $secondSeller->id, 'location_id' => '5271010'],
                ],
            ],
            'items' => [
                ['product_id' => $firstProduct->id, 'quantity' => 1, 'price' => 25000, 'weight' => 1000],
                ['product_id' => $secondProduct->id, 'quantity' => 1, 'price' => 40000, 'weight' => 1000],
            ],
        ];
    }

    private function sellerWithProduct(string $city, string $districtId, int $price): array
    {
        $seller = $this->user('Penjual '.$city);
        DB::table('addresses')->insert([
            'user_id' => $seller->id,
            'store_owner_id' => $seller->id,
            'city_id' => $city === 'Bandung' ? '3273' : '5271',
            'district_id' => $districtId,
            'province_name' => $city === 'Bandung' ? 'Jawa Barat' : 'Nusa Tenggara Barat',
            'city_name' => $city,
            'district_name' => $city,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $product = Product::create([
            'user_id' => $seller->id,
            'name' => 'Produk '.$city,
            'slug' => 'produk-'.strtolower($city),
            'description' => 'Produk uji '.$city,
            'regular_price' => $price,
            'SKU' => 'SKU-'.strtoupper($city),
            'stock_status' => 'instock',
            'quantity' => 10,
            'weight' => 1000,
        ]);

        return [$seller, $product];
    }

    private function user(string $name): User
    {
        return User::create([
            'name' => $name,
            'email' => strtolower(str_replace(' ', '.', $name)).'.'.fake()->unique()->randomNumber(5).'@example.test',
            'password' => 'password',
        ]);
    }
}
