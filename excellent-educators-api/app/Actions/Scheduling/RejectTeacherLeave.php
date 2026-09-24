<?php

namespace App\Actions\Scheduling;

use App\Actions\Notifications\CreateUserNotification;
use App\Enums\NotificationType;
use App\Enums\TeacherLeaveStatus;
use App\Exceptions\ApiException;
use App\Models\TeacherLeave;
use App\Models\TeacherLeaveReassignment;
use App\Models\User;
use App\Scheduling\LeaveRequestAssembler;
use App\Support\AdminActivity;
use App\Support\AppClock;
use App\Support\ErrorCode;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class RejectTeacherLeave
{
    public function __construct(
        private readonly LeaveRequestAssembler $assembler,
        private readonly CreateUserNotification $notifications,
    ) {}

    public function execute(string $groupId, User $actor, ?string $reason = null): array
    {
        return DB::transaction(function () use ($groupId, $actor, $reason) {
            $leaves = TeacherLeave::query()
                ->with(['teacher.user'])
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
                    'This leave request cannot be rejected in its current status.',
                    409,
                );
            }

            $rejectionReason = $reason !== null ? trim($reason) : null;

            TeacherLeave::query()
                ->where('request_group_id', $groupId)
                ->update([
                    'status' => TeacherLeaveStatus::Rejected->value,
                    'reviewed_by' => $actor->id,
                    'reviewed_at' => AppClock::now(),
                    'rejection_reason' => $rejectionReason !== '' ? $rejectionReason : null,
                ]);

            TeacherLeaveReassignment::query()
                ->where('leave_request_group_id', $groupId)
                ->delete();

            $teacher = $primary->teacher;
            $user = $teacher?->user;
            $date = $primary->date?->toDateString() ?? '';
            $displayDate = $date !== '' ? Carbon::parse($date)->format('d M Y') : 'the requested date';

            if ($user !== null) {
                $this->notifications->execute(
                    $user,
                    NotificationType::TeacherLeaveRejected,
                    'Leave request not approved',
                    "Your leave request for {$displayDate} was not approved.",
                    [
                        'leave_request_group_id' => $groupId,
                        'date' => $date,
                        'rejection_reason' => $rejectionReason,
                    ],
                );
            }

            AdminActivity::record(
                $actor,
                'leave.rejected',
                'Rejected leave request for '.($teacher?->full_name ?? 'teacher'),
                $primary,
                [
                    'leave_request_group_id' => $groupId,
                    'rejection_reason' => $rejectionReason,
                ],
            );

            $fresh = $this->assembler->leavesForGroup($groupId);

            return $this->assembler->serializeGroup($fresh);
        });
    }
}
