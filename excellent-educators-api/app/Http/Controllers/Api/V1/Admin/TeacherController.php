<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Feedback\BuildMasterTeacherDashboard;
use App\Actions\Teachers\CreateTeacher;
use App\Actions\Teachers\UpdateTeacher;
use App\Enums\RoleName;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreTeacherRequest;
use App\Http\Requests\Api\V1\Admin\UpdateTeacherRequest;
use App\Http\Resources\Api\V1\TeacherResource;
use App\Models\TeacherProfile;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TeacherController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $teachers = TeacherProfile::query()
            ->with(['user.roles', 'activeBatchAssignments.batch.careerCompassLevel'])
            ->withCount(['activeBatchAssignments', 'activeMasterTeacherAssignments'])
            ->when($request->string('search')->toString(), function ($query, string $search): void {
                $digits = preg_replace('/\D+/', '', $search) ?? '';

                $query->where(function ($inner) use ($search, $digits): void {
                    $inner->where('full_name', 'like', "%{$search}%")
                        ->orWhere('employee_code', 'like', "%{$search}%")
                        ->orWhere('phone', 'like', "%{$search}%")
                        ->orWhere('whatsapp_number', 'like', "%{$search}%")
                        ->orWhereHas('user', fn ($user) => $user->where('email', 'like', "%{$search}%"));

                    if ($digits !== '') {
                        $inner->orWhere('phone', 'like', "%{$digits}%")
                            ->orWhere('whatsapp_number', 'like', "%{$digits}%");
                    }
                });
            })
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->when($request->filled('role'), function ($query) use ($request): void {
                $role = $request->string('role')->toString();
                $query->whereHas('user.roles', fn ($roles) => $roles->where('name', $role));
            })
            ->orderBy('full_name')
            ->paginate((int) $request->integer('per_page', 15));

        return ApiResponse::success(
            'Teachers fetched successfully.',
            TeacherResource::collection($teachers)->resolve(),
            [
                'page' => $teachers->currentPage(),
                'per_page' => $teachers->perPage(),
                'total' => $teachers->total(),
            ],
        );
    }

    public function store(StoreTeacherRequest $request, CreateTeacher $createTeacher): JsonResponse
    {
        $teacher = $createTeacher->execute($request->validated());
        $teacher->load('user.roles');

        return ApiResponse::success('Teacher created successfully.', TeacherResource::make($teacher)->resolve(), status: 201);
    }

    public function show(TeacherProfile $teacher): JsonResponse
    {
        $teacher->load('user.roles')->loadCount(['activeBatchAssignments', 'activeMasterTeacherAssignments']);

        return ApiResponse::success('Teacher fetched successfully.', TeacherResource::make($teacher)->resolve());
    }

    public function dashboard(TeacherProfile $teacher, BuildMasterTeacherDashboard $buildMasterTeacherDashboard): JsonResponse
    {
        $teacher->loadMissing('user.roles');

        if (! $teacher->user?->hasRole(RoleName::MasterTeacher->value)) {
            return ApiResponse::error(
                'Rating progress is available for Master Teachers only.',
                ErrorCode::VALIDATION_ERROR,
                null,
                422,
            );
        }

        return ApiResponse::success(
            'Teacher rating progress fetched successfully.',
            $buildMasterTeacherDashboard->execute($teacher),
        );
    }

    public function update(UpdateTeacherRequest $request, TeacherProfile $teacher, UpdateTeacher $updateTeacher): JsonResponse
    {
        $teacher = $updateTeacher->execute($teacher, $request->validated());
        $teacher->load('user.roles')->loadCount(['activeBatchAssignments', 'activeMasterTeacherAssignments']);

        return ApiResponse::success('Teacher updated successfully.', TeacherResource::make($teacher)->resolve());
    }
}
