<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('teacher_daily_meetings', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('teacher_id')->constrained('teacher_profiles')->cascadeOnDelete();
            $table->date('date');
            $table->string('google_event_id')->nullable();
            $table->string('google_meeting_space_id')->nullable();
            $table->string('meet_url')->nullable();
            $table->string('status')->default('pending');
            $table->timestamps();
            $table->unique(['teacher_id', 'date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('teacher_daily_meetings');
    }
};
