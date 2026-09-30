<?php

namespace App\Actions\Notifications;

use App\Enums\NotificationType;
use App\Models\User;
use App\Models\UserNotification;
use Throwable;

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

    /**
     * @param  array<string, mixed>  $data
     */
    public function safeExecute(
        ?User $user,
        NotificationType $type,
        string $title,
        string $body,
        array $data = [],
    ): ?UserNotification {
        if ($user === null) {
            return null;
        }

        try {
            return $this->execute($user, $type, $title, $body, $data);
        } catch (Throwable) {
            return null;
        }
    }
}
