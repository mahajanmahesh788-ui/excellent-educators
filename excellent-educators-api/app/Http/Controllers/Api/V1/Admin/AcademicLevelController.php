<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\AcademicLevelResource;
use App\Models\AcademicLevel;
use App\Models\Batch;
use App\Models\TeacherProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

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
            ->orderBy('created_at')
            ->get();

        return ApiResponse::success(
            'Levels fetched successfully.',
            AcademicLevelResource::collection($levels)->resolve(),
        );
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255', 'unique:academic_levels,name'],
            'academic_year' => ['required', 'integer', 'min:2000', 'max:2100'],
            'master_classes_per_month' => ['sometimes', 'integer', 'min:1', 'max:10'],
        ], [
            'name.unique' => 'The level name has already been taken.',
        ]);

        $level = AcademicLevel::query()->create([
            'name' => $validated['name'],
            'academic_year' => $validated['academic_year'],
            'master_classes_per_month' => (int) ($validated['master_classes_per_month'] ?? 1),
            'status' => 'active',
        ]);

        // Auto-create initial Batch 1 for the new level
        Batch::query()->create([
            'level_id' => $level->id,
            'name' => 'Batch 1',
            'academic_year' => $level->academic_year,
            'year' => (int) date('Y'),
            'month' => (int) date('n'),
            'status' => 'active',
            'enrolled_watermark' => 0,
        ]);

        $level->load([
            'batches' => fn ($q) => $q->withCount('activeEnrollments'),
            'masterTeachers.user',
        ])->loadCount(['batches', 'students']);

        return ApiResponse::success(
            'Level created successfully.',
            AcademicLevelResource::make($level)->resolve(),
            status: 201,
        );
    }

    public function show(AcademicLevel $level): JsonResponse
    {
        $level->load([
            'batches' => fn ($q) => $q->withCount('activeEnrollments'),
            'masterTeachers.user',
        ])->loadCount(['batches', 'students']);

        return ApiResponse::success(
            'Level fetched successfully.',
            AcademicLevelResource::make($level)->resolve(),
        );
    }

    public function update(Request $request, AcademicLevel $level): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255', Rule::unique('academic_levels', 'name')->ignore($level->id)],
            'academic_year' => ['sometimes', 'integer', 'min:2000', 'max:2100'],
            'master_classes_per_month' => ['sometimes', 'integer', 'min:1', 'max:10'],
            'status' => ['sometimes', Rule::in(['active', 'inactive'])],
        ], [
            'name.unique' => 'The level name has already been taken.',
        ]);

        $level->update($validated);
        $level->load([
            'batches' => fn ($q) => $q->withCount('activeEnrollments'),
            'masterTeachers.user',
        ])->loadCount(['batches', 'students']);

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

        $level->load([
            'batches' => fn ($q) => $q->withCount('activeEnrollments'),
            'masterTeachers.user',
        ])->loadCount(['batches', 'students']);

        return ApiResponse::success(
            'Master Teacher assigned to level successfully.',
            AcademicLevelResource::make($level)->resolve(),
        );
    }

    public function unassignTeacher(AcademicLevel $level, TeacherProfile $teacher): JsonResponse
    {
        $level->masterTeachers()->detach($teacher->id);

        $level->load([
            'batches' => fn ($q) => $q->withCount('activeEnrollments'),
            'masterTeachers.user',
        ])->loadCount(['batches', 'students']);

        return ApiResponse::success(
            'Master Teacher removed from level successfully.',
            AcademicLevelResource::make($level)->resolve(),
        );
    }
}
