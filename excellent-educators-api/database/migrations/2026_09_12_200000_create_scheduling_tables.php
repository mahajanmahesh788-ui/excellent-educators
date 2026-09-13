<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('teacher_breaks', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('teacher_id')->constrained('teacher_profiles')->cascadeOnDelete();
            $table->string('type');
            $table->time('start_time');
            $table->time('end_time');
            $table->boolean('is_recurring')->default(true);
            $table->timestamps();
            $table->unique(['teacher_id', 'type']);
        });

        Schema::create('teacher_weekly_offs', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('teacher_id')->constrained('teacher_profiles')->cascadeOnDelete();
            $table->unsignedTinyInteger('weekday');
            $table->timestamps();
            $table->unique(['teacher_id', 'weekday']);
        });

        Schema::create('teacher_leaves', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('teacher_id')->constrained('teacher_profiles')->cascadeOnDelete();
            $table->date('date');
            $table->time('start_time');
            $table->time('end_time');
            $table->boolean('is_full_day')->default(false);
            $table->foreignUlid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['teacher_id', 'date']);
        });

        Schema::create('session_bookings', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->cascadeOnDelete();
            $table->foreignUlid('teacher_id')->constrained('teacher_profiles')->cascadeOnDelete();
            $table->string('type');
            $table->date('date');
            $table->dateTime('starts_at');
            $table->dateTime('ends_at');
            $table->string('status')->default('scheduled');
            $table->timestamps();
            $table->index(['teacher_id', 'date', 'status']);
            $table->index(['student_id', 'type', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('session_bookings');
        Schema::dropIfExists('teacher_leaves');
        Schema::dropIfExists('teacher_weekly_offs');
        Schema::dropIfExists('teacher_breaks');
    }
};
