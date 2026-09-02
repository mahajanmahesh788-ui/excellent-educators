<?php

namespace App\Http\Middleware;

use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user === null || ! $user->isAdmin()) {
            return ApiResponse::error('This action is unauthorized.', ErrorCode::FORBIDDEN, null, 403);
        }

        return $next($request);
    }
}
