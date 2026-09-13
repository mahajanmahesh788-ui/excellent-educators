<?php

namespace App\Http\Controllers\Api\V1\MasterTeacher;

use App\Actions\Audit\RecordAuditEvent;
use App\Actions\Feedback\BuildFeedbackSummary;
use App\Actions\Feedback\CreateMonthlyFeedback;
use App\Actions\Feedback\DeleteMonthlyFeedback;
use App\Actions\Feedback\UpdateMonthlyFeedback;
use App\Feedback\StudentsDueForRating;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\MasterTeacher\StoreMonthlyFeedbackRequest;
use App\Http\Requests\Api\V1\MasterTeacher\UpdateMonthlyFeedbackRequest;
use App\Http\Resources\Api\V1\AptitudeAssessmentResultResource;
use App\Http\Resources\Api\V1\FeedbackCatalogResource;
use App\Http\Resources\Api\V1\MonthlyFeedbackResource;
use App\Models\AptitudeAssessmentResult;
use App\Models\Dimension;
use App\Models\MonthlyFeedback;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use App\Support\AppClock;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class FeedbackController extends Controller
{
    public function catalog(): JsonResponse
    {
        $dimensions = Dimension::query()
            ->with(['modules.skills'])
            ->orderBy('display_order')
            ->get();

        return ApiResponse::success(
            'Feedback catalog fetched successfully.',
            FeedbackCatalogResource::collection($dimensions)->resolve(),
        );
    }

    public function index(Request $request, StudentProfile $student): JsonResponse
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

    public function store(
        StoreMonthlyFeedbackRequest $request,
        StudentProfile $student,
        CreateMonthlyFeedback $createMonthlyFeedback,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('create', [MonthlyFeedback::class, $student]);

        $teacher = $request->user()?->teacherProfile;
        if ($teacher === null) {
            return ApiResponse::error('Teacher profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $sessionDate = Carbon::parse(
            $request->validated('session_date') ?? AppClock::todayString(),
            config('app.timezone'),
        )->startOfDay();
        $dueIds = app(StudentsDueForRating::class)->idsFor($teacher, $sessionDate->year, $sessionDate->month);
        if (! $dueIds->contains($student->id)) {
            return ApiResponse::error(
                'Add a monthly rating only after this student completes a Master Class.',
                ErrorCode::FEEDBACK_NOT_DUE,
                null,
                409,
            );
        }

        $feedback = $createMonthlyFeedback->execute($teacher, $student, $request->validated());
        $recordAuditEvent->execute('feedback.created', $feedback, $request->user(), null, $feedback->toArray());

        return ApiResponse::success(
            'Feedback submitted successfully.',
            MonthlyFeedbackResource::make($feedback)->resolve(),
            status: 201,
        );
    }

    public function update(
        UpdateMonthlyFeedbackRequest $request,
        StudentProfile $student,
        MonthlyFeedback $feedback,
        UpdateMonthlyFeedback $updateMonthlyFeedback,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('update', $feedback);

        $teacher = $request->user()?->teacherProfile;
        if ($teacher === null) {
            return ApiResponse::error('Teacher profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $old = $feedback->toArray();
        $feedback = $updateMonthlyFeedback->execute($teacher, $student, $feedback, $request->validated());
        $recordAuditEvent->execute('feedback.updated', $feedback, $request->user(), $old, $feedback->toArray());

        return ApiResponse::success(
            'Feedback updated successfully.',
            MonthlyFeedbackResource::make($feedback)->resolve(),
        );
    }

    public function destroy(
        Request $request,
        StudentProfile $student,
        MonthlyFeedback $feedback,
        DeleteMonthlyFeedback $deleteMonthlyFeedback,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('delete', $feedback);

        $teacher = $request->user()?->teacherProfile;
        if ($teacher === null) {
            return ApiResponse::error('Teacher profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $old = $feedback->toArray();
        $deleteMonthlyFeedback->execute($teacher, $student, $feedback);
        $recordAuditEvent->execute('feedback.deleted', $feedback, $request->user(), $old, null);

        return ApiResponse::success('Feedback deleted successfully.');
    }

    public function results(Request $request, StudentProfile $student): JsonResponse
    {
        $this->authorize('viewAnyForStudent', [MonthlyFeedback::class, $student]);

        $results = AptitudeAssessmentResult::query()
            ->where('student_id', $student->id)
            ->with(['dimensions', 'attempt.assessment.careerCompassLevel', 'student'])
            ->orderByDesc('calculated_at')
            ->get();

        return ApiResponse::success(
            'Results fetched successfully.',
            $results->map(fn ($result) => (new AptitudeAssessmentResultResource($result))->resolve())->values()->all(),
        );
    }
}
