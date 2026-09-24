<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Actions\Auth\ChangePassword;
use App\Actions\Auth\LoginUser;
use App\Actions\Auth\LogoutUser;
use App\Actions\Auth\ResetPassword;
use App\Actions\Auth\SendPasswordResetLink;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\ChangePasswordRequest;
use App\Http\Requests\Api\V1\Auth\ForgotPasswordRequest;
use App\Http\Requests\Api\V1\Auth\LoginRequest;
use App\Http\Requests\Api\V1\Auth\ResetPasswordRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Password;

class AuthController extends Controller
{
    public function login(LoginRequest $request, LoginUser $loginUser): JsonResponse
    {
        $result = $loginUser->execute(
            email: $request->string('email')->toString(),
            password: $request->string('password')->toString(),
            deviceName: $request->string('device_name', 'web')->toString(),
        );

        $result['user']->load('roles', 'permissions', 'adminProfile');

        return ApiResponse::success('Logged in successfully.', [
            'token' => $result['token'],
            'token_type' => 'Bearer',
            'expires_in' => $result['expires_in'],
            'user' => UserResource::make($result['user'])->resolve(),
        ]);
    }

    public function logout(Request $request, LogoutUser $logoutUser): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();
        $logoutUser->execute($user, $request->bearerToken());

        return ApiResponse::success('Logged out successfully.');
    }

    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();
        $user->load('roles', 'permissions', 'adminProfile');

        return ApiResponse::success('Current user fetched successfully.', UserResource::make($user)->resolve());
    }

    public function changePassword(ChangePasswordRequest $request, ChangePassword $changePassword): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $changePassword->execute(
            $user,
            $request->string('current_password')->toString(),
            $request->string('password')->toString(),
        );

        return ApiResponse::success('Password changed successfully. Please log in again.');
    }

    public function forgotPassword(ForgotPasswordRequest $request, SendPasswordResetLink $sendPasswordResetLink): JsonResponse
    {
        $sendPasswordResetLink->execute($request->string('email')->toString());

        return ApiResponse::success('If that email exists, a password reset link has been sent.');
    }

    public function resetPassword(ResetPasswordRequest $request, ResetPassword $resetPassword): JsonResponse
    {
        $status = $resetPassword->execute($request->only('email', 'password', 'password_confirmation', 'token'));

        if ($status !== Password::PASSWORD_RESET) {
            return ApiResponse::error(
                'Unable to reset password.',
                'VALIDATION_ERROR',
                ['email' => [__($status)]],
                422,
            );
        }

        return ApiResponse::success('Password reset successfully.');
    }
}
