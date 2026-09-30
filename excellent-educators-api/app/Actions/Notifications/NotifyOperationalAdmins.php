<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Enums\RoleName;
use App\Models\User;
use Throwable;

class NotifyOperationalAdmins
{
    public function __construct(
        private readonly CreateUserNotification $notifications,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public function execute(
        NotificationType $type,
        string $title,
        string $body,
        array $data = [],
    ): void {
        try {
            User::query()
                ->role([
                    RoleName::SuperAdmin->value,
                    RoleName::OperationalAdmin->value,
                ])
                ->get()
                ->each(function (User $admin) use ($type, $title, $body, $data): void {
                    $this->notifications->execute($admin, $type, $title, $body, $data);
                });
        } catch (Throwable) {
            // Domain action must succeed even if notify fails.
        }
    }
}
