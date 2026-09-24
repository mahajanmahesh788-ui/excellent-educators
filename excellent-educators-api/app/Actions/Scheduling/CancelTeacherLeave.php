<?php

namespace App\Actions\Scheduling;

use App\Enums\TeacherLeaveStatus;
use App\Exceptions\ApiException;
use App\Models\TeacherLeave;
use App\Models\TeacherLeaveReassignment;
use App\Models\User;
use App\Scheduling\LeaveRequestAssembler;
use App\Support\AdminActivity;
use App\Support\AppClock;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class CancelTeacherLeave
{
    public function __construct(
        private readonly LeaveRequestAssembler $assembler,
    ) {}

    public function execute(string $groupId, ?User $actor = null, ?string $teacherId = null): array
    {
        return DB::transaction(function () use ($groupId, $actor, $teacherId) {
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

            if ($teacherId !== null && $primary->teacher_id !== $teacherId) {
                throw new ApiException(ErrorCode::NOT_FOUND, 'Leave request not found.', 404);
            }

            if ($primary->dateHasPassed()) {
                throw new ApiException(ErrorCode::LEAVE_DATE_PASSED, 'Past leave cannot be cancelled.', 422);
            }

            if ($primary->status === null || ! $primary->status->isOpen()) {
                throw new ApiException(
                    ErrorCode::LEAVE_NOT_APPROVABLE,
                    'Only pending leave requests can be cancelled.',
                    422,
                );
            }

            TeacherLeave::query()
                ->where('request_group_id', $groupId)
                ->update([
                    'status' => TeacherLeaveStatus::Cancelled->value,
                    'reviewed_by' => $actor?->id,
                    'reviewed_at' => AppClock::now(),
                ]);

            TeacherLeaveReassignment::query()
                ->where('leave_request_group_id', $groupId)
                ->delete();

            if ($actor !== null) {
                AdminActivity::record(
                    $actor,
                    'leave.cancelled',
                    'Cancelled leave request for '.($primary->teacher?->full_name ?? 'teacher'),
                    $primary,
                    ['leave_request_group_id' => $groupId],
                );
            }

            $fresh = $this->assembler->leavesForGroup($groupId);

            return $this->assembler->serializeGroup($fresh);
        });
    }
}
