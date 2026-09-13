<?php

namespace App\Scheduling;

use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Support\AppClock;
use Illuminate\Support\Collection;

class BookingEligibility
{
    /**
     * @return array<string, mixed>
     */
    public function forStudent(StudentProfile $student): array
    {
        $student->loadMissing(['academicLevel.masterTeachers.user', 'activeEnrollment.batch.level.masterTeachers.user']);

        $introCompleted = $this->introductionCompleted($student);
        $hasUpcomingIntro = $this->hasUpcoming($student, SessionBookingType::IntroductionCall);
        $introCount = $this->introductionBookingCount($student);
        $introRebooking = app(\App\Attendance\AttendanceService::class)
            ->unusedRebookingFor($student->id, SessionBookingType::IntroductionCall);
        $canBookIntro = ! $hasUpcomingIntro && ! $introCompleted && ($introCount < 2 || $introRebooking !== null);

        return [
            'introduction_completed' => $introCompleted,
            'can_book_introduction' => $canBookIntro,
            'introduction_last_chance' => $canBookIntro && $introCount >= 1,
            'introduction_attempts_used' => $introCount,
            'introduction_attempts_max' => 2,
            'can_book_master_class' => $this->canBookMasterClass($student),
            'has_upcoming_introduction' => $hasUpcomingIntro,
            'has_master_class_this_month' => ! $this->canBookMasterClass($student) && $introCompleted,
            'master_class_attempts_used' => $this->masterClassesThisMonth($student)->count(),
            'master_class_attempts_max' => 2,
            'level_started_on' => $this->levelStartedOn($student),
            'current_month' => AppClock::currentYearMonth(),
        ];
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
            ->where('starts_at', '>', $now)
            ->when($ignoreBookingId, fn ($q) => $q->where('id', '!=', $ignoreBookingId))
            ->exists();
    }

    public function canBookMasterClass(StudentProfile $student, ?string $ignoreBookingId = null): bool
    {
        if (! $this->introductionCompleted($student)) {
            return false;
        }
        if ($this->hasUpcoming($student, SessionBookingType::MasterClass, $ignoreBookingId)) {
            return false;
        }

        $items = $this->masterClassesThisMonth($student, $ignoreBookingId);
        if ($items->contains(fn (SessionBooking $booking) => $booking->status === SessionBookingStatus::Completed)) {
            return false;
        }

        return $items->count() < 2;
    }

    /**
     * @return Collection<int, SessionBooking>
     */
    public function masterClassesThisMonth(StudentProfile $student, ?string $ignoreBookingId = null): Collection
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
                if ($local === null) {
                    return false;
                }

                return $local->year === $month['year'] && $local->month === $month['month'];
            })
            ->values();
    }

    public function hasMasterClassThisMonth(StudentProfile $student, ?string $ignoreBookingId = null): bool
    {
        return ! $this->canBookMasterClass($student, $ignoreBookingId);
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

    public static function ordinal(int $value): string
    {
        $mod100 = $value % 100;
        if ($mod100 >= 11 && $mod100 <= 13) {
            return $value.'th';
        }

        return $value.match ($value % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            default => 'th',
        };
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

    public function levelStartedOn(StudentProfile $student): ?string
    {
        $enrollment = $student->activeEnrollment;
        if ($enrollment?->enrolled_at !== null) {
            return $enrollment->enrolled_at->timezone(config('app.timezone'))->toDateString();
        }

        return $student->created_at?->timezone(config('app.timezone'))->toDateString();
    }
}
