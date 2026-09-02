<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\AdminRequests\ResolveAdminRequest;
use App\Http\Requests\Api\V1\AdminRequests\ResolveAdminRequestRequest;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\AdminRequestResource;
use App\Models\AdminRequest;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminRequestController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $requests = AdminRequest::query()
            ->with(['user.studentProfile', 'user.teacherProfile', 'resolvedBy', 'student', 'batch'])
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->when($request->string('search')->toString(), function ($query, string $search): void {
                $query->where(function ($inner) use ($search): void {
                    $inner->where('subtitle', 'like', "%{$search}%")
                        ->orWhere('description', 'like', "%{$search}%")
                        ->orWhereHas('user', fn ($user) => $user
                            ->where('name', 'like', "%{$search}%")
                            ->orWhere('email', 'like', "%{$search}%"));
                });
            })
            ->orderByRaw("CASE WHEN status = 'pending' THEN 0 ELSE 1 END")
            ->orderByDesc('created_at')
            ->paginate((int) $request->integer('per_page', 15));

        return ApiResponse::success(
            'Requests fetched successfully.',
            AdminRequestResource::collection($requests)->resolve(),
            [
                'page' => $requests->currentPage(),
                'per_page' => $requests->perPage(),
                'total' => $requests->total(),
            ],
        );
    }

    public function show(AdminRequest $adminRequest): JsonResponse
    {
        $adminRequest->load(['user.studentProfile', 'user.teacherProfile', 'resolvedBy', 'student', 'batch']);

        return ApiResponse::success(
            'Request fetched successfully.',
            AdminRequestResource::make($adminRequest)->resolve(),
        );
    }

    public function resolve(
        ResolveAdminRequestRequest $request,
        AdminRequest $adminRequest,
        ResolveAdminRequest $resolveAdminRequest,
    ): JsonResponse {
        $adminRequest = $resolveAdminRequest->execute(
            $adminRequest,
            $request->user(),
            $request->boolean('apply_action', true),
        );

        $message = $adminRequest->request_type?->value !== 'general' && $request->boolean('apply_action', true)
            ? 'Request approved and action completed.'
            : 'Request marked as resolved.';

        return ApiResponse::success(
            $message,
            AdminRequestResource::make($adminRequest)->resolve(),
        );
    }
}
