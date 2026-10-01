<?php

namespace App\Actions\Teachers;

use App\Enums\SessionBookingStatus;
use App\Models\SessionBooking;
use App\Models\TeacherProfile;

class BuildMentorProfileStats
{
    /** Public floor shown on student-facing mentor profiles (not admin/teacher). */
    public const PUBLIC_STUDENTS_GUIDED_BASELINE = 49;

    /** Public floor shown on student-facing mentor profiles (not admin/teacher). */
    public const PUBLIC_SESSIONS_COMPLETED_BASELINE = 99;

    /**
     * @return array{students_guided: int, sessions_completed: int, rating_average: float|null}
     */
    public function execute(TeacherProfile $teacher, bool $includePublicBaseline = false): array
    {
        $sessionsCompleted = SessionBooking::query()
            ->where('teacher_id', $teacher->id)
            ->where(function ($query): void {
                $query->where('status', SessionBookingStatus::Completed->value)
                    ->orWhere(function ($inner): void {
                        $inner->where('status', '!=', SessionBookingStatus::Cancelled->value)
                            ->whereNotNull('ends_at')
                            ->where('ends_at', '<=', now());
                    });
            })
            ->count();

        $studentsGuided = (int) SessionBooking::query()
            ->where('teacher_id', $teacher->id)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->distinct('student_id')
            ->count('student_id');

        if ($studentsGuided === 0) {
            $studentsGuided = $teacher->activeMasterTeacherAssignments()->count();
        }

        if ($includePublicBaseline) {
            $studentsGuided += self::PUBLIC_STUDENTS_GUIDED_BASELINE;
            $sessionsCompleted += self::PUBLIC_SESSIONS_COMPLETED_BASELINE;
        }

        return [
            'students_guided' => $studentsGuided,
            'sessions_completed' => $sessionsCompleted,
            // Student→mentor ratings are not collected yet.
            'rating_average' => null,
        ];
    }
}
