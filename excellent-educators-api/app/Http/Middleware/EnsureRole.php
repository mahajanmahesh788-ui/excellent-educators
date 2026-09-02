<?php

namespace App\Http\Middleware;

use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureRole
{
    public function handle(Request $request, Closure $next, string $role): Response
    {
        $user = $request->user();
        $roles = array_values(array_filter(array_map('trim', explode('|', $role))));

        if ($user === null || $roles === [] || ! $user->hasRole($roles)) {
            return ApiResponse::error('This action is unauthorized.', ErrorCode::FORBIDDEN, null, 403);
        }

        return $next($request);
    }
}
