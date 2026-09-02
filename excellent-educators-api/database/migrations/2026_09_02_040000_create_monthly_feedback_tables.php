<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('monthly_feedbacks', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->restrictOnDelete();
            $table->foreignUlid('master_teacher_id')->constrained('teacher_profiles')->restrictOnDelete();
            $table->unsignedSmallInteger('year');
            $table->unsignedTinyInteger('month');
            $table->timestamp('submitted_at');
            $table->timestamps();
            $table->unique(['student_id', 'year', 'month']);
        });

        Schema::create('monthly_feedback_items', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('monthly_feedback_id')->constrained('monthly_feedbacks')->restrictOnDelete();
            $table->string('target_type');
            $table->ulid('target_id');
            $table->unsignedTinyInteger('rating');
            $table->text('positive_points')->nullable();
            $table->text('areas_for_improvement')->nullable();
            $table->text('recommended_next_action')->nullable();
            $table->timestamps();
            $table->index(['target_type', 'target_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('monthly_feedback_items');
        Schema::dropIfExists('monthly_feedbacks');
    }
};
