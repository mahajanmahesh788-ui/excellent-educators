<?php

namespace App\Http\Controllers\Api\V1\MasterTeacher;

use App\Actions\Feedback\BuildMasterTeacherDashboard;
use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function show(Request $request, BuildMasterTeacherDashboard $buildMasterTeacherDashboard): JsonResponse
    {
        $teacher = $request->user()?->teacherProfile;
        if ($teacher === null) {
            return ApiResponse::error('This action is unauthorized.', 'FORBIDDEN', null, 403);
        }

        return ApiResponse::success(
            'Master teacher dashboard fetched successfully.',
            $buildMasterTeacherDashboard->execute($teacher),
        );
    }
}
