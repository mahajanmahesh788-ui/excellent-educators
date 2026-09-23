<?php

namespace App\Http\Controllers\Api\V1\Student;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\StudentResource;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $student = $request->user()?->studentProfile;
        if ($student === null) {
            return ApiResponse::error('Student profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $student->load([
            'user',
            'academicLevel.masterTeachers.user',
            'activeEnrollment.batch.level.masterTeachers.user',
            'activeEnrollment.batch.activeTeacherAssignment.teacher',
            'activeMasterTeacherAssignment.teacher',
        ]);
        $student->loadCount([
            'monthlyFeedbacks as feedback_total_sessions',
        ]);
        StudentProfile::attachOverallAverages([$student]);

        return ApiResponse::success('Profile fetched successfully.', StudentResource::make($student)->resolve());
    }
}
