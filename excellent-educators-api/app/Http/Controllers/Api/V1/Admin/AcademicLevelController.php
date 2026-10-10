<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\AcademicLevelResource;
use App\Http\Resources\Api\V1\AptitudeAssessmentResource;
use App\Models\AcademicLevel;
use App\Models\AptitudeAssessment;
use App\Models\Batch;
use App\Models\TeacherProfile;
use App\Support\ApiResponse;
use App\Support\StaticAcademicLevels;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AcademicLevelController extends Controller
{
    public function index(): JsonResponse
    {
        $levels = AcademicLevel::query()
            ->with([
                'batches' => fn ($q) => $q->withCount('activeEnrollments'),
                'masterTeachers.user',
            ])
            ->withCount(['batches', 'students'])
            ->orderByRaw('CASE WHEN number IS NULL THEN 1 ELSE 0 END')
            ->orderBy('number')
            ->orderBy('created_at')
            ->get();

        return ApiResponse::success(
            'Levels fetched successfully.',
            AcademicLevelResource::collection($levels)->resolve(),
            [
                'available_numbers' => StaticAcademicLevels::availableNumbers(),
            ],
        );
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'number' => ['required', 'integer', 'min:'.StaticAcademicLevels::MIN, 'max:'.StaticAcademicLevels::MAX],
            'academic_year' => ['required', 'integer', 'min:2000', 'max:2100'],
            'master_classes_per_month' => ['sometimes', 'integer', 'min:1', 'max:10'],
        ]);

        $number = (int) $validated['number'];
        if (AcademicLevel::query()->where('number', $number)->exists()) {
            throw ValidationException::withMessages([
                'number' => ['Level '.$number.' already exists. Choose another level.'],
            ]);
        }

        $level = AcademicLevel::query()->create([
            'name' => StaticAcademicLevels::label($number),
            'number' => $number,
            'academic_year' => $validated['academic_year'],
            'master_classes_per_month' => (int) ($validated['master_classes_per_month'] ?? 1),
            'status' => 'active',
        ]);

        // Auto-create initial Batch 1 for the new level (inactive until full or admin activates).
        Batch::query()->create([
            'level_id' => $level->id,
            'name' => 'Batch 1',
            'academic_year' => $level->academic_year,
            'year' => (int) date('Y'),
            'month' => (int) date('n'),
            'status' => 'inactive',
            'enrolled_watermark' => 0,
        ]);

        $this->loadLevelDetail($level);

        return ApiResponse::success(
            'Level created successfully.',
            AcademicLevelResource::make($level)->resolve(),
            status: 201,
        );
    }

    public function show(AcademicLevel $level): JsonResponse
    {
        $this->loadLevelDetail($level);

        return ApiResponse::success(
            'Level fetched successfully.',
            AcademicLevelResource::make($level)->resolve(),
        );
    }

    public function update(Request $request, AcademicLevel $level): JsonResponse
    {
        $validated = $request->validate([
            'academic_year' => ['sometimes', 'integer', 'min:2000', 'max:2100'],
            'master_classes_per_month' => ['sometimes', 'integer', 'min:1', 'max:10'],
            'status' => ['sometimes', Rule::in(['active', 'inactive'])],
        ]);

        // Level name/number are fixed (Level 1 … Level 10).
        $level->update($validated);
        $this->loadLevelDetail($level);

        return ApiResponse::success(
            'Level updated successfully.',
            AcademicLevelResource::make($level)->resolve(),
        );
    }

    public function destroy(AcademicLevel $level): JsonResponse
    {
        $level->delete();

        return ApiResponse::success('Level deleted successfully.');
    }

    public function assignTeacher(Request $request, AcademicLevel $level): JsonResponse
    {
        $validated = $request->validate([
            'teacher_id' => ['required', 'string', 'exists:teacher_profiles,id'],
        ]);

        $teacher = TeacherProfile::query()->findOrFail($validated['teacher_id']);

        $level->masterTeachers()->syncWithoutDetaching([$teacher->id]);

        $this->loadLevelDetail($level);

        return ApiResponse::success(
            'Master Teacher assigned to level successfully.',
            AcademicLevelResource::make($level)->resolve(),
        );
    }

    public function unassignTeacher(AcademicLevel $level, TeacherProfile $teacher): JsonResponse
    {
        $level->masterTeachers()->detach($teacher->id);

        $this->loadLevelDetail($level);

        return ApiResponse::success(
            'Master Teacher removed from level successfully.',
            AcademicLevelResource::make($level)->resolve(),
        );
    }

    public function assessments(AcademicLevel $level): JsonResponse
    {
        $assessments = $level->aptitudeAssessments()
            ->withCount(['questions', 'submittedAttempts'])
            ->orderBy('title')
            ->get();

        return ApiResponse::success(
            'Level assessments fetched successfully.',
            [
                'assessment_ids' => $assessments->pluck('id')->values()->all(),
                'assessments' => AptitudeAssessmentResource::collection($assessments)->resolve(),
            ],
        );
    }

    public function syncAssessments(Request $request, AcademicLevel $level): JsonResponse
    {
        $validated = $request->validate([
            'assessment_ids' => ['present', 'array'],
            'assessment_ids.*' => ['string', 'distinct', 'exists:aptitude_assessments,id'],
        ]);

        $ids = $validated['assessment_ids'];
        $level->aptitudeAssessments()->sync($ids);

        $assessments = $level->aptitudeAssessments()
            ->withCount(['questions', 'submittedAttempts'])
            ->orderBy('title')
            ->get();

        return ApiResponse::success(
            'Level assessments updated successfully.',
            [
                'assessment_ids' => $assessments->pluck('id')->values()->all(),
                'assessments' => AptitudeAssessmentResource::collection($assessments)->resolve(),
            ],
        );
    }

    private function loadLevelDetail(AcademicLevel $level): void
    {
        $level->load([
            'batches' => fn ($q) => $q->withCount('activeEnrollments'),
            'masterTeachers.user',
            'aptitudeAssessments' => fn ($q) => $q
                ->withCount(['questions', 'submittedAttempts'])
                ->orderBy('title'),
        ])->loadCount(['batches', 'students']);
    }
}
