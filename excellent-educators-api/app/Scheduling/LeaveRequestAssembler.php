<?php

namespace App\Scheduling;

use App\Enums\TeacherLeaveStatus;
use App\Models\SessionBooking;
use App\Models\TeacherLeave;
use App\Models\TeacherLeaveReassignment;
use Illuminate\Support\Collection;

class LeaveRequestAssembler
{
    public function __construct(
        private readonly FindBookingsAffectedByLeave $findAffected,
        private readonly FindReplacementTeachersForBooking $findReplacements,
    ) {}

    /**
     * @return Collection<int, TeacherLeave>
     */
    public function leavesForGroup(string $groupId): Collection
    {
        return TeacherLeave::query()
            ->with(['teacher.user', 'teacher.academicLevels'])
            ->where('request_group_id', $groupId)
            ->orderBy('start_time')
            ->get();
    }

    /**
     * @param  Collection<int, TeacherLeave>  $leaves
     * @return array<string, mixed>
     */
    public function serializeGroup(Collection $leaves, bool $includeReplacementsAvailability = false): array
    {
        /** @var TeacherLeave $primary */
        $primary = $leaves->first();
        $teacher = $primary->teacher;
        $teacher?->loadMissing(['user', 'academicLevels']);
        $groupId = (string) $primary->request_group_id;
        $affected = $this->findAffected->execute($leaves);
        $reassignments = TeacherLeaveReassignment::query()
            ->with('replacementTeacher')
            ->where('leave_request_group_id', $groupId)
            ->get()
            ->keyBy('booking_id');

        $affectedPayload = $affected->map(function (SessionBooking $booking) use (
            $reassignments,
            $includeReplacementsAvailability,
            $teacher,
        ) {
            $draft = $reassignments->get($booking->id);
            $replacementId = $draft?->replacement_teacher_id;

            $availableReplacements = [];
            if ($includeReplacementsAvailability) {
                $availableReplacements = $this->findReplacements
                    ->execute($booking, $teacher?->id)
                    ->map(fn ($candidate) => [
                        'id' => $candidate->id,
                        'full_name' => $candidate->full_name,
                        'photo_url' => $candidate->photo_url,
                        'phone' => $candidate->phone,
                        'whatsapp_number' => $candidate->whatsapp_number,
                    ])
                    ->values()
                    ->all();
            }

            $assignmentStatus = 'unassigned';
            if ($replacementId !== null) {
                $assignmentStatus = 'assigned';
            } elseif ($includeReplacementsAvailability && $availableReplacements === []) {
                $assignmentStatus = 'no_available';
            }

            return [
                'booking_id' => $booking->id,
                'date' => $booking->date?->toDateString(),
                'start' => SlotGrid::hmFrom($booking->starts_at),
                'end' => SlotGrid::hmFrom($booking->ends_at),
                'student_id' => $booking->student_id,
                'student_name' => $booking->student?->full_name,
                'session_type' => $booking->type?->value ?? $booking->type,
                'session_type_label' => $booking->type?->label() ?? (string) $booking->type,
                'current_teacher_id' => $booking->teacher_id,
                'current_teacher_name' => $booking->teacher?->full_name ?? $teacher?->full_name,
                'booking_status' => $booking->status?->value ?? $booking->status,
                'replacement_teacher_id' => $replacementId,
                'replacement_teacher_name' => $draft?->replacementTeacher?->full_name,
                'assignment_status' => $assignmentStatus,
                'available_replacements' => $availableReplacements,
            ];
        })->values()->all();

        $reassignedCount = collect($affectedPayload)
            ->where('assignment_status', 'assigned')
            ->count();

        $levels = $teacher?->academicLevels
            ?->map(fn ($level) => [
                'id' => $level->id,
                'name' => $level->name,
            ])
            ->values()
            ->all() ?? [];

        return [
            'request_group_id' => $groupId,
            'teacher_id' => $primary->teacher_id,
            'teacher_name' => $teacher?->full_name,
            'teacher_photo_url' => $teacher?->photo_url ?? null,
            'teacher_phone' => $teacher?->phone,
            'teacher_whatsapp' => $teacher?->whatsapp_number,
            'teacher_email' => $teacher?->user?->email,
            'teacher_status' => $teacher?->status?->value ?? $teacher?->status,
            'teacher_work_type' => $teacher?->work_type?->value ?? $teacher?->work_type,
            'teacher_levels' => $levels,
            'date' => $primary->date?->toDateString(),
            'is_full_day' => (bool) $primary->is_full_day,
            'leave_type' => $primary->is_full_day ? 'Full day' : 'Partial',
            'reason' => $primary->reason,
            'status' => $primary->status?->value ?? TeacherLeaveStatus::Pending->value,
            'rejection_reason' => $primary->rejection_reason,
            'reviewed_at' => $primary->reviewed_at?->toIso8601String(),
            'created_at' => $primary->created_at?->toIso8601String(),
            'ranges' => $leaves->map(fn (TeacherLeave $leave) => [
                'id' => $leave->id,
                'start_time' => substr((string) $leave->start_time, 0, 5),
                'end_time' => substr((string) $leave->end_time, 0, 5),
                'is_full_day' => $leave->is_full_day,
            ])->values()->all(),
            'affected_count' => count($affectedPayload),
            'reassigned_count' => $reassignedCount,
            'can_approve' => count($affectedPayload) === $reassignedCount
                && in_array($primary->status?->value, TeacherLeaveStatus::openValues(), true),
            'affected_bookings' => $affectedPayload,
            'items' => $leaves->map(fn (TeacherLeave $leave) => $leave->toScheduleArray())->values()->all(),
        ];
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function listGrouped(?string $teacherId = null, ?string $from = null, ?string $to = null): array
    {
        $leaves = TeacherLeave::query()
            ->with(['teacher.user', 'teacher.academicLevels'])
            ->when($teacherId, fn ($q) => $q->where('teacher_id', $teacherId))
            ->when($from, fn ($q) => $q->whereDate('date', '>=', $from))
            ->when($to, fn ($q) => $q->whereDate('date', '<=', $to))
            ->orderByDesc('date')
            ->orderBy('start_time')
            ->get()
            ->groupBy('request_group_id');

        return $leaves->map(function (Collection $group) {
            return $this->serializeGroup($group);
        })->values()->all();
    }
}
