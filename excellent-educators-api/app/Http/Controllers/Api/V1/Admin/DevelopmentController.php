<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Audit\RecordAuditEvent;
use App\Actions\Feedback\BuildFeedbackSummary;
use App\Actions\Feedback\CreateMonthlyFeedback;
use App\Actions\Feedback\DeleteMonthlyFeedback;
use App\Actions\Feedback\UpdateMonthlyFeedback;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\MasterTeacher\StoreMonthlyFeedbackRequest;
use App\Http\Requests\Api\V1\MasterTeacher\UpdateMonthlyFeedbackRequest;
use App\Http\Resources\Api\V1\AptitudeAssessmentResultResource;
use App\Http\Resources\Api\V1\FeedbackCatalogResource;
use App\Http\Resources\Api\V1\MonthlyFeedbackResource;
use App\Models\AptitudeAssessment;
use App\Models\AptitudeAssessmentResult;
use App\Models\Dimension;
use App\Models\MonthlyFeedback;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;

class DevelopmentController extends Controller
{
    public function feedbackCatalog(): JsonResponse
    {
        $this->authorize('viewAny', AptitudeAssessment::class);

        $dimensions = Dimension::query()
            ->orderBy('display_order')
            ->get();

        return ApiResponse::success(
            'Feedback catalog fetched successfully.',
            FeedbackCatalogResource::collection($dimensions)->resolve(),
        );
    }

    public function studentResults(StudentProfile $student): JsonResponse
    {
        $this->authorize('viewAny', AptitudeAssessment::class);

        $results = AptitudeAssessmentResult::query()
            ->where('student_id', $student->id)
            ->with(['dimensions', 'attempt.assessment', 'student'])
            ->orderByDesc('calculated_at')
            ->get();

        return ApiResponse::success(
            'Results fetched successfully.',
            $results->map(fn ($result) => (new AptitudeAssessmentResultResource($result, true))->resolve())->values()->all(),
        );
    }

    public function studentFeedback(StudentProfile $student): JsonResponse
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

    public function studentFeedbackSummary(StudentProfile $student, BuildFeedbackSummary $buildFeedbackSummary): JsonResponse
    {
        $this->authorize('viewAnyForStudent', [MonthlyFeedback::class, $student]);

        return ApiResponse::success(
            'Feedback summary fetched successfully.',
            $buildFeedbackSummary->execute($student),
        );
    }

    public function storeStudentFeedback(
        StoreMonthlyFeedbackRequest $request,
        StudentProfile $student,
        CreateMonthlyFeedback $createMonthlyFeedback,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('create', [MonthlyFeedback::class, $student]);

        $bookingId = $request->validated('booking_id');
        $booking = $bookingId
            ? SessionBooking::query()->with('teacher')->find($bookingId)
            : null;
        $masterTeacher = $booking?->teacher ?? $student->activeMasterTeacherAssignment?->teacher;
        if ($masterTeacher === null) {
            return ApiResponse::error(
                'Choose a completed Master Class to rate.',
                ErrorCode::VALIDATION_ERROR,
                null,
                422,
            );
        }

        $feedback = $createMonthlyFeedback->execute($masterTeacher, $student, $request->validated());
        $recordAuditEvent->execute('feedback.created', $feedback, $request->user(), null, $feedback->toArray());

        return ApiResponse::success(
            'Feedback submitted successfully.',
            MonthlyFeedbackResource::make($feedback)->resolve(),
            status: 201,
        );
    }

    public function updateStudentFeedback(
        UpdateMonthlyFeedbackRequest $request,
        StudentProfile $student,
        MonthlyFeedback $feedback,
        UpdateMonthlyFeedback $updateMonthlyFeedback,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('update', $feedback);

        $student->loadMissing('activeMasterTeacherAssignment.teacher');
        $masterTeacher = $student->activeMasterTeacherAssignment?->teacher;
        if ($masterTeacher === null) {
            return ApiResponse::error('Master Teacher profile not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $old = $feedback->toArray();
        $feedback = $updateMonthlyFeedback->execute(
            $masterTeacher,
            $student,
            $feedback,
            $request->validated(),
            adminOverride: true,
        );
        $recordAuditEvent->execute('feedback.updated', $feedback, $request->user(), $old, $feedback->toArray());

        return ApiResponse::success(
            'Feedback updated successfully.',
            MonthlyFeedbackResource::make($feedback)->resolve(),
        );
    }

    public function destroyStudentFeedback(
        StudentProfile $student,
        MonthlyFeedback $feedback,
        DeleteMonthlyFeedback $deleteMonthlyFeedback,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('delete', $feedback);

        $old = $feedback->toArray();
        $deleteMonthlyFeedback->execute(null, $student, $feedback, adminOverride: true);
        $recordAuditEvent->execute('feedback.deleted', $feedback, request()->user(), $old, null);

        return ApiResponse::success('Feedback deleted successfully.');
    }
}
