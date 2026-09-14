<?php

namespace App\Http\Controllers\Api\V1\Teacher;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\TeacherResource;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $teacher = $request->user()?->teacherProfile;
        if ($teacher === null) {
            return ApiResponse::error('Teacher profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $teacher->load([
            'user.roles',
            'activeBatchAssignments.batch',
        ])->loadCount(['activeBatchAssignments', 'activeMasterTeacherAssignments']);

        return ApiResponse::success('Profile fetched successfully.', TeacherResource::make($teacher)->resolve());
    }
}
