<?php

namespace App\Actions\AdminRequests;

use App\Enums\AdminRequestRequesterType;
use App\Enums\AdminRequestStatus;
use App\Enums\AdminRequestType;
use App\Models\AdminRequest;
use App\Models\User;

class CreateAdminRequest
{
    /**
     * @param  array{subtitle: string, description: string}  $input
     */
    public function execute(User $user, AdminRequestRequesterType $requesterType, array $input): AdminRequest
    {
        return AdminRequest::query()->create([
            'user_id' => $user->id,
            'requester_type' => $requesterType,
            'request_type' => AdminRequestType::General,
            'subtitle' => $input['subtitle'],
            'description' => $input['description'],
            'status' => AdminRequestStatus::Pending,
        ]);
    }
}
