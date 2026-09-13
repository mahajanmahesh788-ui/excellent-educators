<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('weekly_learnings', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('level_id')->constrained('academic_levels')->cascadeOnDelete();
            $table->unsignedTinyInteger('week_number');
            $table->text('video_url');
            $table->timestamps();
            $table->unique(['level_id', 'week_number']);
        });

        Schema::create('weekly_learning_questions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('weekly_learning_id')->constrained('weekly_learnings')->cascadeOnDelete();
            $table->text('question_text');
            $table->unsignedInteger('display_order')->default(0);
            $table->timestamps();
        });

        Schema::create('weekly_learning_options', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('question_id')->constrained('weekly_learning_questions')->cascadeOnDelete();
            $table->string('option_text');
            $table->unsignedInteger('display_order')->default(0);
            $table->boolean('is_correct')->default(false);
            $table->timestamps();
        });

        Schema::create('student_level_journeys', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->cascadeOnDelete();
            $table->foreignUlid('level_id')->constrained('academic_levels')->cascadeOnDelete();
            $table->dateTime('started_at');
            $table->dateTime('ended_at')->nullable();
            $table->timestamps();
            $table->index(['student_id', 'ended_at']);
        });

        Schema::create('weekly_assignment_attempts', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->cascadeOnDelete();
            $table->foreignUlid('student_level_journey_id')->constrained('student_level_journeys')->cascadeOnDelete();
            $table->foreignUlid('weekly_learning_id')->constrained('weekly_learnings')->restrictOnDelete();
            $table->unsignedTinyInteger('week_number');
            $table->unsignedTinyInteger('attempt_number');
            $table->json('answers');
            $table->text('video_url');
            $table->timestamp('submitted_at');
            $table->timestamps();
            $table->unique(['student_id', 'weekly_learning_id', 'attempt_number'], 'weekly_attempts_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('weekly_assignment_attempts');
        Schema::dropIfExists('student_level_journeys');
        Schema::dropIfExists('weekly_learning_options');
        Schema::dropIfExists('weekly_learning_questions');
        Schema::dropIfExists('weekly_learnings');
    }
};
