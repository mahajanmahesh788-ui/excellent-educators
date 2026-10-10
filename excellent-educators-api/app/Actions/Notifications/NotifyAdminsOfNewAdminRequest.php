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
        $adminRequest->loadMissing(['user', 'student', 'fromLevel', 'targetLevel', 'batch']);

        $requesterName = $adminRequest->user?->name ?? 'Someone';
        [$title, $body] = $this->titleAndBody($adminRequest, $requesterName);

        $this->notifyAdmins->execute(
            NotificationType::AdminRequestSubmitted,
            $title,
            $body,
            [
                'admin_request_id' => $adminRequest->id,
                'requester_type' => $adminRequest->requester_type?->value,
                'request_type' => $adminRequest->request_type?->value,
                'subtitle' => trim((string) $adminRequest->subtitle),
                'link' => '/admin/requests/'.$adminRequest->id,
            ],
        );
    }

    /**
     * @return array{0: string, 1: string}
     */
    private function titleAndBody(AdminRequest $adminRequest, string $requesterName): array
    {
        $studentLabel = $adminRequest->student?->labeledName();

        return match ($adminRequest->request_type) {
            AdminRequestType::PromoteStudent => [
                'Level upgrade request',
                $this->promoteBody($adminRequest, $requesterName, $studentLabel),
            ],
            AdminRequestType::RemoveMentee => [
                'Remove student request',
                $studentLabel !== null
                    ? "{$requesterName} requested to remove {$studentLabel} from their mentees."
                    : "{$requesterName} requested to remove a student from their mentees.",
            ],
            AdminRequestType::RemoveBatchStudent => [
                'Remove student request',
                $this->removeBatchBody($adminRequest, $requesterName, $studentLabel),
            ],
            default => [
                $this->defaultTitle($adminRequest),
                $this->defaultBody($adminRequest, $requesterName),
            ],
        };
    }

    private function promoteBody(AdminRequest $adminRequest, string $requesterName, ?string $studentLabel): string
    {
        $from = $adminRequest->fromLevel?->name ?? 'their current level';
        $to = $adminRequest->targetLevel?->name ?? 'the next level';
        $who = $studentLabel ?? 'a student';

        return "{$requesterName} requested to upgrade {$who} from {$from} to {$to}.";
    }

    private function removeBatchBody(AdminRequest $adminRequest, string $requesterName, ?string $studentLabel): string
    {
        $batchName = $adminRequest->batch?->name;
        $who = $studentLabel ?? 'a student';

        if ($batchName !== null && $batchName !== '') {
            return "{$requesterName} requested to remove {$who} from {$batchName}.";
        }

        return "{$requesterName} requested to remove {$who} from a batch.";
    }

    private function defaultTitle(AdminRequest $adminRequest): string
    {
        $roleLabel = match ($adminRequest->requester_type) {
            AdminRequestRequesterType::Student => 'Student',
            AdminRequestRequesterType::Teacher => 'Teacher',
            default => 'User',
        };

        return "New {$roleLabel} request";
    }

    private function defaultBody(AdminRequest $adminRequest, string $requesterName): string
    {
        $subject = trim((string) $adminRequest->subtitle);
        if ($subject === '') {
            return "{$requesterName} sent a new request.";
        }

        return "{$requesterName} sent a request: {$subject}";
    }
}
