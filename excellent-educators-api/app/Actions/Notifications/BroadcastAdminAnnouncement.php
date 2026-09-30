<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Enums\RoleName;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class BroadcastAdminAnnouncement
{
    public function __construct(
        private readonly CreateUserNotification $createUserNotification,
    ) {}

    /**
     * @return array{sent: int, audience: string}
     */
    public function execute(string $title, string $body, string $audience, ?User $actor = null): array
    {
        $query = User::query()->where('status', 'active');

        $query = match ($audience) {
            'students' => $query->role(RoleName::Student->value),
            'teachers' => $query->role([
                RoleName::CommonTeacher->value,
                RoleName::MasterTeacher->value,
            ]),
            default => $query->role([
                RoleName::Student->value,
                RoleName::CommonTeacher->value,
                RoleName::MasterTeacher->value,
                RoleName::SubAdmin->value,
                RoleName::OperationalAdmin->value,
                RoleName::SuperAdmin->value,
            ]),
        };

        $users = $query->get();
        $sent = 0;

        DB::transaction(function () use ($users, $title, $body, $actor, &$sent): void {
            foreach ($users as $user) {
                $this->createUserNotification->execute(
                    $user,
                    NotificationType::AdminAnnouncement,
                    $title,
                    $body,
                    [
                        'audience' => 'broadcast',
                        'actor_id' => $actor?->id,
                        'actor_name' => $actor?->name,
                    ],
                );
                $sent++;
            }
        });

        return ['sent' => $sent, 'audience' => $audience];
    }
}
