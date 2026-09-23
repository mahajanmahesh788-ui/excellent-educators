<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admin_profiles', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('phone', 32)->nullable();
            $table->string('gender', 16)->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique('user_id');
            $table->unique('phone');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_profiles');
    }
};
