<?php

namespace App\Actions\Learning;

use App\Models\AcademicLevel;
use App\Models\StudentLevelJourney;
use App\Models\StudentProfile;
use App\Support\AppClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class StartStudentLevelJourney
{
    public function execute(StudentProfile $student, AcademicLevel $level, ?Carbon $startedAt = null): StudentLevelJourney
    {
        return DB::transaction(function () use ($student, $level, $startedAt): StudentLevelJourney {
            $now = $startedAt ?? AppClock::now();

            $current = StudentLevelJourney::query()
                ->where('student_id', $student->id)
                ->whereNull('ended_at')
                ->orderBy('started_at')
                ->first();

            if ($current !== null && $current->level_id === $level->id) {
                return $current;
            }

            StudentLevelJourney::query()
                ->where('student_id', $student->id)
                ->whereNull('ended_at')
                ->update(['ended_at' => $now]);

            return StudentLevelJourney::query()->create([
                'student_id' => $student->id,
                'level_id' => $level->id,
                'started_at' => $now,
                'ended_at' => null,
            ]);
        });
    }

    public function ensure(StudentProfile $student): ?StudentLevelJourney
    {
        if ($student->level_id === null) {
            return StudentLevelJourney::query()
                ->where('student_id', $student->id)
                ->whereNull('ended_at')
                ->first();
        }

        $level = $student->academicLevel ?? AcademicLevel::query()->find($student->level_id);
        if ($level === null) {
            return null;
        }

        return $this->execute($student, $level);
    }
}
