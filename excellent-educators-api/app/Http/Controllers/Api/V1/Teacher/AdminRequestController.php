<?php

namespace App\Http\Controllers\Api\V1\Teacher;

use App\Actions\AdminRequests\CreateTeacherAdminRequest;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AdminRequests\StoreTeacherAdminRequestRequest;
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
            ->with(['student', 'batch'])
            ->where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->get();

        return ApiResponse::success(
            'Requests fetched successfully.',
            AdminRequestResource::collection($requests)->resolve(),
        );
    }

    public function store(
        StoreTeacherAdminRequestRequest $request,
        CreateTeacherAdminRequest $createTeacherAdminRequest,
    ): JsonResponse {
        $adminRequest = $createTeacherAdminRequest->execute(
            $request->user(),
            $request->validated(),
        );
        $adminRequest->load(['user', 'student', 'batch']);

        return ApiResponse::success(
            'Request submitted successfully.',
            AdminRequestResource::make($adminRequest)->resolve(),
            status: 201,
        );
    }
}
