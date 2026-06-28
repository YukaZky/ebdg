<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CartLifecycleTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config()->set('database.default', 'cart_lifecycle_testing');
        config()->set('database.connections.cart_lifecycle_testing', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => true,
        ]);

        DB::purge('cart_lifecycle_testing');
        DB::setDefaultConnection('cart_lifecycle_testing');

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->rememberToken();
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
            $table->string('image')->nullable();
            $table->timestamps();
        });

        Schema::create('product_variations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->decimal('regular_price', 15, 2)->default(0);
            $table->decimal('sale_price', 15, 2)->nullable();
            $table->integer('weight')->default(0);
            $table->integer('quantity')->default(0);
            $table->string('image')->nullable();
            $table->timestamps();
        });

        Schema::create('cart_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('variation_id')->nullable();
            $table->string('variation_name')->nullable();
            $table->integer('quantity')->default(1);
            $table->decimal('price', 15, 2);
            $table->string('selected_image')->nullable();
            $table->integer('weight')->default(0);
            $table->timestamps();
        });

        Schema::create('store_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('logo')->nullable();
            $table->timestamps();
        });

        Schema::create('product_images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->string('image');
            $table->timestamps();
        });

        Schema::create('product_reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('rating');
            $table->timestamps();
        });
    }

    public function test_product_can_be_removed_added_again_and_returned_by_cart_api(): void
    {
        $seller = $this->user('seller');
        $buyer = $this->user('buyer');
        $product = Product::create([
            'user_id' => $seller->id,
            'name' => 'Produk Uji',
            'slug' => 'produk-uji',
            'description' => 'Produk untuk siklus keranjang',
            'regular_price' => 25000,
            'SKU' => 'TEST-1',
            'stock_status' => 'instock',
            'quantity' => 10,
            'weight' => 500,
        ]);

        Sanctum::actingAs($buyer);

        $firstCartId = $this->postJson('/api/cart/add', [
            'product_id' => $product->id,
            'quantity' => 1,
        ])->assertOk()->json('data.id');

        $cartResponse = $this->getJson('/api/cart')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.product.id', $product->id)
            ->assertJsonPath('data.0.seller_id', $seller->id);
        $this->assertStringContainsString('no-store', (string) $cartResponse->headers->get('Cache-Control'));

        $this->deleteJson("/api/cart/remove/{$firstCartId}")->assertOk();
        $this->assertDatabaseCount('cart_items', 0);

        $this->postJson('/api/cart/add', [
            'product_id' => $product->id,
            'quantity' => 1,
        ])->assertOk();

        $this->getJson('/api/cart')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.product.id', $product->id)
            ->assertJsonPath('data.0.quantity', 1)
            ->assertJsonPath('data.0.seller_id', $seller->id);
    }

    private function user(string $prefix): User
    {
        return User::create([
            'name' => ucfirst($prefix),
            'email' => $prefix.'@example.test',
            'password' => 'password',
        ]);
    }
}
