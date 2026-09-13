<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('academic_level_teachers', function (Blueprint $table) {
            $table->foreignUlid('level_id')->constrained('academic_levels')->cascadeOnDelete();
            $table->foreignUlid('teacher_id')->constrained('teacher_profiles')->cascadeOnDelete();
            $table->primary(['level_id', 'teacher_id']);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('academic_level_teachers');
    }
};
