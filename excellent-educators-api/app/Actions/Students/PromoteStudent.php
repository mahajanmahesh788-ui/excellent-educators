<?php

namespace App\Actions\Students;

use App\Actions\Batches\AllocateBatchForStudent;
use App\Actions\Learning\StartStudentLevelJourney;
use App\Actions\Notifications\CreateUserNotification;
use App\Enums\NotificationType;
use App\Exceptions\ApiException;
use App\Models\AcademicLevel;
use App\Models\StudentProfile;
use App\Models\User;
use App\Support\ErrorCode;
use App\Support\StudentActivity;
use Illuminate\Support\Facades\DB;
use Throwable;

class PromoteStudent
{
    public function __construct(
        private readonly AllocateBatchForStudent $allocateBatchForStudent,
        private readonly StartStudentLevelJourney $startStudentLevelJourney,
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
            $student->loadMissing(['academicLevel', 'user']);
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

            $fresh = $student->fresh(['user']) ?? $student;
            $this->notifyPromotion($fresh, $from, $level->name);

            return $fresh;
        });
    }

    private function notifyPromotion(StudentProfile $student, ?string $from, string $to): void
    {
        try {
            $user = $student->user;
            if ($user === null) {
                return;
            }

            $body = $from !== null && $from !== ''
                ? "You moved from {$from} to {$to}."
                : "Your level was updated to {$to}.";

            $this->notifications->execute(
                $user,
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
        } catch (Throwable) {
            // Promotion must succeed even if notify fails.
        }
    }
}
