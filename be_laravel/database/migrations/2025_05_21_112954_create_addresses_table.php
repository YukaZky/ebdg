<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('addresses', function (Blueprint $table) {
            $table->id();
            $table->bigInteger('user_id')->unsigned();
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
            $table->timestamps();
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('addresses');
    }
};
