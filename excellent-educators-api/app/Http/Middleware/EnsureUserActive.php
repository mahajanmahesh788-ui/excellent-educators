<?php

namespace App\Http\Middleware;

use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserActive
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if ($user === null) {
            return $next($request);
        }

        if ($user->isActive()) {
            return $next($request);
        }

            // Allow logout so the client can clear local session cleanly.
            if ($request->is('*/auth/logout')) {
                return $next($request);
            }

        $user->currentAccessToken()?->delete();

        return ApiResponse::error(
            'Your account has been disabled by the admin. Kindly contact support.',
            ErrorCode::ACCOUNT_INACTIVE,
            null,
            403,
        );
    }
}
