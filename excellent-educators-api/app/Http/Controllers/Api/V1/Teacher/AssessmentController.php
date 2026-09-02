<?php

namespace App\Http\Controllers\Api\V1\Teacher;

use App\Actions\Assessments\CreateAssessment;
use App\Actions\Assessments\RecordAssessmentScores;
use App\Actions\Assessments\UpdateAssessment;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Teacher\RecordAssessmentScoresRequest;
use App\Http\Requests\Api\V1\Teacher\StoreAssessmentRequest;
use App\Http\Requests\Api\V1\Teacher\UpdateAssessmentRequest;
use App\Http\Resources\Api\V1\AssessmentResource;
use App\Http\Resources\Api\V1\AssessmentScoreResource;
use App\Models\Assessment;
use App\Models\Batch;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AssessmentController extends Controller
{
    public function index(Request $request, Batch $batch): JsonResponse
    {
        if (! $this->teacherAssignedToBatch($request, $batch)) {
            return ApiResponse::error('This action is unauthorized.', 'FORBIDDEN', null, 403);
        }

        $assessments = Assessment::query()
            ->where('batch_id', $batch->id)
            ->withCount([
                'scores as scored_count' => function ($query): void {
                    $query->whereNotNull('score')
                        ->whereColumn('assessment_scores.version', 'assessments.version');
                },
            ])
            ->orderByDesc('created_at')
            ->get();

        return ApiResponse::success(
            'Assessments fetched successfully.',
            AssessmentResource::collection($assessments)->resolve(),
        );
    }

    public function store(
        StoreAssessmentRequest $request,
        Batch $batch,
        CreateAssessment $createAssessment,
    ): JsonResponse {
        if (! $this->teacherAssignedToBatch($request, $batch)) {
            return ApiResponse::error('This action is unauthorized.', 'FORBIDDEN', null, 403);
        }

        $assessment = $createAssessment->execute($batch, $request->user(), $request->validated());
        $assessment->loadCount([
            'scores as scored_count' => function ($query): void {
                $query->whereNotNull('score')
                    ->whereColumn('assessment_scores.version', 'assessments.version');
            },
        ]);

        return ApiResponse::success(
            'Assessment created successfully.',
            AssessmentResource::make($assessment)->resolve(),
            status: 201,
        );
    }

    public function show(Request $request, Batch $batch, Assessment $assessment): JsonResponse
    {
        if (! $this->teacherAssignedToBatch($request, $batch) || $assessment->batch_id !== $batch->id) {
            return ApiResponse::error('This action is unauthorized.', 'FORBIDDEN', null, 403);
        }

        $assessment->loadCount([
            'scores as scored_count' => function ($query): void {
                $query->whereNotNull('score')
                    ->whereColumn('assessment_scores.version', 'assessments.version');
            },
        ]);

        return ApiResponse::success(
            'Assessment fetched successfully.',
            AssessmentResource::make($assessment)->resolve(),
        );
    }

    public function update(
        UpdateAssessmentRequest $request,
        Batch $batch,
        Assessment $assessment,
        UpdateAssessment $updateAssessment,
    ): JsonResponse {
        if (! $this->teacherAssignedToBatch($request, $batch) || $assessment->batch_id !== $batch->id) {
            return ApiResponse::error('This action is unauthorized.', 'FORBIDDEN', null, 403);
        }

        $assessment = $updateAssessment->execute($assessment, $request->user(), $request->validated());
        $assessment->loadCount([
            'scores as scored_count' => function ($query): void {
                $query->whereNotNull('score')
                    ->whereColumn('assessment_scores.version', 'assessments.version');
            },
        ]);

        return ApiResponse::success(
            'Assessment updated successfully.',
            AssessmentResource::make($assessment)->resolve(),
        );
    }

    public function scores(Request $request, Batch $batch, Assessment $assessment): JsonResponse
    {
        if (! $this->teacherAssignedToBatch($request, $batch) || $assessment->batch_id !== $batch->id) {
            return ApiResponse::error('This action is unauthorized.', 'FORBIDDEN', null, 403);
        }

        $version = (int) $request->integer('version', $assessment->version);
        $scores = $assessment->scores()
            ->where('version', $version)
            ->with('student')
            ->get();

        return ApiResponse::success(
            'Assessment scores fetched successfully.',
            AssessmentScoreResource::collection($scores)->resolve(),
            ['version' => $version, 'current_version' => $assessment->version],
        );
    }

    public function recordScores(
        RecordAssessmentScoresRequest $request,
        Batch $batch,
        Assessment $assessment,
        RecordAssessmentScores $recordAssessmentScores,
    ): JsonResponse {
        if (! $this->teacherAssignedToBatch($request, $batch) || $assessment->batch_id !== $batch->id) {
            return ApiResponse::error('This action is unauthorized.', 'FORBIDDEN', null, 403);
        }

        $assessment = $recordAssessmentScores->execute(
            $assessment,
            $batch,
            $request->user(),
            $request->validated('scores'),
        );

        $scores = $assessment->scores()
            ->where('version', $assessment->version)
            ->with('student')
            ->get();
        $assessment->loadCount([
            'scores as scored_count' => function ($query): void {
                $query->whereNotNull('score')
                    ->whereColumn('assessment_scores.version', 'assessments.version');
            },
        ]);

        return ApiResponse::success(
            'Scores recorded successfully.',
            [
                'assessment' => AssessmentResource::make($assessment)->resolve(),
                'scores' => AssessmentScoreResource::collection($scores)->resolve(),
            ],
        );
    }

    private function teacherAssignedToBatch(Request $request, Batch $batch): bool
    {
        $teacher = $request->user()?->teacherProfile;

        return $teacher !== null
            && $teacher->activeBatchAssignments()->where('batch_id', $batch->id)->exists();
    }
}
