<?php

namespace App\Http\Controllers\Api\V1\Student;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\StudentResource;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use App\Support\StudentPhotoStorage;
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

        return ApiResponse::success(
            'Profile fetched successfully.',
            StudentResource::make($this->loadProfile($student))->resolve(),
        );
    }

    public function storePhoto(Request $request): JsonResponse
    {
        $student = $request->user()?->studentProfile;
        if ($student === null) {
            return ApiResponse::error('Student profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $data = $request->validate([
            // 1024 KB = 1 MB hard cap after client-side shrink.
            'photo' => ['required', 'file', 'max:1024', 'mimes:jpg,jpeg,png,webp'],
        ]);

        $photoUrl = StudentPhotoStorage::store($data['photo'], $student);
        $student->update(['photo_url' => $photoUrl]);

        return ApiResponse::success(
            'Profile photo uploaded successfully.',
            [
                'photo_url' => StudentPhotoStorage::accessibleUrl($photoUrl),
                'student' => StudentResource::make($this->loadProfile($student->fresh()))->resolve(),
            ],
        );
    }

    private function loadProfile(StudentProfile $student): StudentProfile
    {
        $student->load([
            'user',
            'academicLevel.masterTeachers.user',
            'activeEnrollment.batch.level.masterTeachers.user',
            'activeEnrollment.batch.activeTeacherAssignment.teacher',
            'activeMasterTeacherAssignment.teacher',
            'currentLevelJourney',
        ]);
        $student->loadCount([
            'monthlyFeedbacks as feedback_total_sessions',
        ]);
        StudentProfile::attachOverallAverages([$student]);

        return $student;
    }
}
