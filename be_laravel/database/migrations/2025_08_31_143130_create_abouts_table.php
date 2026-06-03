<?php

// database/migrations/xxxx_xx_xx_xxxxxx_create_abouts_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('abouts', function (Blueprint $table) {
             $table->id();
            $table->string('logo_image')->nullable();
            $table->string('poster_image')->nullable();
            $table->text('our_story')->nullable();
            $table->text('our_vision')->nullable();
            $table->text('our_mission')->nullable();
            $table->text('the_company')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('abouts');
    }
};