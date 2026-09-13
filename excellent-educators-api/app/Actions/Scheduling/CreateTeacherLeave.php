<?php

namespace App\Actions\Scheduling;

use App\Exceptions\ApiException;
use App\Models\TeacherLeave;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Scheduling\AvailabilityCalculator;
use App\Scheduling\SlotGrid;
use App\Scheduling\TeacherAvailability;
use App\Support\AppClock;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class CreateTeacherLeave
{
    public function __construct(
        private readonly AvailabilityCalculator $availability,
        private readonly TeacherAvailability $teacherAvailability,
    ) {}

    /**
     * @param  array<string, mixed>  $payload
     * @return \Illuminate\Support\Collection<int, TeacherLeave>
     */
    public function execute(TeacherProfile $teacher, array $payload, ?User $actor = null)
    {
        $date = (string) $payload['date'];
        $isFullDay = (bool) ($payload['is_full_day'] ?? false);
        $reason = trim((string) ($payload['reason'] ?? ''));
        $starts = $this->resolveStarts($teacher, $payload, $isFullDay, $date);

        if ($date < AppClock::todayString()) {
            throw new ApiException(ErrorCode::LEAVE_DATE_PASSED, 'Leave cannot be taken for a past date.', 422);
        }

        if ($reason === '') {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Leave reason is required.', 422);
        }

        if ($starts === []) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Select at least one leave slot.', 422);
        }

        if ($this->availability->overlapsBookings($teacher, $date, $starts)) {
            throw new ApiException(
                ErrorCode::LEAVE_OVERLAPS_BOOKING,
                'This leave period overlaps with an existing booking. Please choose another time.',
                422,
            );
        }

        $ranges = $isFullDay
            ? $this->workingRanges($teacher, $date)
            : $this->collapse($starts);

        return DB::transaction(function () use ($teacher, $date, $isFullDay, $reason, $ranges, $actor) {
            $created = collect();
            foreach ($ranges as [$start, $end]) {
                $created->push(TeacherLeave::query()->create([
                    'teacher_id' => $teacher->id,
                    'date' => $date,
                    'start_time' => $start.':00',
                    'end_time' => $end.':00',
                    'is_full_day' => $isFullDay,
                    'reason' => $reason,
                    'created_by' => $actor?->id,
                ]));
            }

            return $created;
        });
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return list<string>
     */
    private function resolveStarts(TeacherProfile $teacher, array $payload, bool $isFullDay, string $date): array
    {
        if ($isFullDay) {
            $starts = [];
            foreach ($this->workingRanges($teacher, $date) as [$start, $end]) {
                $starts = array_merge($starts, SlotGrid::alignedStartsBetween($start, $end));
            }

            return array_values(array_unique($starts));
        }

        if (! empty($payload['start_time']) && ! empty($payload['end_time'])) {
            $start = (string) $payload['start_time'];
            $end = (string) $payload['end_time'];
            if (! SlotGrid::isAligned($start) || ! SlotGrid::isAligned($end) || ! SlotGrid::isWithinDay($start, $end)) {
                throw new ApiException(
                    ErrorCode::VALIDATION_ERROR,
                    'Leave time must be 30-minute slots between '.SlotGrid::dayStart().' and '.SlotGrid::dayEnd().'.',
                    422,
                );
            }

            return SlotGrid::startsCovering($start, $end);
        }

        $starts = array_values(array_unique(array_map('strval', $payload['slot_starts'] ?? [])));
        foreach ($starts as $start) {
            if (! in_array($start, SlotGrid::starts(), true)) {
                throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Invalid leave slot.', 422);
            }
        }

        return $starts;
    }

    /**
     * @param  list<string>  $starts
     * @return list<array{0: string, 1: string}>
     */
    private function collapse(array $starts): array
    {
        sort($starts);
        $ranges = [];
        $rangeStart = null;
        $expected = null;
        foreach ($starts as $start) {
            if ($rangeStart === null) {
                $rangeStart = $start;
                $expected = SlotGrid::endFor($start);
                continue;
            }
            if ($start === $expected) {
                $expected = SlotGrid::endFor($start);
                continue;
            }
            $ranges[] = [$rangeStart, $expected];
            $rangeStart = $start;
            $expected = SlotGrid::endFor($start);
        }
        if ($rangeStart !== null) {
            $ranges[] = [$rangeStart, $expected];
        }

        return $ranges;
    }

    /**
     * @return list<array{0: string, 1: string}>
     */
    private function workingRanges(TeacherProfile $teacher, string $date): array
    {
        $ranges = $this->teacherAvailability->rangesForDate($teacher, $date);
        if ($ranges === []) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'No working hours on this date to take leave.', 422);
        }

        return array_map(
            static fn (array $range): array => [$range['start'], $range['end']],
            $ranges,
        );
    }
}
