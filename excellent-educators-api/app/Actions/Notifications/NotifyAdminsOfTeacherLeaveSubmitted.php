<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Enums\RoleName;
use App\Enums\TeacherLeaveStatus;
use App\Models\TeacherProfile;
use App\Models\User;
use Illuminate\Support\Carbon;
use Throwable;

class NotifyAdminsOfTeacherLeaveSubmitted
{
    public function __construct(
        private readonly CreateUserNotification $notifications,
    ) {}

    public function execute(
        TeacherProfile $teacher,
        string $groupId,
        string $date,
        TeacherLeaveStatus $status,
    ): void {
        $teacher->loadMissing('user');
        $teacherName = $teacher->full_name ?: ($teacher->user?->name ?? 'A teacher');
        $displayDate = Carbon::parse($date)->format('d M Y');

        $title = 'New leave request';
        $body = "New leave request from {$teacherName} for {$displayDate}.";
        $data = [
            'leave_request_group_id' => $groupId,
            'teacher_id' => $teacher->id,
            'teacher_name' => $teacherName,
            'date' => $date,
            'status' => $status->value,
            'link' => '/admin/leaves/'.$groupId,
        ];

        try {
            User::query()
                ->role([
                    RoleName::SuperAdmin->value,
                    RoleName::OperationalAdmin->value,
                ])
                ->get()
                ->each(function (User $admin) use ($title, $body, $data): void {
                    $this->notifications->execute(
                        $admin,
                        NotificationType::TeacherLeaveSubmitted,
                        $title,
                        $body,
                        $data,
                    );
                });
        } catch (Throwable) {
            // Leave submission must succeed even if notify fails.
        }
    }
}
