<?php

namespace App\Http\Controllers\Api\V1\Student;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\UserResource;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use App\Support\PolicyTerms;
use App\Support\StudentActivity;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AcceptTermsController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user === null) {
            return ApiResponse::error('Unauthenticated.', ErrorCode::UNAUTHORIZED, null, 401);
        }

        if (! $user->isStudent()) {
            return ApiResponse::error('Only students can accept platform terms here.', ErrorCode::FORBIDDEN, null, 403);
        }

        $version = PolicyTerms::currentVersion();
        $user->forceFill([
            'terms_accepted_at' => now(),
            'terms_accepted_version' => $version,
            'terms_accepted_ip' => $request->ip(),
            'terms_accepted_user_agent' => substr((string) $request->userAgent(), 0, 2000),
        ])->save();

        $user->refresh();
        $user->load(['adminProfile', 'studentProfile']);

        if ($user->studentProfile !== null) {
            StudentActivity::record(
                $user->studentProfile,
                'terms_accepted',
                "Accepted platform terms (version {$version}).",
                $user,
                $user,
                ['version' => $version],
            );
        }

        return ApiResponse::success(
            'Terms accepted successfully.',
            UserResource::make($user)->resolve(),
        );
    }
}
