<?php

namespace App\Http\Controllers\Api\V1\Teacher;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\AptitudeAssessmentResultResource;
use App\Models\AptitudeAssessmentResult;
use App\Models\MonthlyFeedback;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentResultController extends Controller
{
    public function show(Request $request, StudentProfile $student): JsonResponse
    {
        $this->authorize('viewAnyForStudent', [MonthlyFeedback::class, $student]);

        $teacher = $request->user()?->teacherProfile;
        if ($teacher === null) {
            return ApiResponse::error('Teacher profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $results = AptitudeAssessmentResult::query()
            ->where('student_id', $student->id)
            ->with(['dimensions', 'attempt.assessment', 'student'])
            ->orderByDesc('calculated_at')
            ->get();

        return ApiResponse::success(
            'Results fetched successfully.',
            $results->map(fn ($result) => (new AptitudeAssessmentResultResource($result))->resolve())->values()->all(),
        );
    }
}
