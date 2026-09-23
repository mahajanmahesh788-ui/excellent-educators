<?php

namespace App\Http\Middleware;

use App\Support\AdminPermissionMap;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdminPermission
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if ($user === null || ! $user->isAdmin()) {
            return ApiResponse::error('This action is unauthorized.', ErrorCode::FORBIDDEN, null, 403);
        }

        if ($user->isFullAdmin()) {
            return $next($request);
        }

        $required = AdminPermissionMap::required($request);
        if ($required === null || $required === []) {
            return $next($request);
        }

        foreach ($required as $permission) {
            if ($user->canAdmin($permission)) {
                return $next($request);
            }
        }

        return ApiResponse::error('This action is unauthorized.', ErrorCode::FORBIDDEN, null, 403);
    }
}
