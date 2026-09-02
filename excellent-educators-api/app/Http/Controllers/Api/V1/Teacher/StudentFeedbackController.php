<?php

namespace App\Http\Controllers\Api\V1\Teacher;

use App\Actions\Feedback\BuildFeedbackSummary;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\MonthlyFeedbackResource;
use App\Models\MonthlyFeedback;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class StudentFeedbackController extends Controller
{
    public function index(StudentProfile $student): JsonResponse
    {
        $this->authorize('viewAnyForStudent', [MonthlyFeedback::class, $student]);

        $feedback = MonthlyFeedback::query()
            ->where('student_id', $student->id)
            ->with(['items', 'masterTeacher', 'student'])
            ->orderByDesc('session_date')
            ->orderByDesc('submitted_at')
            ->get();

        return ApiResponse::success(
            'Feedback fetched successfully.',
            MonthlyFeedbackResource::collection($feedback)->resolve(),
        );
    }

    public function summary(StudentProfile $student, BuildFeedbackSummary $buildFeedbackSummary): JsonResponse
    {
        $this->authorize('viewAnyForStudent', [MonthlyFeedback::class, $student]);

        return ApiResponse::success(
            'Feedback summary fetched successfully.',
            $buildFeedbackSummary->execute($student),
        );
    }
}
