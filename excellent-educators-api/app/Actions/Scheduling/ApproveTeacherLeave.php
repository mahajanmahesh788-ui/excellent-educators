<?php

namespace App\Actions\Scheduling;

use App\Actions\Notifications\CreateUserNotification;
use App\Enums\NotificationType;
use App\Enums\SessionBookingType;
use App\Enums\TeacherLeaveStatus;
use App\Exceptions\ApiException;
use App\Models\SessionBooking;
use App\Models\TeacherLeave;
use App\Models\TeacherLeaveReassignment;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Scheduling\FindBookingsAffectedByLeave;
use App\Scheduling\FindReplacementTeachersForBooking;
use App\Scheduling\LeaveRequestAssembler;
use App\Scheduling\SlotGrid;
use App\Support\AdminActivity;
use App\Support\AppClock;
use App\Support\ErrorCode;
use App\Support\StudentActivity;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class ApproveTeacherLeave
{
    public function __construct(
        private readonly LeaveRequestAssembler $assembler,
        private readonly FindBookingsAffectedByLeave $findAffected,
        private readonly FindReplacementTeachersForBooking $findReplacements,
        private readonly RescheduleSessionBooking $reschedule,
        private readonly CreateUserNotification $notifications,
    ) {}

    public function execute(string $groupId, User $actor): array
    {
        return DB::transaction(function () use ($groupId, $actor) {
            $leaves = TeacherLeave::query()
                ->with('teacher')
                ->where('request_group_id', $groupId)
                ->lockForUpdate()
                ->get();

            if ($leaves->isEmpty()) {
                throw new ApiException(ErrorCode::NOT_FOUND, 'Leave request not found.', 404);
            }

            /** @var TeacherLeave $primary */
            $primary = $leaves->first();
            if ($primary->status === null || ! $primary->status->isOpen()) {
                throw new ApiException(
                    ErrorCode::LEAVE_NOT_APPROVABLE,
                    'This leave request cannot be approved in its current status.',
                    409,
                );
            }

            $teacher = TeacherProfile::query()->lockForUpdate()->findOrFail($primary->teacher_id);
            $affected = $this->findAffected->execute($leaves);

            $drafts = TeacherLeaveReassignment::query()
                ->where('leave_request_group_id', $groupId)
                ->lockForUpdate()
                ->get()
                ->keyBy('booking_id');

            if ($affected->count() !== $drafts->whereNotNull('replacement_teacher_id')->count()) {
                throw new ApiException(
                    ErrorCode::LEAVE_REASSIGNMENT_INCOMPLETE,
                    'Every affected session must have a replacement teacher before approval.',
                    422,
                );
            }

            foreach ($affected as $booking) {
                SessionBooking::query()->whereKey($booking->id)->lockForUpdate()->first();
                $draft = $drafts->get($booking->id);
                $replacementId = $draft?->replacement_teacher_id;
                if ($replacementId === null) {
                    throw new ApiException(
                        ErrorCode::LEAVE_REASSIGNMENT_INCOMPLETE,
                        'Every affected session must have a replacement teacher before approval.',
                        422,
                    );
                }

                $candidates = $this->findReplacements->execute($booking, $teacher->id);
                if (! $candidates->contains(fn (TeacherProfile $t) => $t->id === $replacementId)) {
                    throw new ApiException(
                        ErrorCode::SLOT_UNAVAILABLE,
                        'A selected replacement teacher is no longer available. Refresh and try again.',
                        409,
                    );
                }
            }

            // Apply reassignments one by one inside this outer transaction.
            foreach ($affected as $booking) {
                $draft = $drafts->get($booking->id);
                $replacementId = (string) $draft->replacement_teacher_id;
                $start = SlotGrid::hmFrom($booking->starts_at);
                $date = $booking->date?->toDateString() ?? SlotGrid::dateFrom($booking->starts_at);
                $previousTeacherId = $booking->teacher_id;

                $updated = $this->reschedule->execute($booking, [
                    'teacher_id' => $replacementId,
                    'date' => $date,
                    'start' => $start,
                ], adminOverride: true);

                $updated->update([
                    'reassigned_from_teacher_id' => $previousTeacherId,
                    'reassigned_at' => AppClock::now(),
                ]);

                $this->notifyStudent($updated->fresh(['student.user', 'teacher']));

                AdminActivity::record(
                    $actor,
                    'leave.booking_reassigned',
                    'Reassigned booking '.$updated->id.' from leave request',
                    $updated,
                    [
                        'leave_request_group_id' => $groupId,
                        'from_teacher_id' => $previousTeacherId,
                        'to_teacher_id' => $replacementId,
                    ],
                );
            }

            TeacherLeave::query()
                ->where('request_group_id', $groupId)
                ->update([
                    'status' => TeacherLeaveStatus::Approved->value,
                    'reviewed_by' => $actor->id,
                    'reviewed_at' => AppClock::now(),
                    'rejection_reason' => null,
                ]);

            AdminActivity::record(
                $actor,
                'leave.approved',
                'Approved leave request for '.($teacher->full_name ?? 'teacher'),
                $primary,
                [
                    'leave_request_group_id' => $groupId,
                    'affected_count' => $affected->count(),
                ],
            );

            $fresh = $this->assembler->leavesForGroup($groupId);

            return $this->assembler->serializeGroup($fresh);
        });
    }

    private function notifyStudent(SessionBooking $booking): void
    {
        $booking->loadMissing(['student.user', 'teacher']);
        $user = $booking->student?->user;
        if ($user === null) {
            return;
        }

        $teacherName = $booking->teacher?->full_name ?? 'your mentor';
        $typeLabel = SessionBookingType::fromMixed($booking->type)?->label() ?? 'session';
        $date = $booking->date?->toDateString() ?? '';
        $displayDate = $date !== '' ? Carbon::parse($date)->format('d M Y') : '';

        $this->notifications->execute(
            $user,
            NotificationType::SessionMentorUpdated,
            'Your session has been updated.',
            'Due to an unexpected change in your mentor\'s availability, your session has been reassigned to '
                .$teacherName
                .'. Your scheduled date and time remain unchanged.',
            [
                'booking_id' => $booking->id,
                'teacher_id' => $booking->teacher_id,
                'teacher_name' => $teacherName,
                'date' => $date,
                'start' => SlotGrid::hmFrom($booking->starts_at),
                'session_type' => $booking->type?->value ?? $booking->type,
            ],
        );

        StudentActivity::record(
            $booking->student,
            'session_mentor_updated',
            "Session mentor updated for {$typeLabel}".($displayDate !== '' ? " on {$displayDate}" : ''),
            related: $booking,
        );
    }
}
