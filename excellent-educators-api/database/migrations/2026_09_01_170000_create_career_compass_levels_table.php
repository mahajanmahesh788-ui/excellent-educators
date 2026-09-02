<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('career_compass_levels', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('code', 16)->unique();
            $table->string('name');
            $table->unsignedTinyInteger('class_from');
            $table->unsignedTinyInteger('class_to');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('career_compass_levels');
    }
};
