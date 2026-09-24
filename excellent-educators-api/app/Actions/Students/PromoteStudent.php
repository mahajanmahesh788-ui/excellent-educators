<?php

namespace App\Actions\Students;

use App\Actions\Batches\AllocateBatchForStudent;
use App\Actions\Learning\StartStudentLevelJourney;
use App\Exceptions\ApiException;
use App\Models\AcademicLevel;
use App\Models\StudentProfile;
use App\Models\User;
use App\Support\ErrorCode;
use App\Support\StudentActivity;
use Illuminate\Support\Facades\DB;

class PromoteStudent
{
    public function __construct(
        private readonly AllocateBatchForStudent $allocateBatchForStudent,
        private readonly StartStudentLevelJourney $startStudentLevelJourney,
    ) {}

    public function execute(StudentProfile $student, AcademicLevel $level, User $actor): StudentProfile
    {
        if ($student->level_id === $level->id) {
            throw new ApiException(
                ErrorCode::CONFLICT,
                'Student is already on this level.',
                409,
            );
        }

        return DB::transaction(function () use ($student, $level, $actor): StudentProfile {
            $student->loadMissing('academicLevel');
            $from = $student->academicLevel?->name;
            $student->update(['level_id' => $level->id]);
            $this->allocateBatchForStudent->execute($level, $student->fresh(), $actor);
            $this->startStudentLevelJourney->executeIfBatchActive($student->fresh(), $level);
            StudentActivity::record(
                $student->fresh(),
                'level_changed',
                $from
                    ? "Admin updated the student from {$from} to {$level->name}"
                    : "Admin updated the student to {$level->name}",
                actor: $actor,
                related: $level,
            );

            return $student->fresh();
        });
    }
}
