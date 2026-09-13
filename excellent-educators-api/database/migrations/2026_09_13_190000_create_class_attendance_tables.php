<?php

return new class extends \Illuminate\Database\Migrations\Migration
{
    public function up(): void
    {
        \Illuminate\Support\Facades\Schema::create('class_attendances', function (\Illuminate\Database\Schema\Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->unique()->constrained('session_bookings')->cascadeOnDelete();
            $table->foreignUlid('student_id')->constrained('student_profiles')->cascadeOnDelete();
            $table->foreignUlid('teacher_id')->constrained('teacher_profiles')->cascadeOnDelete();
            $table->timestamp('student_first_join_at')->nullable();
            $table->timestamp('student_last_join_at')->nullable();
            $table->unsignedInteger('student_join_count')->default(0);
            $table->timestamp('teacher_first_join_at')->nullable();
            $table->timestamp('teacher_last_join_at')->nullable();
            $table->unsignedInteger('teacher_join_count')->default(0);
            $table->boolean('rebooking_granted')->default(false);
            $table->timestamp('rebooking_granted_at')->nullable();
            $table->foreignUlid('replacement_booking_id')->nullable()->constrained('session_bookings')->nullOnDelete();
            $table->timestamps();
        });

        \Illuminate\Support\Facades\Schema::create('class_join_events', function (\Illuminate\Database\Schema\Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->constrained('session_bookings')->cascadeOnDelete();
            $table->string('actor_type');
            $table->ulid('actor_id');
            $table->timestamp('joined_at');
            $table->timestamps();
            $table->index(['booking_id', 'actor_type']);
        });

        \Illuminate\Support\Facades\Schema::create('attendance_issues', function (\Illuminate\Database\Schema\Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->constrained('session_bookings')->cascadeOnDelete();
            $table->foreignUlid('reporter_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('reporter_role');
            $table->string('issue_type');
            $table->text('message');
            $table->string('verification_status')->default('pending');
            $table->string('admin_decision')->nullable();
            $table->text('admin_notes')->nullable();
            $table->foreignUlid('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();
            $table->unique(['booking_id', 'issue_type']);
        });

        \Illuminate\Support\Facades\Schema::table('teacher_daily_meetings', function (\Illuminate\Database\Schema\Blueprint $table) {
            $table->timestamp('first_join_at')->nullable();
            $table->timestamp('last_join_at')->nullable();
            $table->unsignedInteger('join_count')->default(0);
        });
    }

    public function down(): void
    {
        \Illuminate\Support\Facades\Schema::table('teacher_daily_meetings', function (\Illuminate\Database\Schema\Blueprint $table) {
            $table->dropColumn(['first_join_at', 'last_join_at', 'join_count']);
        });
        \Illuminate\Support\Facades\Schema::dropIfExists('attendance_issues');
        \Illuminate\Support\Facades\Schema::dropIfExists('class_join_events');
        \Illuminate\Support\Facades\Schema::dropIfExists('class_attendances');
    }
};
