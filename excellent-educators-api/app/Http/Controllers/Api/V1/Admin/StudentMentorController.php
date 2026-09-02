<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Mentoring\AssignMasterTeacher;
use App\Actions\Mentoring\UnassignMasterTeacher;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\AssignMasterTeacherRequest;
use App\Http\Resources\Api\V1\StudentResource;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class StudentMentorController extends Controller
{
    public function update(
        AssignMasterTeacherRequest $request,
        StudentProfile $student,
        AssignMasterTeacher $assignMasterTeacher,
    ): JsonResponse {
        $teacher = TeacherProfile::query()->findOrFail($request->string('teacher_id'));
        $assignMasterTeacher->execute($student, $teacher, $request->user());
        $student->load([
            'user',
            'careerCompassLevel',
            'activeEnrollment.batch.activeTeacherAssignment.teacher',
            'activeMasterTeacherAssignment.teacher',
        ]);

        return ApiResponse::success(
            'Master Teacher assigned successfully.',
            StudentResource::make($student)->resolve(),
        );
    }

    public function destroy(StudentProfile $student, UnassignMasterTeacher $unassignMasterTeacher): JsonResponse
    {
        $unassignMasterTeacher->execute($student);
        $student->load([
            'user',
            'careerCompassLevel',
            'activeEnrollment.batch.activeTeacherAssignment.teacher',
            'activeMasterTeacherAssignment.teacher',
        ]);

        return ApiResponse::success(
            'Master Teacher removed successfully.',
            StudentResource::make($student)->resolve(),
        );
    }
}
