<?php

namespace App\Actions\AdminRequests;

use App\Enums\AdminRequestRequesterType;
use App\Enums\AdminRequestStatus;
use App\Enums\AdminRequestType;
use App\Actions\Notifications\NotifyAdminsOfNewAdminRequest;
use App\Exceptions\ApiException;
use App\Models\AdminRequest;
use App\Models\User;
use App\Support\ErrorCode;

class CreateAdminRequest
{
    public const MAX_PENDING_STUDENT_REQUESTS = 3;

    public function __construct(
        private readonly NotifyAdminsOfNewAdminRequest $notifyAdmins,
    ) {}

    /**
     * @param  array{subtitle: string, description: string}  $input
     */
    public function execute(User $user, AdminRequestRequesterType $requesterType, array $input): AdminRequest
    {
        if ($requesterType === AdminRequestRequesterType::Student) {
            $this->assertStudentPendingLimit($user);
        }

        $adminRequest = AdminRequest::query()->create([
            'user_id' => $user->id,
            'requester_type' => $requesterType,
            'request_type' => AdminRequestType::General,
            'subtitle' => $input['subtitle'],
            'description' => $input['description'],
            'status' => AdminRequestStatus::Pending,
        ]);

        $this->notifyAdmins->execute($adminRequest);

        return $adminRequest;
    }

    private function assertStudentPendingLimit(User $user): void
    {
        $pending = AdminRequest::query()
            ->where('user_id', $user->id)
            ->where('requester_type', AdminRequestRequesterType::Student)
            ->where('status', AdminRequestStatus::Pending)
            ->count();

        if ($pending >= self::MAX_PENDING_STUDENT_REQUESTS) {
            throw new ApiException(
                ErrorCode::CONFLICT,
                'You already have '.self::MAX_PENDING_STUDENT_REQUESTS.' pending requests. Please wait for an admin to resolve them before sending another.',
                409,
            );
        }
    }
}
