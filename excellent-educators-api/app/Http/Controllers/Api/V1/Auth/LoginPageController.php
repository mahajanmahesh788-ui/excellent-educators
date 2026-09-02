<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\LoginPageContentResource;
use App\Models\LoginPageContent;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class LoginPageController extends Controller
{
    public function show(): JsonResponse
    {
        return ApiResponse::success(
            'Login page content retrieved successfully.',
            LoginPageContentResource::make(LoginPageContent::current())->resolve(),
        );
    }
}
