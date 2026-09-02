<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\CareerCompassLevelResource;
use App\Models\CareerCompassLevel;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class CareerCompassLevelController extends Controller
{
    public function index(): JsonResponse
    {
        $levels = CareerCompassLevel::query()->orderBy('code')->get();

        return ApiResponse::success(
            'Career Compass levels fetched successfully.',
            CareerCompassLevelResource::collection($levels)->resolve(),
        );
    }
}
