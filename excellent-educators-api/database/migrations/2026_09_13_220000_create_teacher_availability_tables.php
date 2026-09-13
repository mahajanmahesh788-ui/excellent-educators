<?php

use App\Enums\TeacherWorkType;
use App\Models\TeacherProfile;
use App\Models\TeacherWeeklyOff;
use App\Scheduling\TeacherAvailability;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('teacher_profiles', function (Blueprint $table) {
            $table->string('work_type')->default(TeacherWorkType::FullTime->value)->after('status');
        });

        Schema::create('teacher_availability_rules', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('teacher_id')->constrained('teacher_profiles')->cascadeOnDelete();
            $table->unsignedTinyInteger('day_of_week');
            $table->time('start_time');
            $table->time('end_time');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->index(['teacher_id', 'day_of_week', 'is_active']);
        });

        Schema::create('teacher_availability_overrides', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('teacher_id')->constrained('teacher_profiles')->cascadeOnDelete();
            $table->date('date');
            $table->string('type');
            $table->time('start_time')->nullable();
            $table->time('end_time')->nullable();
            $table->timestamps();
            $table->index(['teacher_id', 'date']);
        });

        $availability = app(TeacherAvailability::class);
        TeacherProfile::query()->orderBy('id')->each(function (TeacherProfile $teacher) use ($availability): void {
            $offWeekdays = TeacherWeeklyOff::query()
                ->where('teacher_id', $teacher->id)
                ->pluck('weekday')
                ->all();
            $availability->seedDefaultWeekly($teacher, $offWeekdays);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('teacher_availability_overrides');
        Schema::dropIfExists('teacher_availability_rules');
        Schema::table('teacher_profiles', function (Blueprint $table) {
            $table->dropColumn('work_type');
        });
    }
};
