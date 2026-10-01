<?php

namespace App\Actions\Students;

use App\Actions\Batches\AllocateBatchForStudent;
use App\Actions\Learning\StartStudentLevelJourney;
use App\Actions\Mentoring\UnassignMasterTeacher;
use App\Actions\Notifications\CreateUserNotification;
use App\Enums\NotificationType;
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
        private readonly UnassignMasterTeacher $unassignMasterTeacher,
        private readonly CreateUserNotification $notifications,
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
            $student->loadMissing(['academicLevel', 'user', 'activeMasterTeacherAssignment.teacher']);
            $from = $student->academicLevel?->name;
            $student->update(['level_id' => $level->id]);
            $this->allocateBatchForStudent->execute($level, $student->fresh(), $actor);

            // Always close the previous level journey on promote so history stays
            // readable. Start the new-level Week 1 journey only when the new batch
            // is already active; otherwise the student waits without being locked out.
            $this->startStudentLevelJourney->endOpenJourneys($student->fresh());
            $this->startStudentLevelJourney->executeIfBatchActive($student->fresh(), $level);

            // Level 2 students belong to Level 2 teachers only — drop mentors who
            // are not assigned to the destination level.
            $this->releaseMentorIfNotOnLevel($student->fresh(), $level);

            StudentActivity::record(
                $student->fresh(),
                'level_changed',
                $from
                    ? "Updated the student from {$from} to {$level->name}"
                    : "Updated the student to {$level->name}",
                actor: $actor,
                related: $level,
            );

            $fresh = $student->fresh(['user']) ?? $student;
            $this->notifyPromotion($fresh, $from, $level->name);

            return $fresh;
        });
    }

    private function releaseMentorIfNotOnLevel(StudentProfile $student, AcademicLevel $level): void
    {
        $assignment = $student->activeMasterTeacherAssignment()->with('teacher')->first();
        $teacher = $assignment?->teacher;
        if ($teacher === null) {
            return;
        }

        $teachesTarget = $teacher->academicLevels()
            ->where('academic_levels.id', $level->id)
            ->exists();

        if (! $teachesTarget) {
            $this->unassignMasterTeacher->execute($student);
        }
    }

    private function notifyPromotion(StudentProfile $student, ?string $from, string $to): void
    {
        $body = $from !== null && $from !== ''
            ? "You moved from {$from} to {$to}."
            : "Your level was updated to {$to}.";

        $this->notifications->safeExecute(
            $student->user,
            NotificationType::StudentPromoted,
            'Level updated',
            $body,
            [
                'student_id' => $student->id,
                'from_level' => $from,
                'to_level' => $to,
                'link' => '/student/dashboard',
            ],
        );
    }
}
