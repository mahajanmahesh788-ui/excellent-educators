<?php

namespace App\Support;

use App\Enums\UserStatus;
use App\Models\User;

final class SyncUserAccess
{
    public static function deactivate(User $user): void
    {
        $user->forceFill(['status' => UserStatus::Inactive])->save();
        $user->tokens()->delete();
    }

    public static function activate(User $user): void
    {
        $user->forceFill(['status' => UserStatus::Active])->save();
    }

    public static function syncFromProfileStatus(User $user, string $profileStatus): void
    {
        if ($profileStatus === 'inactive' || $profileStatus === 'suspended') {
            self::deactivate($user);

            return;
        }

        self::activate($user);
    }
}
