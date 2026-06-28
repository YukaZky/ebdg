<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class AuthRegistrationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config()->set('database.default', 'auth_registration_testing');
        config()->set('database.connections.auth_registration_testing', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => true,
        ]);

        DB::purge('auth_registration_testing');
        DB::setDefaultConnection('auth_registration_testing');

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->string('utype')->default('USR');
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });
    }

    public function test_user_can_register_and_use_returned_token(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => ' Budi Santoso ',
            'email' => 'BUDI@example.COM',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertCreated()
            ->assertJsonPath('message', 'Registrasi berhasil.')
            ->assertJsonPath('token_type', 'Bearer')
            ->assertJsonPath('user.name', 'Budi Santoso')
            ->assertJsonPath('user.email', 'budi@example.com')
            ->assertJsonPath('user.utype', 'ADM')
            ->assertJsonStructure([
                'access_token',
                'token_type',
                'user' => ['id', 'name', 'email', 'utype'],
            ]);

        $this->assertDatabaseHas('users', [
            'name' => 'Budi Santoso',
            'email' => 'budi@example.com',
            'utype' => 'ADM',
        ]);

        $this->withHeader('Authorization', 'Bearer ' . $response->json('access_token'))
            ->getJson('/api/user-profile')
            ->assertOk()
            ->assertJsonPath('email', 'budi@example.com')
            ->assertJsonPath('utype', 'ADM');
    }

    public function test_register_rejects_mismatched_password_confirmation(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Budi Santoso',
            'email' => 'budi@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password456',
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['password']);

        $this->assertDatabaseCount('users', 0);
    }

    public function test_register_rejects_duplicate_email(): void
    {
        DB::table('users')->insert([
            'name' => 'Existing User',
            'email' => 'budi@example.com',
            'password' => Hash::make('password123'),
            'utype' => 'USR',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->postJson('/api/register', [
            'name' => 'Budi Baru',
            'email' => 'BUDI@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['email']);

        $this->assertDatabaseCount('users', 1);
    }
}
