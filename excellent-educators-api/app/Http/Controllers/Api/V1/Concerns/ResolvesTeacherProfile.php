<?php

namespace App\Http\Controllers\Api\V1\Concerns;

use App\Exceptions\ApiException;
use App\Models\TeacherProfile;
use App\Models\StudentProfile;
use App\Support\ErrorCode;
use Illuminate\Http\Request;

trait ResolvesTeacherProfile
{
    protected function teacherFrom(Request $request): TeacherProfile
    {
        $teacher = $request->user()?->teacherProfile;
        if ($teacher === null) {
            throw new ApiException(ErrorCode::NOT_FOUND, 'Teacher profile not found.', 404);
        }

        return $teacher;
    }

    protected function studentFrom(Request $request): StudentProfile
    {
        $student = $request->user()?->studentProfile;
        if ($student === null) {
            throw new ApiException(ErrorCode::NOT_FOUND, 'Student profile not found.', 404);
        }

        return $student;
    }
}
