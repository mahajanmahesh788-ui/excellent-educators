<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Models\User;
use App\Models\UserNotification;

class CreateUserNotification
{
    /**
     * @param  array<string, mixed>  $data
     */
    public function execute(
        User $user,
        NotificationType $type,
        string $title,
        string $body,
        array $data = [],
    ): UserNotification {
        return UserNotification::query()->create([
            'user_id' => $user->id,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'data' => $data === [] ? null : $data,
            'created_at' => now(),
        ]);
    }
}
