<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Assessments\ActivateAptitudeAssessment;
use App\Actions\Assessments\CreateAptitudeAssessment;
use App\Actions\Assessments\DeactivateAptitudeAssessment;
use App\Actions\Assessments\DeleteAptitudeAssessment;
use App\Actions\Assessments\SyncOptionDimensionCodes;
use App\Actions\Assessments\UpdateAptitudeAssessment;
use App\Actions\Audit\RecordAuditEvent;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreAptitudeAssessmentRequest;
use App\Http\Requests\Api\V1\Admin\StoreAptitudeOptionRequest;
use App\Http\Requests\Api\V1\Admin\StoreAptitudeQuestionRequest;
use App\Http\Requests\Api\V1\Admin\UpdateAptitudeAssessmentRequest;
use App\Http\Resources\Api\V1\AptitudeAssessmentResource;
use App\Http\Resources\Api\V1\AptitudeAssessmentResultResource;
use App\Models\AptitudeAssessment;
use App\Models\AptitudeAssessmentOption;
use App\Models\AptitudeAssessmentQuestion;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AptitudeAssessmentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', AptitudeAssessment::class);

        $assessments = AptitudeAssessment::query()
            ->withCount(['questions', 'submittedAttempts as submitted_attempts_count'])
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->orderByDesc('created_at')
            ->paginate((int) $request->integer('per_page', 15));

        return ApiResponse::success(
            'Assessments fetched successfully.',
            AptitudeAssessmentResource::collection($assessments)->resolve(),
            [
                'page' => $assessments->currentPage(),
                'per_page' => $assessments->perPage(),
                'total' => $assessments->total(),
            ],
        );
    }

    public function store(
        StoreAptitudeAssessmentRequest $request,
        CreateAptitudeAssessment $createAptitudeAssessment,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('create', AptitudeAssessment::class);

        $assessment = $createAptitudeAssessment->execute($request->user(), $request->validated());
        $recordAuditEvent->execute('assessment.created', $assessment, $request->user(), null, $assessment->toArray());

        return ApiResponse::success(
            'Assessment created successfully.',
            (new AptitudeAssessmentResource($assessment))->resolve(),
            status: 201,
        );
    }

    public function show(AptitudeAssessment $aptitudeAssessment): JsonResponse
    {
        $this->authorize('view', $aptitudeAssessment);
        $aptitudeAssessment->load(['questions.options.dimensionCodes']);
        $aptitudeAssessment->loadCount('submittedAttempts');

        return ApiResponse::success(
            'Assessment fetched successfully.',
            (new AptitudeAssessmentResource($aptitudeAssessment))->resolve(),
        );
    }

    public function update(
        UpdateAptitudeAssessmentRequest $request,
        AptitudeAssessment $aptitudeAssessment,
        UpdateAptitudeAssessment $updateAptitudeAssessment,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('update', $aptitudeAssessment);

        $old = $aptitudeAssessment->toArray();
        $assessment = $updateAptitudeAssessment->execute($aptitudeAssessment, $request->user(), $request->validated());
        $recordAuditEvent->execute('assessment.updated', $assessment, $request->user(), $old, $assessment->toArray());

        return ApiResponse::success(
            'Assessment updated successfully.',
            (new AptitudeAssessmentResource($assessment))->resolve(),
        );
    }

    public function destroy(
        Request $request,
        AptitudeAssessment $aptitudeAssessment,
        DeleteAptitudeAssessment $deleteAptitudeAssessment,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('delete', $aptitudeAssessment);

        $old = $aptitudeAssessment->toArray();
        $deleteAptitudeAssessment->execute($aptitudeAssessment);
        $recordAuditEvent->execute('assessment.deleted', $aptitudeAssessment, $request->user(), $old, null);

        return ApiResponse::success('Assessment deleted successfully.');
    }

    public function activate(
        Request $request,
        AptitudeAssessment $aptitudeAssessment,
        ActivateAptitudeAssessment $activateAptitudeAssessment,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('activate', $aptitudeAssessment);

        $old = ['status' => $aptitudeAssessment->status?->value];
        $assessment = $activateAptitudeAssessment->execute($aptitudeAssessment, $request->user());
        $recordAuditEvent->execute('assessment.activated', $assessment, $request->user(), $old, ['status' => $assessment->status?->value]);

        return ApiResponse::success(
            'Assessment activated successfully.',
            (new AptitudeAssessmentResource($assessment))->resolve(),
        );
    }

    public function deactivate(
        Request $request,
        AptitudeAssessment $aptitudeAssessment,
        DeactivateAptitudeAssessment $deactivateAptitudeAssessment,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('activate', $aptitudeAssessment);

        $old = ['status' => $aptitudeAssessment->status?->value];
        $assessment = $deactivateAptitudeAssessment->execute($aptitudeAssessment, $request->user());
        $recordAuditEvent->execute('assessment.deactivated', $assessment, $request->user(), $old, ['status' => $assessment->status?->value]);

        return ApiResponse::success(
            'Assessment deactivated successfully.',
            (new AptitudeAssessmentResource($assessment))->resolve(),
        );
    }

    public function storeQuestion(
        StoreAptitudeQuestionRequest $request,
        AptitudeAssessment $aptitudeAssessment,
        RecordAuditEvent $recordAuditEvent,
        SyncOptionDimensionCodes $syncOptionDimensionCodes,
    ): JsonResponse {
        $this->authorize('update', $aptitudeAssessment);
        $this->assertUnlocked($aptitudeAssessment);

        $question = $aptitudeAssessment->questions()->create([
            'question_text' => $request->validated('question_text'),
            'display_order' => $request->validated('display_order') ?? ($aptitudeAssessment->questions()->count() + 1),
        ]);

        foreach (array_values($request->validated('options')) as $index => $option) {
            $created = $question->options()->create([
                'option_text' => $option['option_text'],
                'display_order' => $option['display_order'] ?? ($index + 1),
            ]);
            $syncOptionDimensionCodes->execute($created, $option['dimension_codes']);
        }

        $aptitudeAssessment->refresh()->load(['questions.options.dimensionCodes']);
        $recordAuditEvent->execute('assessment.updated', $aptitudeAssessment, $request->user());

        return ApiResponse::success(
            'Question added successfully.',
            (new AptitudeAssessmentResource($aptitudeAssessment))->resolve(),
            status: 201,
        );
    }

    public function updateQuestion(
        StoreAptitudeQuestionRequest $request,
        AptitudeAssessment $aptitudeAssessment,
        AptitudeAssessmentQuestion $question,
        RecordAuditEvent $recordAuditEvent,
        SyncOptionDimensionCodes $syncOptionDimensionCodes,
    ): JsonResponse {
        $this->authorize('update', $aptitudeAssessment);
        $this->assertQuestionBelongs($aptitudeAssessment, $question);
        $this->assertUnlocked($aptitudeAssessment);

        $question->update([
            'question_text' => $request->validated('question_text'),
            'display_order' => $request->validated('display_order') ?? $question->display_order,
        ]);

        $question->options()->delete();
        foreach (array_values($request->validated('options')) as $index => $option) {
            $created = $question->options()->create([
                'option_text' => $option['option_text'],
                'display_order' => $option['display_order'] ?? ($index + 1),
            ]);
            $syncOptionDimensionCodes->execute($created, $option['dimension_codes']);
        }

        $aptitudeAssessment->refresh()->load(['questions.options.dimensionCodes']);
        $recordAuditEvent->execute('assessment.updated', $aptitudeAssessment, $request->user());

        return ApiResponse::success(
            'Question updated successfully.',
            (new AptitudeAssessmentResource($aptitudeAssessment))->resolve(),
        );
    }

    public function destroyQuestion(
        Request $request,
        AptitudeAssessment $aptitudeAssessment,
        AptitudeAssessmentQuestion $question,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('update', $aptitudeAssessment);
        $this->assertQuestionBelongs($aptitudeAssessment, $question);
        $this->assertUnlocked($aptitudeAssessment);

        $question->options()->delete();
        $question->delete();

        $aptitudeAssessment->refresh()->load(['questions.options.dimensionCodes']);
        $recordAuditEvent->execute('assessment.updated', $aptitudeAssessment, $request->user());

        return ApiResponse::success(
            'Question deleted successfully.',
            (new AptitudeAssessmentResource($aptitudeAssessment))->resolve(),
        );
    }

    public function storeOption(
        StoreAptitudeOptionRequest $request,
        AptitudeAssessment $aptitudeAssessment,
        AptitudeAssessmentQuestion $question,
        RecordAuditEvent $recordAuditEvent,
        SyncOptionDimensionCodes $syncOptionDimensionCodes,
    ): JsonResponse {
        $this->authorize('update', $aptitudeAssessment);
        $this->assertQuestionBelongs($aptitudeAssessment, $question);
        $this->assertUnlocked($aptitudeAssessment);

        $option = $question->options()->create([
            'option_text' => $request->validated('option_text'),
            'display_order' => $request->validated('display_order') ?? ($question->options()->count()),
        ]);
        $syncOptionDimensionCodes->execute($option, $request->validated('dimension_codes'));

        $aptitudeAssessment->refresh()->load(['questions.options.dimensionCodes']);
        $recordAuditEvent->execute('assessment.updated', $aptitudeAssessment, $request->user());

        return ApiResponse::success(
            'Option added successfully.',
            (new AptitudeAssessmentResource($aptitudeAssessment))->resolve(),
            status: 201,
        );
    }

    public function updateOption(
        StoreAptitudeOptionRequest $request,
        AptitudeAssessment $aptitudeAssessment,
        AptitudeAssessmentOption $option,
        RecordAuditEvent $recordAuditEvent,
        SyncOptionDimensionCodes $syncOptionDimensionCodes,
    ): JsonResponse {
        $this->authorize('update', $aptitudeAssessment);
        $this->assertOptionBelongs($aptitudeAssessment, $option);
        $this->assertUnlocked($aptitudeAssessment);

        $option->update([
            'option_text' => $request->validated('option_text'),
            'display_order' => $request->validated('display_order') ?? $option->display_order,
        ]);
        $syncOptionDimensionCodes->execute($option, $request->validated('dimension_codes'));
        $aptitudeAssessment->refresh()->load(['questions.options.dimensionCodes']);
        $recordAuditEvent->execute('assessment.updated', $aptitudeAssessment, $request->user());

        return ApiResponse::success(
            'Option updated successfully.',
            (new AptitudeAssessmentResource($aptitudeAssessment))->resolve(),
        );
    }

    public function destroyOption(
        Request $request,
        AptitudeAssessment $aptitudeAssessment,
        AptitudeAssessmentOption $option,
        RecordAuditEvent $recordAuditEvent,
    ): JsonResponse {
        $this->authorize('update', $aptitudeAssessment);
        $this->assertOptionBelongs($aptitudeAssessment, $option);
        $this->assertUnlocked($aptitudeAssessment);

        $option->delete();
        $aptitudeAssessment->refresh()->load(['questions.options.dimensionCodes']);
        $recordAuditEvent->execute('assessment.updated', $aptitudeAssessment, $request->user());

        return ApiResponse::success(
            'Option deleted successfully.',
            (new AptitudeAssessmentResource($aptitudeAssessment))->resolve(),
        );
    }

    public function attempts(AptitudeAssessment $aptitudeAssessment): JsonResponse
    {
        $this->authorize('viewAttempts', $aptitudeAssessment);

        $results = $aptitudeAssessment->submittedAttempts()
            ->with(['result.dimensions', 'result.student'])
            ->get()
            ->map(fn ($attempt) => $attempt->result)
            ->filter();

        return ApiResponse::success(
            'Assessment attempts fetched successfully.',
            $results->map(fn ($result) => (new AptitudeAssessmentResultResource($result, true))->resolve())->values()->all(),
        );
    }

    private function assertUnlocked(AptitudeAssessment $assessment): void
    {
        if ($assessment->hasSubmittedAttempts()) {
            throw new ApiException(
                ErrorCode::ASSESSMENT_LOCKED,
                'Questions cannot be changed after a student has submitted this assessment.',
                409,
            );
        }
    }

    private function assertQuestionBelongs(AptitudeAssessment $assessment, AptitudeAssessmentQuestion $question): void
    {
        if ($question->aptitude_assessment_id !== $assessment->id) {
            throw new ApiException(ErrorCode::NOT_FOUND, 'Question not found for this assessment.', 404);
        }
    }

    private function assertOptionBelongs(AptitudeAssessment $assessment, AptitudeAssessmentOption $option): void
    {
        $option->loadMissing('question');
        if ($option->question?->aptitude_assessment_id !== $assessment->id) {
            throw new ApiException(ErrorCode::NOT_FOUND, 'Option not found for this assessment.', 404);
        }
    }
}
