<?php

namespace App\Actions\Teachers;

use App\Enums\AttendanceVerificationStatus;
use App\Enums\SessionBookingStatus;
use App\Enums\SessionBookingType;
use App\Models\MonthlyFeedback;
use App\Models\MonthlyFeedbackItem;
use App\Models\SessionBooking;
use App\Models\StudentLevelJourney;
use App\Models\TeacherLeave;
use App\Models\TeacherProfile;
use App\Support\AppClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class BuildTeacherHistory
{
    /**
     * @return array<string, mixed>
     */
    public function execute(TeacherProfile $teacher): array
    {
        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();
        $monthStart = Carbon::create($year, $month, 1, 0, 0, 0, config('app.timezone'))->startOfDay();
        $monthEnd = $monthStart->copy()->endOfMonth();

        $bookings = SessionBooking::query()
            ->with([
                'student.academicLevel',
                'student.activeEnrollment.batch.level',
                'student.currentLevelJourney.level',
                'student.levelJourneys.level',
                'attendanceIssues',
            ])
            ->where('teacher_id', $teacher->id)
            ->orderByDesc('starts_at')
            ->get();

        $leaves = TeacherLeave::query()
            ->where('teacher_id', $teacher->id)
            ->orderByDesc('date')
            ->orderByDesc('start_time')
            ->get();

        $ratings = MonthlyFeedback::query()
            ->with(['student.academicLevel', 'items'])
            ->where('master_teacher_id', $teacher->id)
            ->orderByDesc('session_date')
            ->orderByDesc('submitted_at')
            ->get();

        $introAttempts = $this->attemptMap($bookings, SessionBookingType::IntroductionCall);
        $masterAttempts = $this->masterAttemptMap($bookings);

        $activeBookings = $bookings->filter(
            fn (SessionBooking $booking) => $booking->status !== SessionBookingStatus::Cancelled,
        );
        $heldIntros = $activeBookings->filter(
            fn (SessionBooking $booking) => $booking->type === SessionBookingType::IntroductionCall && $this->wasHeld($booking),
        );
        $heldMasters = $activeBookings->filter(
            fn (SessionBooking $booking) => $booking->type === SessionBookingType::MasterClass && $this->wasHeld($booking),
        );
        $allIntros = $activeBookings->filter(fn (SessionBooking $booking) => $booking->type === SessionBookingType::IntroductionCall);
        $allMasters = $activeBookings->filter(fn (SessionBooking $booking) => $booking->type === SessionBookingType::MasterClass);

        $monthBookings = $activeBookings->filter(fn (SessionBooking $booking) => $this->inMonth($booking->date, $monthStart, $monthEnd));
        $monthLeaves = $leaves->filter(fn (TeacherLeave $leave) => $this->inMonth($leave->date, $monthStart, $monthEnd));
        $monthRatings = $ratings->filter(fn (MonthlyFeedback $rating) => $rating->year === $year && $rating->month === $month);
        $monthConflicts = $bookings
            ->filter(fn (SessionBooking $booking) => $this->inMonth($booking->date, $monthStart, $monthEnd) && $booking->attendanceIssues->isNotEmpty())
            ->count();

        $ratingAverage = MonthlyFeedbackItem::query()
            ->whereIn('monthly_feedback_id', $ratings->pluck('id'))
            ->avg('rating');

        $events = collect()
            ->concat($leaves->map(fn (TeacherLeave $leave) => $this->leaveEvent($leave)))
            ->concat($bookings->map(fn (SessionBooking $booking) => $this->bookingEvent(
                $booking,
                $introAttempts,
                $masterAttempts,
            )))
            ->concat($ratings->map(fn (MonthlyFeedback $rating) => $this->ratingEvent($rating)))
            ->filter()
            ->sortByDesc(fn (array $event) => $event['sort_at'])
            ->values()
            ->map(function (array $event): array {
                unset($event['sort_at']);

                return $event;
            })
            ->all();

        return [
            'teacher' => [
                'id' => $teacher->id,
                'full_name' => $teacher->full_name,
            ],
            'current_month' => [
                'year' => $year,
                'month' => $month,
            ],
            'this_month' => $this->countsFor(
                interviews: $monthBookings->filter(fn (SessionBooking $booking) => $booking->type === SessionBookingType::IntroductionCall)->count(),
                interviewsHeld: $monthBookings->filter(fn (SessionBooking $booking) => $booking->type === SessionBookingType::IntroductionCall && $this->wasHeld($booking))->count(),
                masterClasses: $monthBookings->filter(fn (SessionBooking $booking) => $booking->type === SessionBookingType::MasterClass)->count(),
                masterClassesHeld: $monthBookings->filter(fn (SessionBooking $booking) => $booking->type === SessionBookingType::MasterClass && $this->wasHeld($booking))->count(),
                leaveDays: $monthLeaves->unique(fn (TeacherLeave $leave) => $leave->date?->toDateString())->count(),
                ratingsSubmitted: $monthRatings->count(),
                conflictsReported: $monthConflicts,
                classesCancelled: $bookings
                    ->filter(fn (SessionBooking $booking) => $this->inMonth($booking->date, $monthStart, $monthEnd)
                        && $booking->status === SessionBookingStatus::Cancelled)
                    ->count(),
            ),
            'all_time' => $this->countsFor(
                interviews: $allIntros->count(),
                interviewsHeld: $heldIntros->count(),
                masterClasses: $allMasters->count(),
                masterClassesHeld: $heldMasters->count(),
                leaveDays: $leaves->unique(fn (TeacherLeave $leave) => $leave->date?->toDateString())->count(),
                ratingsSubmitted: $ratings->count(),
                conflictsReported: $bookings->filter(fn (SessionBooking $booking) => $booking->attendanceIssues->isNotEmpty())->count(),
                classesCancelled: $bookings->filter(fn (SessionBooking $booking) => $booking->status === SessionBookingStatus::Cancelled)->count(),
                ratingAverage: $ratingAverage === null ? null : round((float) $ratingAverage, 1),
            ),
            'by_month' => $this->byMonth($bookings, $leaves, $ratings, $year, $month),
            'events' => $events,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function countsFor(
        int $interviews,
        int $interviewsHeld,
        int $masterClasses,
        int $masterClassesHeld,
        int $leaveDays,
        int $ratingsSubmitted,
        int $conflictsReported,
        int $classesCancelled,
        ?float $ratingAverage = null,
    ): array {
        return [
            'interviews' => $interviews,
            'interviews_held' => $interviewsHeld,
            'master_classes' => $masterClasses,
            'master_classes_held' => $masterClassesHeld,
            'leave_days' => $leaveDays,
            'ratings_submitted' => $ratingsSubmitted,
            'conflicts_reported' => $conflictsReported,
            'classes_cancelled' => $classesCancelled,
            'rating_average' => $ratingAverage,
        ];
    }

    /**
     * @param  Collection<int, SessionBooking>  $bookings
     * @param  Collection<int, TeacherLeave>  $leaves
     * @param  Collection<int, MonthlyFeedback>  $ratings
     * @return list<array<string, mixed>>
     */
    private function byMonth(Collection $bookings, Collection $leaves, Collection $ratings, int $currentYear, int $currentMonth): array
    {
        $keys = collect();
        foreach ($bookings as $booking) {
            $key = $this->yearMonthKey($booking->date ?? $booking->starts_at);
            if ($key !== null) {
                $keys->push($key);
            }
        }
        foreach ($leaves as $leave) {
            $key = $this->yearMonthKey($leave->date);
            if ($key !== null) {
                $keys->push($key);
            }
        }
        foreach ($ratings as $rating) {
            $keys->push(sprintf('%04d-%02d', $rating->year, $rating->month));
        }
        $keys->push(sprintf('%04d-%02d', $currentYear, $currentMonth));

        return $keys
            ->unique()
            ->sortDesc()
            ->values()
            ->map(function (string $key) use ($bookings, $leaves, $ratings): array {
                [$year, $month] = array_map('intval', explode('-', $key));
                $monthStart = Carbon::create($year, $month, 1, 0, 0, 0, config('app.timezone'))->startOfDay();
                $monthEnd = $monthStart->copy()->endOfMonth();
                $monthBookings = $bookings->filter(
                    fn (SessionBooking $booking) => $booking->status !== SessionBookingStatus::Cancelled
                        && $this->inMonth($booking->date, $monthStart, $monthEnd),
                );

                return array_merge(
                    ['year' => $year, 'month' => $month],
                    $this->countsFor(
                        interviews: $monthBookings->filter(fn (SessionBooking $booking) => $booking->type === SessionBookingType::IntroductionCall)->count(),
                        interviewsHeld: $monthBookings->filter(fn (SessionBooking $booking) => $booking->type === SessionBookingType::IntroductionCall && $this->wasHeld($booking))->count(),
                        masterClasses: $monthBookings->filter(fn (SessionBooking $booking) => $booking->type === SessionBookingType::MasterClass)->count(),
                        masterClassesHeld: $monthBookings->filter(fn (SessionBooking $booking) => $booking->type === SessionBookingType::MasterClass && $this->wasHeld($booking))->count(),
                        leaveDays: $leaves
                            ->filter(fn (TeacherLeave $leave) => $this->inMonth($leave->date, $monthStart, $monthEnd))
                            ->unique(fn (TeacherLeave $leave) => $leave->date?->toDateString())
                            ->count(),
                        ratingsSubmitted: $ratings->filter(fn (MonthlyFeedback $rating) => $rating->year === $year && $rating->month === $month)->count(),
                        conflictsReported: $monthBookings->filter(fn (SessionBooking $booking) => $booking->attendanceIssues->isNotEmpty())->count(),
                        classesCancelled: $bookings
                            ->filter(fn (SessionBooking $booking) => $this->inMonth($booking->date, $monthStart, $monthEnd)
                                && $booking->status === SessionBookingStatus::Cancelled)
                            ->count(),
                    ),
                );
            })
            ->all();
    }

    private function wasHeld(SessionBooking $booking): bool
    {
        if ($booking->status === SessionBookingStatus::Cancelled) {
            return false;
        }

        return $booking->status === SessionBookingStatus::Completed
            || ($booking->ends_at !== null && $booking->ends_at->lte(AppClock::now()));
    }

    private function inMonth(mixed $date, Carbon $start, Carbon $end): bool
    {
        if ($date === null) {
            return false;
        }
        $value = Carbon::parse($date, config('app.timezone'));

        return $value->betweenIncluded($start, $end);
    }

    private function yearMonthKey(mixed $date): ?string
    {
        if ($date === null) {
            return null;
        }
        $value = Carbon::parse($date, config('app.timezone'));

        return $value->format('Y-m');
    }

    /**
     * @param  Collection<int, SessionBooking>  $bookings
     * @return array<string, int>
     */
    private function attemptMap(Collection $bookings, SessionBookingType $type): array
    {
        $map = [];
        $bookings
            ->filter(fn (SessionBooking $booking) => $booking->type === $type && $booking->status !== SessionBookingStatus::Cancelled)
            ->groupBy('student_id')
            ->each(function (Collection $items) use (&$map): void {
                $items->sortBy(fn (SessionBooking $booking) => $booking->starts_at?->timestamp ?? 0)
                    ->values()
                    ->each(function (SessionBooking $booking, int $index) use (&$map): void {
                        $map[$booking->id] = $index + 1;
                    });
            });

        return $map;
    }

    /**
     * @param  Collection<int, SessionBooking>  $bookings
     * @return array<string, int>
     */
    private function masterAttemptMap(Collection $bookings): array
    {
        $map = [];
        $bookings
            ->filter(fn (SessionBooking $booking) => $booking->type === SessionBookingType::MasterClass && $booking->status !== SessionBookingStatus::Cancelled)
            ->groupBy(function (SessionBooking $booking): string {
                $local = $booking->starts_at?->timezone(config('app.timezone'));

                return $booking->student_id.'|'.($local?->format('Y-m') ?? 'unknown');
            })
            ->each(function (Collection $items) use (&$map): void {
                $items->sortBy(fn (SessionBooking $booking) => $booking->starts_at?->timestamp ?? 0)
                    ->values()
                    ->each(function (SessionBooking $booking, int $index) use (&$map): void {
                        $map[$booking->id] = $index + 1;
                    });
            });

        return $map;
    }

    /**
     * @return array<string, mixed>
     */
    private function leaveEvent(TeacherLeave $leave): array
    {
        $when = $leave->is_full_day
            ? 'Full day'
            : substr((string) $leave->start_time, 0, 5).'–'.substr((string) $leave->end_time, 0, 5);
        $reason = filled($leave->reason) ? $leave->reason : 'Leave';
        $facts = [
            $this->fact('Duration', $when),
            $this->fact('Reason', $reason),
        ];

        return $this->event(
            id: 'leave-'.$leave->id,
            kind: 'leave',
            date: $leave->date?->toDateString(),
            time: $leave->is_full_day ? null : substr((string) $leave->start_time, 0, 5),
            endTime: $leave->is_full_day ? null : substr((string) $leave->end_time, 0, 5),
            title: 'Leave',
            status: 'leave',
            tags: [
                $this->tag('Leave', 'muted'),
                $this->tag($leave->is_full_day ? 'Full day' : 'Partial', 'muted'),
            ],
            facts: $facts,
            sortAt: ($leave->date?->toDateString() ?? '1970-01-01').' '.($leave->is_full_day ? '00:00' : substr((string) $leave->start_time, 0, 5)),
        );
    }

    /**
     * @param  array<string, int>  $introAttempts
     * @param  array<string, int>  $masterAttempts
     * @return array<string, mixed>
     */
    private function bookingEvent(SessionBooking $booking, array $introAttempts, array $masterAttempts): array
    {
        $isMaster = $booking->type === SessionBookingType::MasterClass;
        $status = $booking->status?->value ?? (string) $booking->status;
        $held = $this->wasHeld($booking);
        $statusLabel = $this->bookingStatusLabel($status, $held);
        $student = $booking->student;
        $level = $this->levelName($booking);
        $week = $isMaster ? $this->learningWeek($booking) : null;
        $attempt = $isMaster ? ($masterAttempts[$booking->id] ?? null) : ($introAttempts[$booking->id] ?? null);
        $attemptMax = $isMaster || $booking->type === SessionBookingType::IntroductionCall ? 2 : null;
        $conflict = $booking->attendanceIssues->sortByDesc('created_at')->first();
        $conflictStatus = $conflict?->verification_status?->value;
        $decision = $conflict?->admin_decision?->value;
        $tz = config('app.timezone');
        $start = $booking->starts_at?->timezone($tz)->format('H:i');
        $end = $booking->ends_at?->timezone($tz)->format('H:i');

        $tags = [
            $this->tag($isMaster ? 'Master class' : 'Interview', $isMaster ? 'success' : 'info'),
            $this->tag($statusLabel, $status === SessionBookingStatus::Cancelled->value ? 'danger' : 'muted'),
        ];
        if ($level !== null) {
            $tags[] = $this->tag($level, 'muted');
        }
        if ($week !== null) {
            $tags[] = $this->tag('Week '.$week, 'muted');
        }
        if ($attempt !== null) {
            $tags[] = $this->tag('Attempt '.$attempt.($attemptMax ? ' of '.$attemptMax : ''), 'muted');
        }
        if ($conflictStatus !== null) {
            $resolved = $conflictStatus === AttendanceVerificationStatus::Resolved->value;
            $conflictLabel = $resolved ? 'Conflict · Resolved' : 'Conflict · Pending';
            if ($decision === 'extra_chance') {
                $conflictLabel = 'Conflict · Extra chance';
            }
            $tags[] = $this->tag($conflictLabel, $resolved ? 'success' : 'danger');
        }

        $facts = array_values(array_filter([
            $this->fact('Student code', $student?->student_code),
            $this->fact('Class', $student?->class_grade !== null ? 'Class '.$student->class_grade : null),
        ]));

        return $this->event(
            id: 'booking-'.$booking->id,
            kind: $isMaster ? 'master_class' : 'introduction_call',
            date: $booking->date?->toDateString(),
            time: $start,
            endTime: $end,
            title: $isMaster ? SessionBookingType::MasterClass->label() : SessionBookingType::IntroductionCall->label(),
            status: $held && $status !== SessionBookingStatus::Cancelled->value ? 'completed' : $status,
            tags: $tags,
            facts: $facts,
            studentId: $booking->student_id,
            studentName: $student?->full_name,
            studentCode: $student?->student_code,
            levelName: $level,
            learningWeek: $week,
            attemptNumber: $attempt,
            attemptMax: $attemptMax,
            conflictStatus: $conflictStatus,
            conflictId: $conflict?->id,
            sortAt: $booking->starts_at?->timezone($tz)->toDateTimeString()
                ?? ($booking->date?->toDateString() ?? '1970-01-01').' 00:00:00',
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function ratingEvent(MonthlyFeedback $rating): array
    {
        $date = $rating->session_date?->toDateString()
            ?? sprintf('%04d-%02d-01', $rating->year, $rating->month);
        $avg = $rating->items->avg('rating');
        $monthLabel = Carbon::create($rating->year, $rating->month, 1)->format('F Y');
        $level = $rating->student?->academicLevel?->name;
        $facts = array_values(array_filter([
            $this->fact('Student', $rating->student?->full_name),
            $this->fact('Student code', $rating->student?->student_code),
            $this->fact('Level', $level),
            $this->fact('Rating month', $monthLabel),
            $this->fact('Average', $avg === null ? null : number_format((float) $avg, 1)),
            $this->fact('Items rated', (string) $rating->items->count()),
            $this->fact('Session date', $rating->session_date?->toDateString()),
        ]));
        $tags = array_values(array_filter([
            $this->tag('Rating', 'warning'),
            $this->tag($monthLabel, 'muted'),
            $avg === null ? null : $this->tag('Avg '.number_format((float) $avg, 1), 'warning'),
            $level === null ? null : $this->tag($level, 'muted'),
        ]));

        return $this->event(
            id: 'rating-'.$rating->id,
            kind: 'rating',
            date: $date,
            time: $rating->submitted_at?->timezone(config('app.timezone'))->format('H:i'),
            title: 'Monthly rating',
            status: 'submitted',
            tags: $tags,
            facts: $facts,
            studentId: $rating->student_id,
            studentName: $rating->student?->full_name,
            studentCode: $rating->student?->student_code,
            levelName: $level,
            sortAt: ($rating->submitted_at ?? $rating->session_date)?->timezone(config('app.timezone'))->toDateTimeString()
                ?? $date.' 12:00:00',
        );
    }

    private function learningWeek(SessionBooking $booking): ?int
    {
        $student = $booking->student;
        $at = $booking->starts_at;
        if ($student === null || $at === null) {
            return null;
        }

        $journeys = $student->relationLoaded('levelJourneys') ? $student->levelJourneys : collect();
        /** @var StudentLevelJourney|null $journey */
        $journey = $journeys->first(function (StudentLevelJourney $item) use ($at): bool {
            $started = $item->started_at;
            if ($started === null || $started->gt($at)) {
                return false;
            }

            return $item->ended_at === null || $item->ended_at->gte($at);
        }) ?? $student->currentLevelJourney;

        return $journey?->weekNumberAt($at);
    }

    private function levelName(SessionBooking $booking): ?string
    {
        $student = $booking->student;
        if ($student === null) {
            return null;
        }
        $at = $booking->starts_at;
        $journeys = $student->relationLoaded('levelJourneys') ? $student->levelJourneys : collect();
        $journey = $at === null ? $student->currentLevelJourney : $journeys->first(function (StudentLevelJourney $item) use ($at): bool {
            $started = $item->started_at;
            if ($started === null || $started->gt($at)) {
                return false;
            }

            return $item->ended_at === null || $item->ended_at->gte($at);
        });

        return $journey?->level?->name
            ?? $student->academicLevel?->name
            ?? $student->activeEnrollment?->batch?->level?->name;
    }

    /**
     * @param  list<array{label: string, tone: string}>  $tags
     * @param  list<array{label: string, value: string}>  $facts
     * @return array<string, mixed>
     */
    private function event(
        string $id,
        string $kind,
        ?string $date,
        string $title,
        string $status,
        array $tags,
        array $facts,
        string $sortAt,
        ?string $time = null,
        ?string $endTime = null,
        ?string $studentId = null,
        ?string $studentName = null,
        ?string $studentCode = null,
        ?string $levelName = null,
        ?int $learningWeek = null,
        ?int $attemptNumber = null,
        ?int $attemptMax = null,
        ?string $conflictStatus = null,
        ?string $conflictId = null,
    ): array {
        $detail = collect($facts)->map(fn (array $fact) => $fact['label'].': '.$fact['value'])->implode(' · ');

        return [
            'id' => $id,
            'kind' => $kind,
            'date' => $date,
            'time' => $time,
            'end_time' => $endTime,
            'title' => $title,
            'detail' => $detail,
            'status' => $status,
            'tags' => $tags,
            'facts' => $facts,
            'student_id' => $studentId,
            'student_name' => $studentName,
            'student_code' => $studentCode,
            'level_name' => $levelName,
            'learning_week' => $learningWeek,
            'attempt_number' => $attemptNumber,
            'attempt_max' => $attemptMax,
            'conflict_status' => $conflictStatus,
            'conflict_id' => $conflictId,
            'sort_at' => $sortAt,
        ];
    }

    /**
     * @return array{label: string, tone: string}
     */
    private function tag(string $label, string $tone): array
    {
        return ['label' => $label, 'tone' => $tone];
    }

    /**
     * @return array{label: string, value: string}|null
     */
    private function fact(string $label, ?string $value): ?array
    {
        if (! filled($value)) {
            return null;
        }

        return ['label' => $label, 'value' => $value];
    }

    private function bookingStatusLabel(string $status, bool $held): string
    {
        if ($status === SessionBookingStatus::Cancelled->value) {
            return 'Cancelled';
        }
        if ($held || $status === SessionBookingStatus::Completed->value) {
            return 'Completed';
        }

        return 'Scheduled';
    }

    private function decisionLabel(?string $decision): ?string
    {
        return match ($decision) {
            'resolved' => 'Resolved',
            'extra_chance' => 'Extra chance',
            'student_attended' => 'Student attended',
            'teacher_attended' => 'Teacher attended',
            'both_attended' => 'Both attended',
            'student_absent' => 'Student absent',
            'teacher_absent' => 'Teacher absent',
            'technical_issue' => 'Technical issue',
            'both_absent' => 'Both absent',
            'no_conclusion' => 'No conclusion',
            default => null,
        };
    }
}
