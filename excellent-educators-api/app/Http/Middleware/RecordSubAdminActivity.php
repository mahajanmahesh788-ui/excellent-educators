<?php

namespace App\Http\Middleware;

use App\Support\AdminActivity;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class RecordSubAdminActivity
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        if ($response->getStatusCode() >= 200 && $response->getStatusCode() < 300) {
            try {
                AdminActivity::fromRequest($request);
            } catch (Throwable) {
                // Activity logging must not break the request.
            }
        }

        return $response;
    }
}
