<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dimensions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('code', 8)->unique();
            $table->string('name');
            $table->unsignedSmallInteger('display_order');
            $table->timestamps();
        });

        Schema::create('modules', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('dimension_id')->constrained('dimensions')->restrictOnDelete();
            $table->string('name');
            $table->unsignedSmallInteger('display_order')->default(1);
            $table->timestamps();
        });

        Schema::create('skills', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('module_id')->constrained('modules')->restrictOnDelete();
            $table->string('name');
            $table->unsignedSmallInteger('display_order')->default(1);
            $table->timestamps();
        });

        $codes = "'P','I','CF','L','CM','DM','CR','CU','TW','FA'";

        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE dimensions ADD CONSTRAINT dimensions_code_check CHECK (code IN ({$codes}))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('skills');
        Schema::dropIfExists('modules');
        Schema::dropIfExists('dimensions');
    }
};
