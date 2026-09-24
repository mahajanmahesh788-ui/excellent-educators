<?php

namespace App\Scheduling;

use App\Attendance\AttendanceService;
use App\Enums\ScheduleSlotStatus;
use App\Enums\SessionBookingStatus;
use App\Enums\TeacherBreakType;
use App\Enums\TeacherLeaveStatus;
use App\Models\SessionBooking;
use App\Models\TeacherBreak;
use App\Models\TeacherDailyMeeting;
use App\Models\TeacherLeave;
use App\Models\TeacherProfile;
use App\Models\TeacherWeeklyOff;
use App\Support\AppClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class AvailabilityCalculator
{
    public function __construct(
        private readonly AttendanceService $attendance,
        private readonly TeacherAvailability $teacherAvailability,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function day(
        TeacherProfile $teacher,
        string $date,
        ?string $ignoreBookingId = null,
        bool $bookableOnly = false,
        string $viewer = 'teacher',
    ): array {
        $source = $this->teacherAvailability->sourceForDate($teacher, $date);
        $ranges = $source['ranges'];
        $outsideStatus = $source['source'] === 'weekly_off'
            ? ScheduleSlotStatus::WeeklyOff->value
            : ScheduleSlotStatus::Unavailable->value;

        $starts = SlotGrid::starts();
        foreach ($ranges as $range) {
            $starts = array_merge($starts, SlotGrid::alignedStartsBetween($range['start'], $range['end']));
        }
        $starts = array_values(array_unique($starts));
        sort($starts);

        $slots = [];
        foreach ($starts as $start) {
            $inside = false;
            foreach ($ranges as $range) {
                if (SlotGrid::slotFitsRange($start, $range['start'], $range['end'])) {
                    $inside = true;
                    break;
                }
            }
            $slots[$start] = [
                'start' => $start,
                'end' => SlotGrid::endFor($start),
                'status' => $inside ? ScheduleSlotStatus::Available->value : $outsideStatus,
                'booking_id' => null,
                'student_name' => null,
                'booking_type' => null,
            ];
        }

        if ($source['source'] === 'default') {
            $weekday = SlotGrid::atDate($date, SlotGrid::dayStart())->dayOfWeek;
            $hasWeeklyOff = TeacherWeeklyOff::query()
                ->where('teacher_id', $teacher->id)
                ->where('weekday', $weekday)
                ->exists();
            if ($hasWeeklyOff) {
                foreach ($slots as $start => $slot) {
                    $slots[$start]['status'] = ScheduleSlotStatus::WeeklyOff->value;
                }
            }
        }

        $breaks = TeacherBreak::query()
            ->where('teacher_id', $teacher->id)
            ->get();

        foreach ($breaks as $break) {
            $status = $break->type === TeacherBreakType::Lunch
                ? ScheduleSlotStatus::Lunch
                : ScheduleSlotStatus::Breakfast;
            foreach ($this->overlappingStarts($slots, $this->hm($break->start_time), $this->hm($break->end_time)) as $start) {
                if (($slots[$start]['status'] ?? null) === ScheduleSlotStatus::Available->value) {
                    $slots[$start]['status'] = $status->value;
                }
            }
        }

        $leaves = TeacherLeave::query()
            ->where('teacher_id', $teacher->id)
            ->whereDate('date', $date)
            ->whereNotIn('status', [
                TeacherLeaveStatus::Rejected->value,
                TeacherLeaveStatus::Cancelled->value,
            ])
            ->get();

        $approvedLeaves = $leaves->filter(
            fn (TeacherLeave $leave) => $leave->status === TeacherLeaveStatus::Approved,
        );
        $holdLeaves = $leaves->filter(
            fn (TeacherLeave $leave) => in_array(
                $leave->status?->value,
                TeacherLeaveStatus::bookingHoldValues(),
                true,
            ),
        );

        foreach ($approvedLeaves as $leave) {
            foreach ($this->overlappingStarts($slots, $this->hm($leave->start_time), $this->hm($leave->end_time)) as $start) {
                if (($slots[$start]['status'] ?? null) === ScheduleSlotStatus::Available->value
                    || in_array($slots[$start]['status'], [
                        ScheduleSlotStatus::Breakfast->value,
                        ScheduleSlotStatus::Lunch->value,
                    ], true)) {
                    $slots[$start]['status'] = ScheduleSlotStatus::Leave->value;
                    $slots[$start]['leave_id'] = $leave->id;
                }
            }
        }

        $holdStarts = [];
        foreach ($holdLeaves as $leave) {
            foreach ($this->overlappingStarts($slots, $this->hm($leave->start_time), $this->hm($leave->end_time)) as $start) {
                $holdStarts[$start] = true;
            }
        }

        $bookings = SessionBooking::query()
            ->with('student')
            ->where('teacher_id', $teacher->id)
            ->whereDate('date', $date)
            ->where('status', '!=', SessionBookingStatus::Cancelled->value)
            ->when($ignoreBookingId, fn ($q) => $q->where('id', '!=', $ignoreBookingId))
            ->get();

        foreach ($bookings as $booking) {
            $startHm = SlotGrid::hmFrom($booking->starts_at);
            $endHm = SlotGrid::hmFrom($booking->ends_at);
            foreach ($this->overlappingStarts($slots, $startHm, $endHm) as $start) {
                $slots[$start]['status'] = ScheduleSlotStatus::Booked->value;
                $slots[$start]['booking_id'] = $booking->id;
                $slots[$start]['student_name'] = $booking->student?->full_name;
                $slots[$start]['booking_type'] = $booking->type?->value ?? $booking->type;
            }
        }

        $now = AppClock::now();
        $isToday = $date === $now->toDateString();
        $nowMinutes = ($now->hour * 60) + $now->minute;

        $list = array_values($slots);
        if ($bookableOnly) {
            $list = array_values(array_filter($list, function (array $slot) use ($isToday, $nowMinutes, $holdStarts): bool {
                if ($slot['status'] !== ScheduleSlotStatus::Available->value) {
                    return false;
                }
                if (isset($holdStarts[$slot['start']])) {
                    return false;
                }
                if ($isToday && SlotGrid::parseHm($slot['start']) <= $nowMinutes) {
                    return false;
                }

                return true;
            }));
        }

        return [
            'date' => $date,
            'day_start' => SlotGrid::dayStart(),
            'day_end' => SlotGrid::dayEnd(),
            'slot_minutes' => SlotGrid::slotMinutes(),
            'availability_source' => $source['source'],
            'availability_ranges' => $ranges,
            'slots' => $list,
            'breaks' => $breaks->map(fn (TeacherBreak $break) => [
                'id' => $break->id,
                'type' => $break->type?->value ?? $break->type,
                'start_time' => $this->hm($break->start_time),
                'end_time' => $this->hm($break->end_time),
            ])->values()->all(),
            'leaves' => $leaves->map(fn (TeacherLeave $leave) => $leave->toScheduleArray())->values()->all(),
            'bookings' => $bookings->map(fn (SessionBooking $booking) => $this->bookingPayload($booking, $viewer))->values()->all(),
        ];
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function week(TeacherProfile $teacher, string $startDate): array
    {
        $days = [];
        $cursor = SlotGrid::atDate($startDate, SlotGrid::dayStart());
        for ($i = 0; $i < 7; $i++) {
            $days[] = $this->day($teacher, $cursor->copy()->addDays($i)->toDateString());
        }

        return $days;
    }

    /**
     * @return array<string, mixed>
     */
    public function month(TeacherProfile $teacher, int $year, int $month): array
    {
        $start = SlotGrid::atDate(sprintf('%04d-%02d-01', $year, $month), SlotGrid::dayStart());
        $daysInMonth = $start->daysInMonth;
        $days = [];
        for ($day = 1; $day <= $daysInMonth; $day++) {
            $date = sprintf('%04d-%02d-%02d', $year, $month, $day);
            $snapshot = $this->day($teacher, $date);
            $counts = Collection::make($snapshot['slots'])->countBy('status');
            $days[] = [
                'date' => $date,
                'available' => (int) ($counts[ScheduleSlotStatus::Available->value] ?? 0),
                'booked' => (int) ($counts[ScheduleSlotStatus::Booked->value] ?? 0),
                'leave' => (int) ($counts[ScheduleSlotStatus::Leave->value] ?? 0),
                'breakfast' => (int) ($counts[ScheduleSlotStatus::Breakfast->value] ?? 0),
                'lunch' => (int) ($counts[ScheduleSlotStatus::Lunch->value] ?? 0),
                'unavailable' => (int) ($counts[ScheduleSlotStatus::Unavailable->value] ?? 0),
                'weekly_off' => (int) ($counts[ScheduleSlotStatus::WeeklyOff->value] ?? 0),
                'has_full_day_leave' => collect($snapshot['leaves'])->contains(fn ($leave) => $leave['is_full_day'] === true),
            ];
        }

        return [
            'year' => $year,
            'month' => $month,
            'days' => $days,
        ];
    }

    public function isSlotAvailable(
        TeacherProfile $teacher,
        string $date,
        string $start,
        ?string $ignoreBookingId = null,
    ): bool {
        $day = $this->day($teacher, $date, $ignoreBookingId);
        foreach ($day['slots'] as $slot) {
            if ($slot['start'] === $start) {
                if ($slot['status'] !== ScheduleSlotStatus::Available->value) {
                    return false;
                }

                return ! $this->hasBookingHold($teacher, $date, $start);
            }
        }

        return false;
    }

    public function hasBookingHold(TeacherProfile $teacher, string $date, string $start): bool
    {
        $startM = SlotGrid::parseHm($start);
        $endM = $startM + SlotGrid::slotMinutes();

        $holds = TeacherLeave::query()
            ->where('teacher_id', $teacher->id)
            ->whereDate('date', $date)
            ->whereIn('status', TeacherLeaveStatus::bookingHoldValues())
            ->get();

        foreach ($holds as $leave) {
            $from = SlotGrid::parseHm($this->hm($leave->start_time));
            $to = SlotGrid::parseHm($this->hm($leave->end_time));
            if ($startM < $to && $from < $endM) {
                return true;
            }
        }

        return false;
    }

    /**
     * @param  list<string>  $starts
     */
    public function overlapsBookings(TeacherProfile $teacher, string $date, array $starts, ?string $ignoreBookingId = null): bool
    {
        $day = $this->day($teacher, $date, $ignoreBookingId);
        $wanted = array_flip($starts);
        foreach ($day['slots'] as $slot) {
            if (isset($wanted[$slot['start']]) && $slot['status'] === ScheduleSlotStatus::Booked->value) {
                return true;
            }
        }

        return false;
    }

    /**
     * @return array<string, mixed>
     */
    public function bookingPayload(SessionBooking $booking, string $viewer = 'student'): array
    {
        $booking->loadMissing(['student.currentLevelJourney', 'teacher', 'reassignedFromTeacher']);
        $eligibility = app(BookingEligibility::class);
        $type = $booking->type?->value ?? $booking->type;
        $attempt = $eligibility->attemptNumber($booking);
        $week = $type === 'master_class' ? $eligibility->learningWeekFor($booking) : null;

        return [
            'id' => $booking->id,
            'student_id' => $booking->student_id,
            'teacher_id' => $booking->teacher_id,
            'student_name' => $booking->student?->full_name,
            'teacher_name' => $booking->teacher?->full_name,
            'type' => $type,
            'date' => $booking->date?->toDateString() ?? SlotGrid::dateFrom($booking->starts_at),
            'start' => SlotGrid::hmFrom($booking->starts_at),
            'end' => SlotGrid::hmFrom($booking->ends_at),
            'starts_at' => $booking->starts_at?->timezone(config('app.timezone'))->toIso8601String(),
            'ends_at' => $booking->ends_at?->timezone(config('app.timezone'))->toIso8601String(),
            'status' => $booking->status?->value ?? $booking->status,
            'attempt_number' => $attempt,
            'learning_week' => $week,
            'meeting_url' => TeacherDailyMeeting::query()
                ->where('teacher_id', $booking->teacher_id)
                ->whereDate('date', $booking->date?->toDateString() ?? SlotGrid::dateFrom($booking->starts_at))
                ->value('meet_url'),
            'attendance' => $this->attendance->payloadFor($booking, $viewer),
            'was_reassigned' => $booking->reassigned_at !== null,
            'reassigned_at' => $booking->reassigned_at?->toIso8601String(),
            'previous_teacher_name' => $booking->reassignedFromTeacher?->full_name,
        ];
    }

    private function hm(mixed $time): string
    {
        if ($time instanceof \DateTimeInterface) {
            return Carbon::instance(\DateTime::createFromInterface($time))->format('H:i');
        }

        $value = (string) $time;
        if (preg_match('/^(\d{2}:\d{2})/', $value, $matches) === 1) {
            return $matches[1];
        }

        return $value;
    }

    /**
     * @param  array<string, array<string, mixed>>  $slots
     * @return list<string>
     */
    private function overlappingStarts(array $slots, string $from, string $to): array
    {
        $fromM = SlotGrid::parseHm($from);
        $toM = SlotGrid::parseHm($to);
        $hit = [];
        foreach (array_keys($slots) as $start) {
            $slotFrom = SlotGrid::parseHm($start);
            $slotTo = $slotFrom + SlotGrid::slotMinutes();
            if ($slotFrom < $toM && $fromM < $slotTo) {
                $hit[] = $start;
            }
        }

        return $hit;
    }
}
