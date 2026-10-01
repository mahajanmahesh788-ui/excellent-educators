<?php

namespace App\Actions\AdminRequests;

use App\Actions\Notifications\CreateUserNotification;
use App\Enums\AdminRequestStatus;
use App\Enums\AdminRequestType;
use App\Enums\NotificationType;
use App\Exceptions\ApiException;
use App\Models\AdminRequest;
use App\Models\User;
use App\Support\AppClock;
use App\Support\ErrorCode;

class ResolveAdminRequest
{
    public function __construct(
        private readonly ApplyAdminRequestAction $applyAdminRequestAction,
        private readonly CreateUserNotification $notifications,
    ) {}

    public function execute(
        AdminRequest $adminRequest,
        User $admin,
        bool $applyAction = true,
        bool $reject = false,
    ): AdminRequest {
        if ($adminRequest->status !== AdminRequestStatus::Pending) {
            throw new ApiException(
                ErrorCode::CONFLICT,
                'This request is already resolved.',
                409,
            );
        }

        if ($reject) {
            $adminRequest->update([
                'status' => AdminRequestStatus::Rejected,
                'resolved_at' => AppClock::now(),
                'resolved_by_id' => $admin->id,
            ]);

            $fresh = $adminRequest->fresh(['user.studentProfile', 'user.teacherProfile', 'resolvedBy', 'student', 'batch', 'fromLevel', 'targetLevel']);
            $this->notifyRequester($fresh, approved: false);

            return $fresh;
        }

        if ($applyAction) {
            $adminRequest->loadMissing(['student', 'batch', 'fromLevel', 'targetLevel']);
            $this->applyAdminRequestAction->execute($adminRequest, $admin);
        }

        $adminRequest->update([
            'status' => AdminRequestStatus::Completed,
            'resolved_at' => AppClock::now(),
            'resolved_by_id' => $admin->id,
        ]);

        $fresh = $adminRequest->fresh(['user.studentProfile', 'user.teacherProfile', 'resolvedBy', 'student', 'batch', 'fromLevel', 'targetLevel']);

        if ($applyAction && $fresh?->request_type === AdminRequestType::PromoteStudent) {
            $this->notifyRequester($fresh, approved: true);
        }

        return $fresh;
    }

    private function notifyRequester(?AdminRequest $adminRequest, bool $approved): void
    {
        if ($adminRequest === null || $adminRequest->user === null) {
            return;
        }

        $from = $adminRequest->fromLevel?->name ?? 'previous level';
        $to = $adminRequest->targetLevel?->name ?? 'new level';
        $studentName = $adminRequest->student?->full_name ?? 'the student';

        if ($approved) {
            $this->notifications->safeExecute(
                $adminRequest->user,
                NotificationType::AdminRequestApproved,
                'Level upgrade approved',
                "Your request to upgrade {$studentName} from {$from} to {$to} was approved.",
                [
                    'admin_request_id' => $adminRequest->id,
                    'student_id' => $adminRequest->student_id,
                    'from_level' => $from,
                    'to_level' => $to,
                    'link' => '/teacher/requests',
                ],
            );

            return;
        }

        $this->notifications->safeExecute(
            $adminRequest->user,
            NotificationType::AdminRequestRejected,
            'Level upgrade rejected',
            "Your request to upgrade {$studentName} from {$from} to {$to} was rejected.",
            [
                'admin_request_id' => $adminRequest->id,
                'student_id' => $adminRequest->student_id,
                'from_level' => $from,
                'to_level' => $to,
                'link' => '/teacher/requests',
            ],
        );
    }
}
