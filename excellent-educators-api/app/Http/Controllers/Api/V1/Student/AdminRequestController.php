<?php

namespace App\Http\Controllers\Api\V1\Student;

use App\Actions\AdminRequests\CreateAdminRequest;
use App\Enums\AdminRequestRequesterType;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AdminRequests\StoreAdminRequestRequest;
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
            ->where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->get();

        return ApiResponse::success(
            'Requests fetched successfully.',
            AdminRequestResource::collection($requests)->resolve(),
        );
    }

    public function store(
        StoreAdminRequestRequest $request,
        CreateAdminRequest $createAdminRequest,
    ): JsonResponse {
        $adminRequest = $createAdminRequest->execute(
            $request->user(),
            AdminRequestRequesterType::Student,
            $request->validated(),
        );
        $adminRequest->load('user');

        return ApiResponse::success(
            'Request submitted successfully.',
            AdminRequestResource::make($adminRequest)->resolve(),
            status: 201,
        );
    }
}
