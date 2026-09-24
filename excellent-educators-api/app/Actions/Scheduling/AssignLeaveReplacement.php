<?php

namespace App\Actions\Scheduling;

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
use App\Support\AppClock;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class AssignLeaveReplacement
{
    public function __construct(
        private readonly LeaveRequestAssembler $assembler,
        private readonly FindBookingsAffectedByLeave $findAffected,
        private readonly FindReplacementTeachersForBooking $findReplacements,
    ) {}

    public function execute(
        string $groupId,
        string $bookingId,
        ?string $replacementTeacherId,
        User $actor,
    ): array {
        return DB::transaction(function () use ($groupId, $bookingId, $replacementTeacherId, $actor) {
            $leaves = TeacherLeave::query()
                ->where('request_group_id', $groupId)
                ->lockForUpdate()
                ->get();

            if ($leaves->isEmpty()) {
                throw new ApiException(ErrorCode::NOT_FOUND, 'Leave request not found.', 404);
            }

            $status = $leaves->first()->status;
            if ($status === null || ! $status->isOpen()) {
                throw new ApiException(
                    ErrorCode::LEAVE_NOT_APPROVABLE,
                    'Replacements can only be assigned while the leave request is open.',
                    422,
                );
            }

            $affected = $this->findAffected->execute($leaves);
            $booking = $affected->firstWhere('id', $bookingId);
            if ($booking === null) {
                throw new ApiException(
                    ErrorCode::VALIDATION_ERROR,
                    'This booking is not affected by the leave request.',
                    422,
                );
            }

            if ($replacementTeacherId === null || $replacementTeacherId === '') {
                TeacherLeaveReassignment::query()->updateOrCreate(
                    [
                        'leave_request_group_id' => $groupId,
                        'booking_id' => $bookingId,
                    ],
                    [
                        'replacement_teacher_id' => null,
                        'assigned_by' => null,
                        'assigned_at' => null,
                    ],
                );
            } else {
                $replacement = TeacherProfile::query()->find($replacementTeacherId);
                if ($replacement === null) {
                    throw new ApiException(ErrorCode::NOT_FOUND, 'Replacement teacher not found.', 404);
                }

                $candidates = $this->findReplacements->execute($booking, $leaves->first()->teacher_id);
                if (! $candidates->contains(fn (TeacherProfile $t) => $t->id === $replacement->id)) {
                    throw new ApiException(
                        ErrorCode::SLOT_UNAVAILABLE,
                        'This teacher is not available for the selected session.',
                        422,
                    );
                }

                // Same replacement may cover multiple slots only when each is free.
                $this->assertNoDraftConflict($groupId, $booking, $replacement->id);

                TeacherLeaveReassignment::query()->updateOrCreate(
                    [
                        'leave_request_group_id' => $groupId,
                        'booking_id' => $bookingId,
                    ],
                    [
                        'replacement_teacher_id' => $replacement->id,
                        'assigned_by' => $actor->id,
                        'assigned_at' => AppClock::now(),
                    ],
                );
            }

            $fresh = $this->assembler->leavesForGroup($groupId);

            return $this->assembler->serializeGroup($fresh, includeReplacementsAvailability: true);
        });
    }

    private function assertNoDraftConflict(
        string $groupId,
        SessionBooking $booking,
        string $replacementTeacherId,
    ): void {
        $otherDrafts = TeacherLeaveReassignment::query()
            ->with('booking')
            ->where('leave_request_group_id', $groupId)
            ->where('replacement_teacher_id', $replacementTeacherId)
            ->where('booking_id', '!=', $booking->id)
            ->get();

        foreach ($otherDrafts as $draft) {
            $other = $draft->booking;
            if ($other === null) {
                continue;
            }
            if ($booking->starts_at < $other->ends_at && $other->starts_at < $booking->ends_at) {
                throw new ApiException(
                    ErrorCode::BOOKING_OVERLAP,
                    'This teacher is already assigned to an overlapping session in this leave request.',
                    422,
                );
            }
        }
    }
}
