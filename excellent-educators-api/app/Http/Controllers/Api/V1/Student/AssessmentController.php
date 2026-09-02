<?php

namespace App\Http\Controllers\Api\V1\Student;

use App\Actions\Assessments\GetApplicableStudentAssessment;
use App\Actions\Assessments\SubmitStudentAssessment;
use App\Actions\Audit\RecordAuditEvent;
use App\Actions\Feedback\BuildFeedbackSummary;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Student\SubmitAptitudeAssessmentRequest;
use App\Http\Resources\Api\V1\AptitudeAssessmentResource;
use App\Http\Resources\Api\V1\MonthlyFeedbackResource;
use App\Models\AptitudeAssessment;
use App\Models\MonthlyFeedback;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AssessmentController extends Controller
{
    public function show(Request $request, GetApplicableStudentAssessment $getApplicable): JsonResponse
    {
        $student = $request->user()?->studentProfile;
        if ($student === null) {
            return ApiResponse::error('Student profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $assessment = $getApplicable->execute($student);
        if ($assessment === null) {
            $reason = $getApplicable->completedExists($student) ? 'already_completed' : 'none_available';

            return ApiResponse::success('No assessment is currently available.', [
                'available' => false,
                'reason' => $reason,
                'assessment' => null,
            ]);
        }

        return ApiResponse::success('Assessment fetched successfully.', [
            'available' => true,
            'reason' => null,
            'assessment' => (new AptitudeAssessmentResource($assessment, false))->resolve(),
        ]);
    }

    public function submit(
        SubmitAptitudeAssessmentRequest $request,
        AptitudeAssessment $aptitudeAssessment,
        SubmitStudentAssessment $submitStudentAssessment,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $student = $request->user()?->studentProfile;
        if ($student === null) {
            return ApiResponse::error('Student profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $result = $submitStudentAssessment->execute(
            $student,
            $aptitudeAssessment,
            $request->validated('answers'),
        );

        $recordAuditEvent->execute(
            'assessment.submitted',
            $result->attempt ?? $aptitudeAssessment,
            $request->user(),
            null,
            ['assessment_id' => $aptitudeAssessment->id, 'result_id' => $result->id],
        );

        return ApiResponse::success(
            'Assessment submitted successfully.',
            [
                'id' => $result->id,
                'submitted_at' => $result->calculated_at?->toIso8601String(),
            ],
            status: 201,
        );
    }

    public function results(Request $request): JsonResponse
    {
        return ApiResponse::error(
            'Assessment results are available to your teachers only.',
            ErrorCode::FORBIDDEN,
            null,
            403,
        );
    }

    public function feedback(Request $request): JsonResponse
    {
        $student = $request->user()?->studentProfile;
        if ($student === null) {
            return ApiResponse::error('Student profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

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

    public function feedbackSummary(Request $request, BuildFeedbackSummary $buildFeedbackSummary): JsonResponse
    {
        $student = $request->user()?->studentProfile;
        if ($student === null) {
            return ApiResponse::error('Student profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $this->authorize('viewAnyForStudent', [MonthlyFeedback::class, $student]);

        return ApiResponse::success(
            'Feedback summary fetched successfully.',
            $buildFeedbackSummary->execute($student),
        );
    }
}
