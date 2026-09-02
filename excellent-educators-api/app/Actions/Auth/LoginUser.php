<?php

namespace App\Actions\Auth;

use App\Enums\UserStatus;
use App\Exceptions\ApiException;
use App\Models\User;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\Hash;

class LoginUser
{
    /**
     * @return array{user: User, token: string, expires_in: int}
     */
    public function execute(string $email, string $password, string $deviceName = 'web'): array
    {
        $user = User::query()->where('email', $email)->first();

        if (! $user || ! Hash::check($password, $user->password)) {
            throw new ApiException(
                ErrorCode::INVALID_CREDENTIALS,
                'These credentials do not match our records.',
                401,
            );
        }

        if ($user->status !== UserStatus::Active) {
            throw new ApiException(
                ErrorCode::ACCOUNT_INACTIVE,
                'This account is not active.',
                403,
            );
        }

        $user->tokens()->where('name', $deviceName)->delete();

        $expiresInMinutes = (int) config('sanctum.expiration', 480);
        $expiresAt = now()->addMinutes($expiresInMinutes);

        $token = $user->createToken($deviceName, ['*'], $expiresAt)->plainTextToken;

        $user->forceFill(['last_login_at' => now()])->save();

        return [
            'user' => $user->fresh() ?? $user,
            'token' => $token,
            'expires_in' => $expiresInMinutes * 60,
        ];
    }
}
