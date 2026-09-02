<?php

namespace App\Actions\Auth;

use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;

class ResetPassword
{
    /**
     * @param  array{email: string, password: string, password_confirmation: string, token: string}  $credentials
     */
    public function execute(array $credentials): string
    {
        return Password::reset($credentials, function (User $user, string $password): void {
            $user->forceFill([
                'password' => $password,
                'remember_token' => Str::random(60),
            ])->save();

            $user->tokens()->delete();

            event(new PasswordReset($user));
        });
    }
}
