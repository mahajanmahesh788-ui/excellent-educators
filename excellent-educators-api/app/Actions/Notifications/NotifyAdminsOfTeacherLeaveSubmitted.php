<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Enums\TeacherLeaveStatus;
use App\Models\TeacherProfile;
use App\Support\AppClock;

class NotifyAdminsOfTeacherLeaveSubmitted
{
    public function __construct(
        private readonly NotifyOperationalAdmins $notifyAdmins,
    ) {}

    public function execute(
        TeacherProfile $teacher,
        string $groupId,
        string $date,
        TeacherLeaveStatus $status,
    ): void {
        $teacher->loadMissing('user');
        $teacherName = $teacher->full_name ?: ($teacher->user?->name ?? 'A teacher');
        $displayDate = AppClock::formatDisplayDate($date, 'the requested date');

        $this->notifyAdmins->execute(
            NotificationType::TeacherLeaveSubmitted,
            'New leave request',
            "New leave request from {$teacherName} for {$displayDate}.",
            [
                'leave_request_group_id' => $groupId,
                'teacher_id' => $teacher->id,
                'teacher_name' => $teacherName,
                'date' => $date,
                'status' => $status->value,
                'link' => '/admin/leaves/'.$groupId,
            ],
        );
    }
}
