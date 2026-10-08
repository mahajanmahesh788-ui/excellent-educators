<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('academic_level_assessments', function (Blueprint $table) {
            $table->foreignUlid('level_id')->constrained('academic_levels')->cascadeOnDelete();
            $table->foreignUlid('aptitude_assessment_id')
                ->constrained('aptitude_assessments')
                ->cascadeOnDelete();
            $table->timestamps();

            $table->primary(['level_id', 'aptitude_assessment_id'], 'level_assessment_primary');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('academic_level_assessments');
    }
};
