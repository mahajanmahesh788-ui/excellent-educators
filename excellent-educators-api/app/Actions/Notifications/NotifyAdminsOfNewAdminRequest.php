<?php

namespace App\Actions\Notifications;

use App\Enums\AdminRequestRequesterType;
use App\Enums\AdminRequestType;
use App\Enums\NotificationType;
use App\Models\AdminRequest;

class NotifyAdminsOfNewAdminRequest
{
    public function __construct(
        private readonly NotifyOperationalAdmins $notifyAdmins,
    ) {}

    public function execute(AdminRequest $adminRequest): void
    {
        $adminRequest->loadMissing('user');

        $requesterName = $adminRequest->user?->name ?? 'Someone';
        $roleLabel = match ($adminRequest->requester_type) {
            AdminRequestRequesterType::Student => 'Student',
            AdminRequestRequesterType::Teacher => 'Teacher',
            default => 'User',
        };

        $typeLabel = match ($adminRequest->request_type) {
            AdminRequestType::RemoveMentee => 'remove mentee',
            AdminRequestType::RemoveBatchStudent => 'remove batch student',
            AdminRequestType::PromoteStudent => 'level upgrade',
            default => 'support',
        };

        $subject = trim((string) $adminRequest->subtitle);
        if ($subject === '') {
            $subject = 'New request';
        }

        $this->notifyAdmins->execute(
            NotificationType::AdminRequestSubmitted,
            "New {$roleLabel} request",
            "{$requesterName} sent a {$typeLabel} request: {$subject}",
            [
                'admin_request_id' => $adminRequest->id,
                'requester_type' => $adminRequest->requester_type?->value,
                'request_type' => $adminRequest->request_type?->value,
                'subtitle' => $subject,
                'link' => '/admin/requests/'.$adminRequest->id,
            ],
        );
    }
}
