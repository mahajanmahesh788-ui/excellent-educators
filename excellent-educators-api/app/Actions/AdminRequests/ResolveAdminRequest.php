<?php

namespace App\Actions\AdminRequests;

use App\Enums\AdminRequestStatus;
use App\Exceptions\ApiException;
use App\Models\AdminRequest;
use App\Models\User;
use App\Support\AppClock;
use App\Support\ErrorCode;

class ResolveAdminRequest
{
    public function __construct(
        private readonly ApplyAdminRequestAction $applyAdminRequestAction,
    ) {}

    public function execute(AdminRequest $adminRequest, User $admin, bool $applyAction = true): AdminRequest
    {
        if ($adminRequest->status === AdminRequestStatus::Completed) {
            throw new ApiException(
                ErrorCode::CONFLICT,
                'This request is already marked as resolved.',
                409,
            );
        }

        if ($applyAction) {
            $adminRequest->loadMissing(['student', 'batch']);
            $this->applyAdminRequestAction->execute($adminRequest);
        }

        $adminRequest->update([
            'status' => AdminRequestStatus::Completed,
            'resolved_at' => AppClock::now(),
            'resolved_by_id' => $admin->id,
        ]);

        return $adminRequest->fresh(['user.studentProfile', 'user.teacherProfile', 'resolvedBy', 'student', 'batch']);
    }
}
