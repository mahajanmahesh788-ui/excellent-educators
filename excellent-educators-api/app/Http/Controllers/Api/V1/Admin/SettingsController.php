<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\UpdateAppSettingsRequest;
use App\Support\ApiResponse;
use App\Support\AppSettings;
use Illuminate\Http\JsonResponse;

class SettingsController extends Controller
{
    public function show(AppSettings $settings): JsonResponse
    {
        return ApiResponse::success('Settings fetched successfully.', $settings->payload());
    }

    public function update(UpdateAppSettingsRequest $request, AppSettings $settings): JsonResponse
    {
        $data = $settings->update($request->validated(), $request->user()?->id);

        return ApiResponse::success('Settings saved successfully.', $data);
    }
}
