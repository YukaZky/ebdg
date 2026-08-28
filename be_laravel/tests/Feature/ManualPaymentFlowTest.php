<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Transaction;
use App\Models\User;
use App\Services\ManualPaymentService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ManualPaymentFlowTest extends TestCase
{
    private User $buyer;

    private User $admin;

    private User $otherUser;

    private Order $order;

    private Product $product;

    protected function setUp(): void
    {
        parent::setUp();

        config()->set('database.default', 'manual_payment_testing');
        config()->set('database.connections.manual_payment_testing', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => true,
        ]);

        DB::purge('manual_payment_testing');
        DB::setDefaultConnection('manual_payment_testing');
        $this->createTables();
        Storage::fake('local');

        $this->buyer = $this->user('Pembeli', 'USR');
        $this->admin = $this->user('Super Admin', 'ADM');
        $this->otherUser = $this->user('Orang Lain', 'USR');
        DB::table('user_super')->insert([
            'user_id' => $this->admin->id,
            'keterangan' => 'Super Admin',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $seller = $this->user('Penjual', 'ADM');
        $this->product = Product::create([
            'user_id' => $seller->id,
            'name' => 'Produk Manual',
            'slug' => 'produk-manual',
            'description' => 'Produk pengujian pembayaran manual',
            'regular_price' => 100000,
            'SKU' => 'MANUAL-1',
            'stock_status' => 'instock',
            'quantity' => 8,
            'weight' => 1000,
        ]);

        $accountId = DB::table('manual_payment_accounts')->insertGetId([
            'account_type' => 'virtual_account',
            'bank_name' => 'BCA',
            'account_number' => '812345678901',
            'account_name' => 'GeoDesa Connect',
            'label' => 'VA Utama',
            'instructions' => 'Transfer sesuai total order.',
            'is_active' => true,
            'is_primary' => true,
            'created_by' => $this->admin->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->order = Order::create([
            'user_id' => $this->buyer->id,
            'subtotal' => 100000,
            'discount' => 0,
            'tax' => 0,
            'total' => 115000,
            'mode_pengiriman' => 'JNE',
            'jenis_pengiriman' => 'REG',
            'ongkir' => 15000,
            'name' => $this->buyer->name,
            'phone' => '081234567890',
            'locality' => '-',
            'address' => 'Jl. Pengujian No. 1',
            'city' => 'Surabaya',
            'state' => 'Jawa Timur',
            'country' => 'Indonesia',
            'zip' => '60000',
            'status' => 'ordered',
        ]);
        OrderItem::create([
            'order_id' => $this->order->id,
            'product_id' => $this->product->id,
            'price' => 100000,
            'quantity' => 2,
        ]);

        $snapshot = [
            'id' => $accountId,
            'account_type' => 'virtual_account',
            'bank_name' => 'BCA',
            'account_number' => '812345678901',
            'account_name' => 'GeoDesa Connect',
            'label' => 'VA Utama',
            'instructions' => 'Transfer sesuai total order.',
        ];
        $paymentInfo = [
            'va_number' => '812345678901',
            'account_number' => '812345678901',
            'account_name' => 'GeoDesa Connect',
            'bank_name' => 'BCA',
            'expiry_time' => now()->addHours(24)->toIso8601String(),
            'payment_type' => 'manual_transfer',
        ];
        Transaction::create([
            'user_id' => $this->buyer->id,
            'order_id' => $this->order->id,
            'manual_payment_account_id' => $accountId,
            'mode' => 'transfer',
            'status' => 'pending',
            'manual_payment_account_snapshot' => $snapshot,
            'payment_expires_at' => now()->addHours(24),
            'payment_details' => json_encode([
                'stage' => ManualPaymentService::WAITING_PAYMENT,
                'manual_payment' => true,
                'payment_info' => $paymentInfo,
            ]),
        ]);
    }

    public function test_owner_can_submit_proof_and_only_super_admin_can_approve_it(): void
    {
        Sanctum::actingAs($this->buyer);
        $this->post('/api/orders/'.$this->order->id.'/payment-proof', [
            'sender_name' => 'Nama Pengirim',
            'sender_bank' => 'BRI',
            'sender_account_number' => '1234567890',
            'transferred_amount' => 115000,
            'proof' => UploadedFile::fake()->image('bukti.jpg'),
        ], ['Accept' => 'application/json'])
            ->assertCreated()
            ->assertJsonPath('payment_state', ManualPaymentService::PROOF_SUBMITTED);

        $this->assertDatabaseHas('manual_payment_confirmations', [
            'order_id' => $this->order->id,
            'user_id' => $this->buyer->id,
            'status' => 'submitted',
        ]);
        $proofPath = DB::table('manual_payment_confirmations')->value('proof_path');
        $confirmationId = (int) DB::table('manual_payment_confirmations')->value('id');
        Storage::disk('local')->assertExists($proofPath);

        $this->postJson('/api/orders/'.$this->order->id.'/cancel')
            ->assertUnprocessable();

        DB::table('user_super')->insert([
            'user_id' => $this->otherUser->id,
            'keterangan' => 'Role tidak valid karena bukan ADM',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        Sanctum::actingAs($this->otherUser);
        $this->get('/api/manual-payment-confirmations/'.$confirmationId.'/proof', ['Accept' => 'application/json'])
            ->assertForbidden();

        Sanctum::actingAs($this->buyer);
        $this->get('/api/manual-payment-confirmations/'.$confirmationId.'/proof')
            ->assertOk();

        $ordinaryAdmin = $this->user('Admin Toko', 'ADM');
        Sanctum::actingAs($ordinaryAdmin);
        $this->postJson('/api/admin/manual-payments/'.$this->order->id.'/approve')
            ->assertForbidden();

        Sanctum::actingAs($this->admin);
        $this->postJson('/api/admin/manual-payments/'.$this->order->id.'/approve')
            ->assertOk();

        $this->assertDatabaseHas('transactions', [
            'order_id' => $this->order->id,
            'status' => 'approved',
            'payment_approved_by' => $this->admin->id,
        ]);
        $this->assertDatabaseHas('manual_payment_confirmations', [
            'order_id' => $this->order->id,
            'status' => 'approved',
            'reviewed_by' => $this->admin->id,
        ]);

        $this->postJson('/api/admin/manual-payments/'.$this->order->id.'/approve')
            ->assertUnprocessable();
    }

    public function test_rejected_proof_can_be_resubmitted_and_status_is_private_to_order_owner(): void
    {
        $this->submitProofAsBuyer();

        Sanctum::actingAs($this->admin);
        $this->postJson('/api/admin/manual-payments/'.$this->order->id.'/reject', [
            'reason' => 'Gambar bukti tidak terbaca dengan jelas.',
            'extend_deadline' => true,
        ])->assertOk();

        $this->assertDatabaseHas('manual_payment_confirmations', [
            'order_id' => $this->order->id,
            'status' => 'rejected',
            'rejection_reason' => 'Gambar bukti tidak terbaca dengan jelas.',
        ]);
        $this->assertDatabaseHas('transactions', [
            'order_id' => $this->order->id,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->otherUser);
        $this->getJson('/api/order/'.$this->order->id.'/status')->assertNotFound();

        Sanctum::actingAs($this->buyer);
        $this->getJson('/api/order/'.$this->order->id.'/status')
            ->assertOk()
            ->assertJsonPath('payment_state', ManualPaymentService::PROOF_REJECTED)
            ->assertJsonPath('rejection_reason', 'Gambar bukti tidak terbaca dengan jelas.');

        $this->post('/api/orders/'.$this->order->id.'/payment-proof', [
            'sender_name' => 'Nama Pengirim',
            'sender_bank' => 'BRI',
            'sender_account_number' => '1234567890',
            'transferred_amount' => 115000,
            'proof' => UploadedFile::fake()->image('bukti-baru.png'),
        ], ['Accept' => 'application/json'])->assertCreated();

        $this->assertDatabaseCount('manual_payment_confirmations', 2);
        $this->assertDatabaseHas('manual_payment_confirmations', [
            'order_id' => $this->order->id,
            'status' => 'submitted',
        ]);
    }

    public function test_option_a_uses_one_primary_account_and_keeps_the_order_snapshot(): void
    {
        $ordinaryAdmin = $this->user('Admin Toko Kedua', 'ADM');
        Sanctum::actingAs($ordinaryAdmin);
        $this->postJson('/api/admin/manual-payment-accounts', [
            'account_type' => 'virtual_account',
            'bank_name' => 'BNI',
            'account_number' => '998877665544',
            'account_name' => 'GeoDesa Connect',
            'is_active' => true,
            'is_primary' => true,
        ])->assertForbidden();

        Sanctum::actingAs($this->admin);
        $response = $this->postJson('/api/admin/manual-payment-accounts', [
            'account_type' => 'virtual_account',
            'bank_name' => 'BNI',
            'account_number' => '998877665544',
            'account_name' => 'GeoDesa Connect',
            'label' => 'VA Baru',
            'is_active' => true,
            'is_primary' => true,
        ])->assertCreated();
        $newAccountId = (int) $response->json('data.id');

        $this->assertDatabaseHas('manual_payment_accounts', [
            'id' => $newAccountId,
            'is_primary' => true,
        ]);
        $this->assertSame(1, DB::table('manual_payment_accounts')->where('is_active', true)->where('is_primary', true)->count());

        $transaction = $this->order->transaction;
        $transaction->manual_payment_account_id = null;
        $transaction->manual_payment_account_snapshot = null;
        $transaction->payment_expires_at = null;
        $transaction->payment_details = json_encode([
            'stage' => 'core_api_charged',
            'payment_type' => 'bank_transfer',
        ]);
        $transaction->save();

        app(ManualPaymentService::class)->ensureInstructionForLegacyOrder($this->order->fresh('transaction'));
        $transaction->refresh();
        $this->assertSame($newAccountId, (int) $transaction->manual_payment_account_id);
        $this->assertSame('998877665544', $transaction->manual_payment_account_snapshot['account_number']);

        $this->putJson('/api/admin/manual-payment-accounts/'.$newAccountId, [
            'account_type' => 'virtual_account',
            'bank_name' => 'BNI',
            'account_number' => '111122223333',
            'account_name' => 'GeoDesa Connect',
            'label' => 'VA Baru',
            'is_active' => true,
            'is_primary' => true,
        ])->assertOk();

        $this->assertSame('998877665544', $transaction->fresh()->manual_payment_account_snapshot['account_number']);

        $this->putJson('/api/admin/manual-payment-accounts/'.$newAccountId, [
            'account_type' => 'virtual_account',
            'bank_name' => 'BNI',
            'account_number' => '111122223333',
            'account_name' => 'GeoDesa Connect',
            'label' => 'VA Baru',
            'is_active' => false,
            'is_primary' => true,
        ])->assertOk();
        $this->assertDatabaseHas('manual_payment_accounts', [
            'id' => $newAccountId,
            'is_active' => false,
            'is_primary' => false,
        ]);
        $this->assertSame(1, DB::table('manual_payment_accounts')->where('is_active', true)->where('is_primary', true)->count());
    }

    public function test_expired_unsubmitted_payment_is_canceled_and_stock_is_restored_once(): void
    {
        $transaction = $this->order->transaction;
        $transaction->payment_expires_at = now()->subMinute();
        $transaction->save();

        Sanctum::actingAs($this->buyer);
        $this->getJson('/api/order/'.$this->order->id.'/status')
            ->assertOk()
            ->assertJsonPath('payment_state', ManualPaymentService::EXPIRED)
            ->assertJsonPath('order_status', 'canceled');

        $this->assertDatabaseHas('transactions', [
            'order_id' => $this->order->id,
            'status' => 'declined',
        ]);
        $this->assertDatabaseHas('products', [
            'id' => $this->product->id,
            'quantity' => 10,
            'stock_status' => 'instock',
        ]);

        $this->getJson('/api/order/'.$this->order->id.'/status')->assertOk();
        $this->assertDatabaseHas('products', [
            'id' => $this->product->id,
            'quantity' => 10,
        ]);
    }

    private function submitProofAsBuyer(): void
    {
        Sanctum::actingAs($this->buyer);
        $this->post('/api/orders/'.$this->order->id.'/payment-proof', [
            'sender_name' => 'Nama Pengirim',
            'sender_bank' => 'BRI',
            'sender_account_number' => '1234567890',
            'transferred_amount' => 115000,
            'proof' => UploadedFile::fake()->image('bukti.jpg'),
        ], ['Accept' => 'application/json'])->assertCreated();
    }

    private function user(string $name, string $utype): User
    {
        return User::create([
            'name' => $name,
            'email' => strtolower(str_replace(' ', '.', $name)).'.'.fake()->unique()->randomNumber(5).'@example.test',
            'password' => 'password',
            'phone' => '081234567890',
            'utype' => $utype,
        ]);
    }

    private function createTables(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('phone')->nullable();
            $table->string('password');
            $table->string('utype')->default('USR');
            $table->rememberToken();
            $table->timestamps();
        });
        Schema::create('user_super', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('keterangan');
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
            $table->unsignedInteger('quantity')->default(0);
            $table->unsignedInteger('weight')->default(1000);
            $table->timestamps();
        });
        Schema::create('product_variations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->string('name');
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
            $table->string('name');
            $table->string('phone');
            $table->string('locality');
            $table->text('address');
            $table->string('city');
            $table->string('state');
            $table->string('country');
            $table->string('zip');
            $table->string('status')->default('ordered');
            $table->date('canceled_date')->nullable();
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
        Schema::create('manual_payment_accounts', function (Blueprint $table) {
            $table->id();
            $table->string('account_type');
            $table->string('bank_name');
            $table->string('account_number');
            $table->string('account_name');
            $table->string('label')->nullable();
            $table->text('instructions')->nullable();
            $table->boolean('is_active')->default(true);
            $table->boolean('is_primary')->default(false);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('manual_payment_account_id')->nullable()->constrained('manual_payment_accounts')->nullOnDelete();
            $table->string('mode');
            $table->string('status')->default('pending');
            $table->string('payment_token')->nullable();
            $table->text('payment_url')->nullable();
            $table->text('payment_details')->nullable();
            $table->json('manual_payment_account_snapshot')->nullable();
            $table->timestamp('payment_expires_at')->nullable();
            $table->timestamp('payment_approved_at')->nullable();
            $table->foreignId('payment_approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
        Schema::create('manual_payment_confirmations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transaction_id')->constrained()->cascadeOnDelete();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('sender_name');
            $table->string('sender_bank');
            $table->string('sender_account_number');
            $table->decimal('transferred_amount', 15, 2);
            $table->timestamp('transferred_at')->nullable();
            $table->string('proof_path');
            $table->text('note')->nullable();
            $table->string('status');
            $table->text('rejection_reason')->nullable();
            $table->timestamp('submitted_at');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();
        });
        Schema::create('manual_payment_audits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transaction_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('order_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action');
            $table->string('from_status')->nullable();
            $table->string('to_status')->nullable();
            $table->text('reason')->nullable();
            $table->json('metadata')->nullable();
            $table->string('ip_address')->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamps();
        });
    }
}
