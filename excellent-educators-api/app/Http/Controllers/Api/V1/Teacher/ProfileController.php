<?php

namespace App\Http\Controllers\Api\V1\Teacher;

use App\Actions\Teachers\UpdateTeacher;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Teacher\UpdateMentorProfileRequest;
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
            'academicLevels',
        ])->loadCount(['activeBatchAssignments', 'activeMasterTeacherAssignments']);

        return ApiResponse::success('Profile fetched successfully.', TeacherResource::make($teacher)->resolve());
    }

    public function update(UpdateMentorProfileRequest $request, UpdateTeacher $updateTeacher): JsonResponse
    {
        $teacher = $request->user()?->teacherProfile;
        if ($teacher === null) {
            return ApiResponse::error('Teacher profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $teacher = $updateTeacher->execute($teacher, $request->validated());
        $teacher->load([
            'user.roles',
            'activeBatchAssignments.batch',
            'academicLevels',
        ])->loadCount(['activeBatchAssignments', 'activeMasterTeacherAssignments']);

        return ApiResponse::success('Professional profile updated successfully.', TeacherResource::make($teacher)->resolve());
    }
}
