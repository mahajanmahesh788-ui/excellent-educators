<?php

use App\Exceptions\ApiException;
use App\Http\Middleware\AssignRequestId;
use App\Http\Middleware\EnsureAdmin;
use App\Http\Middleware\EnsureAdminPermission;
use App\Http\Middleware\EnsureRole;
use App\Http\Middleware\RecordSubAdminActivity;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Spatie\Permission\Middleware\PermissionMiddleware;
use Spatie\Permission\Middleware\RoleOrPermissionMiddleware;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        apiPrefix: 'api/v1',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->api(prepend: [
            AssignRequestId::class,
        ]);

        $middleware->alias([
            'role' => EnsureRole::class,
            'permission' => PermissionMiddleware::class,
            'role_or_permission' => RoleOrPermissionMiddleware::class,
            'admin' => EnsureAdmin::class,
            'admin.permission' => EnsureAdminPermission::class,
            'subadmin.activity' => RecordSubAdminActivity::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        $exceptions->render(function (Throwable $e, Request $request) {
            if (! $request->is('api/*') && ! $request->expectsJson()) {
                return null;
            }

            if ($e instanceof ApiException) {
                return ApiResponse::error($e->getMessage(), $e->errorCode, $e->details, $e->getStatusCode());
            }

            if ($e instanceof ValidationException) {
                return ApiResponse::error(
                    'Validation failed.',
                    ErrorCode::VALIDATION_ERROR,
                    $e->errors(),
                    422,
                );
            }

            if ($e instanceof AuthenticationException) {
                return ApiResponse::error(
                    'Unauthenticated.',
                    ErrorCode::UNAUTHENTICATED,
                    null,
                    401,
                );
            }

            if ($e instanceof AuthorizationException) {
                return ApiResponse::error(
                    'This action is unauthorized.',
                    ErrorCode::FORBIDDEN,
                    null,
                    403,
                );
            }

            if ($e instanceof ModelNotFoundException || $e instanceof NotFoundHttpException) {
                return ApiResponse::error(
                    'The requested resource was not found.',
                    ErrorCode::NOT_FOUND,
                    null,
                    404,
                );
            }

            if ($e instanceof TooManyRequestsHttpException) {
                return ApiResponse::error(
                    'Too many attempts. Please try again later.',
                    ErrorCode::TOO_MANY_REQUESTS,
                    null,
                    429,
                );
            }

            if ($e instanceof HttpExceptionInterface) {
                $status = $e->getStatusCode();
                $code = match (true) {
                    $status === 401 => ErrorCode::UNAUTHENTICATED,
                    $status === 403 => ErrorCode::FORBIDDEN,
                    $status === 404 => ErrorCode::NOT_FOUND,
                    $status === 409 => ErrorCode::CONFLICT,
                    $status === 429 => ErrorCode::TOO_MANY_REQUESTS,
                    default => ErrorCode::SERVER_ERROR,
                };

                $message = $e->getMessage() !== '' ? $e->getMessage() : 'HTTP error.';

                return ApiResponse::error($message, $code, null, $status);
            }

            $message = config('app.debug') ? $e->getMessage() : 'An unexpected error occurred.';

            return ApiResponse::error($message, ErrorCode::SERVER_ERROR, null, 500);
        });
    })->create();
