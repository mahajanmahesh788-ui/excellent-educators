<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Batches\CreateBatch;
use App\Actions\Batches\EnrollStudent;
use App\Actions\Batches\UnenrollStudent;
use App\Actions\Batches\UpdateBatch;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\EnrollStudentRequest;
use App\Http\Requests\Api\V1\Admin\StoreBatchRequest;
use App\Http\Requests\Api\V1\Admin\UpdateBatchRequest;
use App\Http\Resources\Api\V1\BatchResource;
use App\Http\Resources\Api\V1\StudentResource;
use App\Enums\BatchStatus;
use App\Enums\ProfileStatus;
use App\Models\AcademicLevel;
use App\Models\Batch;
use App\Models\StudentProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class BatchController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $batches = Batch::query()
            ->with(['activeTeacherAssignment.teacher'])
            ->withCount('activeEnrollments')
            ->when($request->string('search')->toString(), function ($query, string $search): void {
                $query->where('name', 'like', "%{$search}%");
            })
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->when($request->has('full'), function ($query): void {
                $maxPerBatch = app(\App\Support\AppSettings::class)->maxActiveStudents();
                $query->whereIn('id', function ($sub) use ($maxPerBatch): void {
                    $sub->select('batch_id')
                        ->from('batch_students')
                        ->whereNull('left_at')
                        ->where('status', ProfileStatus::Active->value)
                        ->groupBy('batch_id')
                        ->havingRaw('count(*) >= ?', [$maxPerBatch]);
                });
            })
            ->orderBy('name')
            ->paginate((int) $request->integer('per_page', 15));

        return ApiResponse::success(
            'Batches fetched successfully.',
            BatchResource::collection($batches)->resolve(),
            [
                'page' => $batches->currentPage(),
                'per_page' => $batches->perPage(),
                'total' => $batches->total(),
            ],
        );
    }

    public function store(StoreBatchRequest $request, CreateBatch $createBatch): JsonResponse
    {
        $batch = $createBatch->execute($request->validated());
        $batch->load(['activeTeacherAssignment.teacher'])->loadCount('activeEnrollments');

        return ApiResponse::success('Batch created successfully.', BatchResource::make($batch)->resolve(), status: 201);
    }

    public function show(Batch $batch): JsonResponse
    {
        $batch->load(['activeTeacherAssignment.teacher'])->loadCount('activeEnrollments');

        return ApiResponse::success('Batch fetched successfully.', BatchResource::make($batch)->resolve());
    }

    public function update(UpdateBatchRequest $request, Batch $batch, UpdateBatch $updateBatch): JsonResponse
    {
        $batch = $updateBatch->execute($batch, $request->validated());
        $batch->load(['activeTeacherAssignment.teacher'])->loadCount('activeEnrollments');

        return ApiResponse::success('Batch updated successfully.', BatchResource::make($batch)->resolve());
    }

    public function students(Batch $batch): JsonResponse
    {
        $students = $batch->activeEnrollments()
            ->with([
                'student.user',
                'student.activeEnrollment.batch.activeTeacherAssignment.teacher',
                'student.activeMasterTeacherAssignment.teacher',
            ])
            ->get()
            ->pluck('student');

        return ApiResponse::success(
            'Batch students fetched successfully.',
            StudentResource::collection($students)->resolve(),
        );
    }

    public function enroll(EnrollStudentRequest $request, Batch $batch, EnrollStudent $enrollStudent): JsonResponse
    {
        $student = StudentProfile::query()->findOrFail($request->string('student_id'));
        $enrollStudent->execute($batch, $student, $request->user());
        $batch->load(['activeTeacherAssignment.teacher'])->loadCount('activeEnrollments');

        return ApiResponse::success('Student enrolled successfully.', BatchResource::make($batch)->resolve());
    }

    public function unenroll(Batch $batch, StudentProfile $student, UnenrollStudent $unenrollStudent): JsonResponse
    {
        $unenrollStudent->execute($batch, $student);
        $batch->load(['activeTeacherAssignment.teacher'])->loadCount('activeEnrollments');

        return ApiResponse::success('Student removed from batch.', BatchResource::make($batch)->resolve());
    }

    public function toggleStatus(Batch $batch): JsonResponse
    {
        $newStatus = ($batch->status === BatchStatus::Active || $batch->status === 'active') ? 'inactive' : 'active';
        $batch->update(['status' => $newStatus]);
        $batch->load(['level', 'activeTeacherAssignment.teacher'])->loadCount('activeEnrollments');

        return ApiResponse::success(
            "Batch status updated to {$newStatus}.",
            BatchResource::make($batch)->resolve(),
        );
    }

    public function storeForLevel(Request $request, AcademicLevel $level): JsonResponse
    {
        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('batches', 'name')->where('level_id', $level->id),
            ],
            'year' => ['nullable', 'integer', 'min:2000', 'max:2100'],
            'month' => ['nullable', 'integer', 'min:1', 'max:12'],
        ], [
            'name.unique' => 'A batch with this name already exists in this level.',
        ]);

        $year = $validated['year'] ?? ($level->academic_year ?? (int) date('Y'));
        $month = $validated['month'] ?? (int) date('n');

        $batch = Batch::query()->create([
            'level_id' => $level->id,
            'name' => $validated['name'],
            'academic_year' => $year,
            'year' => $year,
            'month' => $month,
            'status' => 'active',
            'enrolled_watermark' => 0,
        ]);

        $batch->loadCount('activeEnrollments');

        return ApiResponse::success('Batch created successfully.', BatchResource::make($batch)->resolve(), status: 201);
    }
}
