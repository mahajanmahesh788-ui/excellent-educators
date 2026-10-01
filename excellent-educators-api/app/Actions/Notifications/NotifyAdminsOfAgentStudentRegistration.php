<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Models\StudentProfile;
use App\Models\User;

class NotifyAdminsOfAgentStudentRegistration
{
    public function __construct(
        private readonly NotifyOperationalAdmins $notifyAdmins,
    ) {}

    public function execute(User $agent, StudentProfile $student): void
    {
        if (! $agent->isAgent()) {
            return;
        }

        $student->loadMissing('user');
        $studentName = $student->full_name ?: ($student->user?->name ?? 'A student');
        $agentName = $agent->name ?: 'An agent';

        $this->notifyAdmins->execute(
            NotificationType::AgentRegisteredStudent,
            'New student registered by agent',
            "{$agentName} registered {$studentName} ({$student->student_code}).",
            [
                'student_id' => $student->id,
                'student_name' => $studentName,
                'student_code' => $student->student_code,
                'agent_id' => $agent->id,
                'agent_name' => $agentName,
                'link' => '/admin/students/'.$student->id,
            ],
        );
    }
}
