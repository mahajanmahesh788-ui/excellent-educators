<?php

namespace App\Actions\Auth;

use App\Models\User;
use Laravel\Sanctum\PersonalAccessToken;

class LogoutUser
{
    public function execute(User $user, ?string $bearerToken = null): void
    {
        if (is_string($bearerToken) && $bearerToken !== '') {
            $accessToken = PersonalAccessToken::findToken($bearerToken);

            if ($accessToken && (string) $accessToken->tokenable_id === (string) $user->id) {
                $accessToken->delete();

                return;
            }
        }

        $current = $user->currentAccessToken();

        if ($current instanceof PersonalAccessToken) {
            $current->delete();
        }
    }
}
