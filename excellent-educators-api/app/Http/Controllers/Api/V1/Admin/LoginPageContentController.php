<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Content\UpdateLoginPageContent;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\UpdateLoginPageContentRequest;
use App\Http\Resources\Api\V1\LoginPageContentResource;
use App\Models\LoginPageContent;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class LoginPageContentController extends Controller
{
    public function show(): JsonResponse
    {
        return ApiResponse::success(
            'Login page content retrieved successfully.',
            LoginPageContentResource::make(LoginPageContent::current())->resolve(),
        );
    }

    public function update(UpdateLoginPageContentRequest $request, UpdateLoginPageContent $updateLoginPageContent): JsonResponse
    {
        $content = $updateLoginPageContent->execute($request->validated());

        return ApiResponse::success(
            'Login page content updated successfully.',
            LoginPageContentResource::make($content)->resolve(),
        );
    }
}
