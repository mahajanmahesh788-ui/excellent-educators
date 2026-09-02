<?php

namespace App\Actions\Auth;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class ChangePassword
{
    public function execute(User $user, string $currentPassword, string $newPassword): void
    {
        if (! Hash::check($currentPassword, $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => [__('The current password is incorrect.')],
            ]);
        }

        $user->forceFill([
            'password' => $newPassword,
        ])->save();

        $user->tokens()->delete();
    }
}
