<?php

namespace App\Scheduling;

use App\Attendance\AttendanceService;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Models\ClassAttendance;
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
        $introRebooking = app(AttendanceService::class)
            ->unusedRebookingFor($student->id, SessionBookingType::IntroductionCall);
        $canBookIntro = ! $hasUpcomingIntro && ! $introCompleted && ($introCount < 2 || $introRebooking !== null);
        $balance = app(MasterClassBalance::class)->snapshot($student);
        $journeyMonth = $this->journeyMonth($student);
        $masterOpensNextMonth = $this->masterClassOpensNextMonth($student);
        $canBookMaster = $this->canBookMasterClass($student);

        return [
            'introduction_completed' => $introCompleted,
            'can_book_introduction' => $canBookIntro,
            'introduction_last_chance' => $canBookIntro && $introCount >= 1,
            'introduction_attempts_used' => $introCount,
            'introduction_attempts_max' => 2,
            'can_book_master_class' => $canBookMaster,
            'has_upcoming_introduction' => $hasUpcomingIntro,
            'has_master_class_this_month' => $introCompleted && ! $masterOpensNextMonth && ! $canBookMaster,
            'master_class_rebooking_available' => app(AttendanceService::class)
                ->unusedRebookingFor($student->id, SessionBookingType::MasterClass) !== null,
            'master_class_attempts_used' => $balance['used'],
            'master_class_attempts_max' => $balance['allotment'],
            'master_class_remaining' => $balance['remaining'],
            'master_class_opens_next_month' => $masterOpensNextMonth,
            'journey_month' => $journeyMonth,
            'master_class_unlocks_on' => $this->masterClassUnlocksOn($student),
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
        if (! $this->introductionCompleted($student)) {
            return false;
        }
        if ($this->masterClassOpensNextMonth($student)) {
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
     * Master Class unlocks from the calendar month after the journey/batch start month.
     */
    public function masterClassOpensNextMonth(StudentProfile $student): bool
    {
        if (! $this->introductionCompleted($student)) {
            return false;
        }

        return $this->journeyMonth($student) < 2;
    }

    public function journeyMonth(StudentProfile $student): int
    {
        $started = \App\Models\StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->value('started_at');

        if ($started === null) {
            $student->loadMissing('activeEnrollment.batch');
            $started = $student->activeEnrollment?->batch?->starts_on;
        }

        if ($started === null) {
            // No journey/batch start yet — do not permanently block Master Class.
            return 2;
        }

        $startedAt = $started instanceof \Illuminate\Support\Carbon
            ? $started->copy()
            : \Illuminate\Support\Carbon::parse($started);

        $at = AppClock::now()->copy()->startOfMonth();
        $start = $startedAt->timezone(config('app.timezone'))->startOfMonth();

        return max(1, ((int) $start->diffInMonths($at)) + 1);
    }

    public function masterClassUnlocksOn(StudentProfile $student): ?string
    {
        $started = \App\Models\StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->value('started_at');

        if ($started === null) {
            $student->loadMissing('activeEnrollment.batch');
            $started = $student->activeEnrollment?->batch?->starts_on;
        }

        if ($started === null) {
            return null;
        }

        $startedAt = $started instanceof \Illuminate\Support\Carbon
            ? $started->copy()
            : \Illuminate\Support\Carbon::parse($started);

        return $startedAt->timezone(config('app.timezone'))->startOfMonth()->addMonth()->toDateString();
    }

    /**
     * @param  Collection<int, SessionBooking>  $items
     * @return list<string>
     */
    private function heldMasterClassIds(Collection $items): array
    {
        if ($items->isEmpty()) {
            return [];
        }

        $joinedIds = ClassAttendance::query()
            ->whereIn('booking_id', $items->pluck('id'))
            ->where('student_join_count', '>', 0)
            ->pluck('booking_id')
            ->all();
        $now = AppClock::now();
        $held = [];

        foreach ($items as $booking) {
            $status = $booking->status instanceof SessionBookingStatus
                ? $booking->status
                : SessionBookingStatus::from((string) $booking->status);
            $ended = $booking->ends_at !== null && $now->gte($booking->ends_at);
            $joined = in_array($booking->id, $joinedIds, true);

            if ($status === SessionBookingStatus::Completed || ($ended && $joined)) {
                $held[] = $booking->id;
                if ($status === SessionBookingStatus::Scheduled && $ended && $joined) {
                    $booking->update(['status' => SessionBookingStatus::Completed->value]);
                }
            }
        }

        return $held;
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
        $started = \App\Models\StudentLevelJourney::query()
            ->where('student_id', $student->id)
            ->whereNull('ended_at')
            ->value('started_at');

        if ($started !== null) {
            $startedAt = $started instanceof \Illuminate\Support\Carbon
                ? $started->copy()
                : \Illuminate\Support\Carbon::parse($started);

            return $startedAt->timezone(config('app.timezone'))->toDateString();
        }

        $student->loadMissing('activeEnrollment.batch');
        if ($student->activeEnrollment?->batch?->starts_on !== null) {
            return $student->activeEnrollment->batch->starts_on
                ->timezone(config('app.timezone'))
                ->toDateString();
        }

        $enrollment = $student->activeEnrollment;
        if ($enrollment?->enrolled_at !== null) {
            return $enrollment->enrolled_at->timezone(config('app.timezone'))->toDateString();
        }

        return $student->created_at?->timezone(config('app.timezone'))->toDateString();
    }
}
