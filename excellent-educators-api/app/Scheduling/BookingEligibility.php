<?php

namespace App\Scheduling;

use App\Attendance\AttendanceService;
use App\Enums\BatchStatus;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\WeeklyAssignmentAttempt;
use App\Support\AppClock;
use App\Support\AppSettings;
use Illuminate\Support\Collection;

class BookingEligibility
{
    /** Default when no admin setting is stored (kept for tests / helpers). */
    public const MASTER_CLASS_REQUIRED_LEVEL_WEEKS = 4;

    /**
     * @return array<string, mixed>
     */
    public function forStudent(StudentProfile $student): array
    {
        $student->loadMissing(['academicLevel.masterTeachers.user', 'activeEnrollment.batch.level.masterTeachers.user']);

        $introCompleted = $this->introductionCompleted($student);
        $hasUpcomingIntro = $this->hasUpcoming($student, SessionBookingType::IntroductionCall);
        $introCount = $this->introductionBookingCount($student);
        $introRebooking = app(AttendanceService::class)
            ->unusedRebookingFor($student->id, SessionBookingType::IntroductionCall);
        $batchReady = $this->levelBatchReadyForBooking($student);
        $canBookIntro = $batchReady
            && ! $hasUpcomingIntro
            && ! $introCompleted
            && ($introCount < 2 || $introRebooking !== null);
        $balance = app(MasterClassBalance::class)->snapshot($student);
        $levelWeeksCompleted = $this->levelWeeksCompletedForMasterClass($student);
        $requiresLevelWeeks = $this->masterClassRequiresLevelWeeks($student);
        $canBookMaster = $this->canBookMasterClass($student);

        return [
            'introduction_completed' => $introCompleted,
            'can_book_introduction' => $canBookIntro,
            'level_batch_ready' => $batchReady,
            'introduction_last_chance' => $canBookIntro && $introCount >= 1,
            'introduction_attempts_used' => $introCount,
            'introduction_attempts_max' => 2,
            'can_book_master_class' => $canBookMaster,
            'has_upcoming_introduction' => $hasUpcomingIntro,
            'has_master_class_this_month' => $introCompleted && ! $requiresLevelWeeks && ! $canBookMaster,
            'master_class_rebooking_available' => app(AttendanceService::class)
                ->unusedRebookingFor($student->id, SessionBookingType::MasterClass) !== null,
            'master_class_attempts_used' => $balance['used'],
            'master_class_attempts_max' => $balance['allotment'],
            'master_class_remaining' => $balance['remaining'],
            'master_class_requires_level_weeks' => $requiresLevelWeeks,
            'level_weeks_completed' => $levelWeeksCompleted,
            'level_weeks_required' => $this->requiredLevelWeeks(),
            'current_month' => AppClock::currentYearMonth(),
        ];
    }

    public function requiredLevelWeeks(): int
    {
        return app(AppSettings::class)->masterClassRequiredLevelWeeks();
    }

    public function introductionCompleted(StudentProfile $student): bool
    {
        return SessionBooking::query()
            ->where('student_id', $student->id)
            ->where('type', SessionBookingType::IntroductionCall->value)
            ->where('status', SessionBookingStatus::Completed->value)
            ->exists();
    }

    public function introductionBookingCount(StudentProfile $student): int
    {
        return SessionBooking::query()
            ->where('student_id', $student->id)
            ->where('type', SessionBookingType::IntroductionCall->value)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->count();
    }

    public function hasUpcoming(StudentProfile $student, SessionBookingType $type, ?string $ignoreBookingId = null): bool
    {
        $now = AppClock::now();

        return SessionBooking::query()
            ->where('student_id', $student->id)
            ->where('type', $type->value)
            ->where('status', SessionBookingStatus::Scheduled->value)
            ->where(function ($query) use ($now): void {
                $query->where('ends_at', '>', $now)
                    ->orWhere(function ($fallback) use ($now): void {
                        $fallback->whereNull('ends_at')->where('starts_at', '>=', $now);
                    });
            })
            ->when($ignoreBookingId, fn ($q) => $q->where('id', '!=', $ignoreBookingId))
            ->exists();
    }

    public function canBookMasterClass(StudentProfile $student, ?string $ignoreBookingId = null): bool
    {
        if (! $this->levelBatchReadyForBooking($student)) {
            return false;
        }
        if (! $this->introductionCompleted($student)) {
            return false;
        }
        if ($this->masterClassRequiresLevelWeeks($student)) {
            return false;
        }
        if ($this->hasUpcoming($student, SessionBookingType::MasterClass, $ignoreBookingId)) {
            return false;
        }
        if ($ignoreBookingId !== null) {
            return true;
        }

        return app(MasterClassBalance::class)->remaining($student) > 0;
    }

