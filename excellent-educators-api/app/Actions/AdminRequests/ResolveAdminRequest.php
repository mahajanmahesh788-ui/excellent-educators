<?php

namespace App\Actions\AdminRequests;

use App\Actions\Notifications\CreateUserNotification;
use App\Enums\AdminRequestRequesterType;
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
        ?string $resolutionNote = null,
    ): AdminRequest {
        if ($adminRequest->status !== AdminRequestStatus::Pending) {
            throw new ApiException(
                ErrorCode::CONFLICT,
                'This request is already resolved.',
                409,
            );
        }

        $note = $resolutionNote !== null ? trim($resolutionNote) : null;
        if ($note === '') {
            $note = null;
        }

        if ($reject) {
            $adminRequest->update([
                'status' => AdminRequestStatus::Rejected,
                'resolution_note' => $note,
                'resolved_at' => AppClock::now(),
                'resolved_by_id' => $admin->id,
            ]);

            $fresh = $adminRequest->fresh(['user.studentProfile', 'user.teacherProfile', 'resolvedBy', 'student', 'batch', 'fromLevel', 'targetLevel']);
            $this->notifyRequester($fresh, approved: false, actionApplied: false);

            return $fresh;
        }

        if ($applyAction) {
            $adminRequest->loadMissing(['student', 'batch', 'fromLevel', 'targetLevel']);
            $this->applyAdminRequestAction->execute($adminRequest, $admin);
        }

        $adminRequest->update([
            'status' => AdminRequestStatus::Completed,
            'resolution_note' => $note,
            'resolved_at' => AppClock::now(),
            'resolved_by_id' => $admin->id,
        ]);

        $fresh = $adminRequest->fresh(['user.studentProfile', 'user.teacherProfile', 'resolvedBy', 'student', 'batch', 'fromLevel', 'targetLevel']);
        $this->notifyRequester($fresh, approved: true, actionApplied: $applyAction);

        return $fresh;
    }

    private function notifyRequester(?AdminRequest $adminRequest, bool $approved, bool $actionApplied = true): void
    {
        if ($adminRequest === null || $adminRequest->user === null) {
            return;
        }

        [$title, $body] = $this->notificationCopy($adminRequest, $approved, $actionApplied);
        $note = $adminRequest->resolution_note;
        if (is_string($note) && trim($note) !== '') {
            $body .= "\n\nAdmin message: ".trim($note);
        }

        $link = $adminRequest->requester_type === AdminRequestRequesterType::Student
            ? '/student/requests'
            : '/teacher/requests';

        $this->notifications->safeExecute(
            $adminRequest->user,
            $approved ? NotificationType::AdminRequestApproved : NotificationType::AdminRequestRejected,
            $title,
            $body,
            [
                'admin_request_id' => $adminRequest->id,
                'student_id' => $adminRequest->student_id,
                'request_type' => $adminRequest->request_type?->value,
                'resolution_note' => $note,
                'link' => $link,
            ],
        );
    }

    /**
     * @return array{0: string, 1: string}
     */
    private function notificationCopy(AdminRequest $adminRequest, bool $approved, bool $actionApplied): array
    {
        $type = $adminRequest->request_type;
        $studentName = $adminRequest->student?->labeledName('the student') ?? 'the student';
        $from = $adminRequest->fromLevel?->name ?? 'previous level';
        $to = $adminRequest->targetLevel?->name ?? 'new level';

        if ($type === AdminRequestType::PromoteStudent) {
            return $approved
                ? [
                    'Level upgrade approved',
                    "Your request to upgrade {$studentName} from {$from} to {$to} was approved.",
                ]
                : [
                    'Level upgrade rejected',
                    "Your request to upgrade {$studentName} from {$from} to {$to} was rejected.",
                ];
        }

        if ($type === AdminRequestType::RemoveMentee || $type === AdminRequestType::RemoveBatchStudent) {
            if (! $approved) {
                return [
                    'Request rejected',
                    "Your request to remove {$studentName} was rejected.",
                ];
            }

            if ($actionApplied) {
                return [
                    'Request approved',
                    "Your request to remove {$studentName} was approved.",
                ];
            }

            return [
                'Request resolved',
                "Your request to remove {$studentName} was marked as resolved without removing the student.",
            ];
        }

        $subtitle = $adminRequest->subtitle ?: 'your request';

        return $approved
            ? [
                'Request resolved',
                "Your request ({$subtitle}) was resolved by admin.",
            ]
            : [
                'Request rejected',
                "Your request ({$subtitle}) was rejected by admin.",
            ];
    }
}
