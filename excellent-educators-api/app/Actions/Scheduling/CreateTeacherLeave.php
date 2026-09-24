<?php

namespace App\Actions\Scheduling;

use App\Actions\Notifications\NotifyAdminsOfTeacherLeaveSubmitted;
use App\Enums\TeacherLeaveStatus;
use App\Exceptions\ApiException;
use App\Models\TeacherLeave;
use App\Models\TeacherLeaveReassignment;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Scheduling\FindBookingsAffectedByLeave;
use App\Scheduling\SlotGrid;
use App\Scheduling\TeacherAvailability;
use App\Support\AppClock;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CreateTeacherLeave
{
    public function __construct(
        private readonly TeacherAvailability $teacherAvailability,
        private readonly FindBookingsAffectedByLeave $findAffected,
        private readonly NotifyAdminsOfTeacherLeaveSubmitted $notifyAdmins,
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

        $ranges = $isFullDay
            ? $this->workingRanges($teacher, $date)
            : $this->collapse($starts);

        $this->assertNoOverlappingLeave($teacher, $date, $ranges);

        $affected = $this->findAffected->forStarts($teacher, $date, $starts);
        $status = $affected->isEmpty()
            ? TeacherLeaveStatus::Pending
            : TeacherLeaveStatus::ReassignmentPending;
        $groupId = (string) Str::ulid();

        $created = DB::transaction(function () use (
            $teacher,
            $date,
            $isFullDay,
            $reason,
            $ranges,
            $actor,
            $status,
            $groupId,
            $affected,
        ) {
            $created = collect();
            foreach ($ranges as [$start, $end]) {
                $created->push(TeacherLeave::query()->create([
                    'request_group_id' => $groupId,
                    'teacher_id' => $teacher->id,
                    'date' => $date,
                    'start_time' => $start.':00',
                    'end_time' => $end.':00',
                    'is_full_day' => $isFullDay,
                    'reason' => $reason,
                    'status' => $status,
                    'created_by' => $actor?->id,
                ]));
            }

            foreach ($affected as $booking) {
                TeacherLeaveReassignment::query()->create([
                    'leave_request_group_id' => $groupId,
                    'booking_id' => $booking->id,
                    'replacement_teacher_id' => null,
                    'assigned_by' => null,
                    'assigned_at' => null,
                ]);
            }

            return $created;
        });

        $this->notifyAdmins->execute($teacher, $groupId, $date, $status);

        return $created;
    }

    /**
     * @param  list<array{0: string, 1: string}>  $ranges
     */
    private function assertNoOverlappingLeave(TeacherProfile $teacher, string $date, array $ranges): void
    {
        $existing = TeacherLeave::query()
            ->where('teacher_id', $teacher->id)
            ->whereDate('date', $date)
            ->whereIn('status', TeacherLeaveStatus::activeValues())
            ->get();

        foreach ($existing as $leave) {
            $leaveStart = SlotGrid::parseHm(substr((string) $leave->start_time, 0, 5));
            $leaveEnd = SlotGrid::parseHm(substr((string) $leave->end_time, 0, 5));
            foreach ($ranges as [$start, $end]) {
                $from = SlotGrid::parseHm($start);
                $to = SlotGrid::parseHm($end);
                if ($from < $leaveEnd && $leaveStart < $to) {
                    throw new ApiException(
                        ErrorCode::LEAVE_OVERLAPS_LEAVE,
                        'This leave overlaps an existing leave request for the same period.',
                        422,
                    );
                }
            }
        }
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