    /**
     * Booking is allowed when:
     * - the student has an open level journey (mid-level continuity), or
     * - the current batch is active, or
     * - the student is still on Level 1 with no completed journey (onboarding
     *   may book while Batch 1 waits to fill).
     *
     * After promotion into an inactive Level 2+ batch, journeys are closed and
     * no new journey starts — booking stays locked until that batch activates.
     */
    public function levelBatchReadyForBooking(StudentProfile $student): bool
    {
        $student->loadMissing(['activeEnrollment.batch', 'currentLevelJourney', 'academicLevel']);

        if ($student->currentLevelJourney !== null) {
            return true;
        }

        $batch = $student->activeEnrollment?->batch;
        if ($batch !== null) {
            $status = $batch->status instanceof BatchStatus
                ? $batch->status
                : BatchStatus::tryFrom((string) $batch->status);
            if ($status === BatchStatus::Active) {
                return true;
            }
        }

        $levelNumber = (int) ($student->academicLevel?->number ?? 0);
        if ($levelNumber > 1) {
            return false;
        }

        $completedALevel = $student->levelJourneys()
            ->whereNotNull('ended_at')
            ->exists();

        return ! $completedALevel;
    }

    /**
     * Master Class stays locked after Introduction until the student completes
     * the configured number of weekly assignments on the current level (0–5).
     */
    public function masterClassRequiresLevelWeeks(StudentProfile $student): bool
    {
        if (! $this->introductionCompleted($student)) {
            return false;
        }

        $required = $this->requiredLevelWeeks();
        if ($required <= 0) {
            return false;
        }

        return $this->levelWeeksCompletedForMasterClass($student) < $required;
    }

    public function levelWeeksCompletedForMasterClass(StudentProfile $student): int
    {
        $required = $this->requiredLevelWeeks();
        if ($required <= 0) {
            return 0;
        }

        // Query directly — avoid a stale null currentLevelJourney relation from earlier in the request.
        $journeyId = \App\Models\StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->value('id');

        if ($journeyId === null) {
            return 0;
        }

        return (int) WeeklyAssignmentAttempt::query()
            ->where('student_id', $student->id)
            ->where('student_level_journey_id', $journeyId)
            ->whereBetween('week_number', [1, $required])
            ->distinct()
            ->count('week_number');
    }

    /**
     * @return Collection<int, SessionBooking>
     */
    private function masterClassesThisMonth(StudentProfile $student, ?string $ignoreBookingId = null): Collection
    {
        $month = AppClock::currentYearMonth();

        return SessionBooking::query()
            ->where('student_id', $student->id)
            ->where('type', SessionBookingType::MasterClass->value)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->when($ignoreBookingId, fn ($q) => $q->where('id', '!=', $ignoreBookingId))
            ->orderBy('starts_at')
            ->get()
            ->filter(function (SessionBooking $booking) use ($month): bool {
                $local = $booking->starts_at?->timezone(config('app.timezone'));
                if ($local === null && $booking->date !== null) {
                    $local = $booking->date->timezone(config('app.timezone'));
                }
                if ($local === null) {
                    return false;
                }

                return $local->year === $month['year'] && $local->month === $month['month'];
            })
            ->values();
    }

    public function attemptNumber(SessionBooking $booking): ?int
    {
        $type = $booking->type?->value ?? $booking->type;
        $student = $booking->student ?? StudentProfile::query()->find($booking->student_id);
        if ($student === null) {
            return null;
        }

        if ($type === SessionBookingType::IntroductionCall->value) {
            $items = SessionBooking::query()
                ->where('student_id', $student->id)
                ->where('type', SessionBookingType::IntroductionCall->value)
                ->where('status', '!=', SessionBookingStatus::Cancelled->value)
                ->orderBy('starts_at')
                ->get();
            foreach ($items->values() as $index => $item) {
                if ($item->id === $booking->id) {
                    return $index + 1;
                }
            }

            return $items->count() + 1;
        }

        if ($type !== SessionBookingType::MasterClass->value) {
            return null;
        }

        $items = $this->masterClassesThisMonth($student);
        foreach ($items->values() as $index => $item) {
            if ($item->id === $booking->id) {
                return $index + 1;
            }
        }

        return $items->count() + 1;
    }

    public function learningWeekFor(SessionBooking $booking): ?int
    {
        $student = $booking->student ?? StudentProfile::query()->find($booking->student_id);
        $at = $booking->starts_at;
        if ($student === null || $at === null) {
            return null;
        }

        $journey = $student->currentLevelJourney
            ?? $student->levelJourneys()
                ->where('started_at', '<=', $at)
                ->where(function ($query) use ($at): void {
                    $query->whereNull('ended_at')->orWhere('ended_at', '>=', $at);
                })
                ->orderByDesc('started_at')
                ->first();

        return $journey?->weekNumberAt($at);
    }

    /**
     * @return Collection<int, TeacherProfile>
     */
    public function eligibleTeachers(StudentProfile $student): Collection
    {
        $level = $student->academicLevel ?? $student->activeEnrollment?->batch?->level;
        if ($level === null) {
            return collect();
        }

        $level->loadMissing('masterTeachers.user');

        return $level->masterTeachers->unique('id')->values();
    }

    public function teacherIsEligible(StudentProfile $student, TeacherProfile $teacher): bool
    {
        return $this->eligibleTeachers($student)->contains(fn (TeacherProfile $item) => $item->id === $teacher->id);
    }
}
