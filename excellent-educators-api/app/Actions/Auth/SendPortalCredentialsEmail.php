<?php

namespace App\Actions\Auth;

use App\Mail\PortalCredentialsMail;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

class SendPortalCredentialsEmail
{
    public function execute(
        User $user,
        string $temporaryPassword,
        string $roleLabel,
        ?string $studentCode = null,
    ): void {
        $loginUrl = rtrim((string) config('app.frontend_url'), '/').'/#/login';

        try {
            Mail::to($user->email)->send(new PortalCredentialsMail($user, [
                'role_label' => $roleLabel,
                'login_url' => $loginUrl,
                'temporary_password' => $temporaryPassword,
                'student_code' => $studentCode,
            ]));
        } catch (Throwable $exception) {
            // Account create must succeed even if SMTP fails.
            Log::error('Failed to send portal credentials email.', [
                'user_id' => $user->id,
                'email' => $user->email,
                'message' => $exception->getMessage(),
            ]);
        }
    }
}
