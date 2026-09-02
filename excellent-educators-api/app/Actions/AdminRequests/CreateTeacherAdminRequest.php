<?php

namespace App\Actions\AdminRequests;

use App\Enums\AdminRequestRequesterType;
use App\Enums\AdminRequestStatus;
use App\Enums\AdminRequestType;
use App\Enums\RoleName;
use App\Exceptions\ApiException;
use App\Models\AdminRequest;
use App\Models\Batch;
use App\Models\StudentProfile;
use App\Models\User;
use App\Support\ErrorCode;
use Illuminate\Validation\ValidationException;

class CreateTeacherAdminRequest
{
    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(User $user, array $input): AdminRequest
    {
        $type = AdminRequestType::tryFrom((string) ($input['request_type'] ?? AdminRequestType::General->value))
            ?? AdminRequestType::General;

        return match ($type) {
            AdminRequestType::General => $this->createGeneral($user, $input),
            AdminRequestType::RemoveMentee => $this->createRemoveMentee($user, $input),
            AdminRequestType::RemoveBatchStudent => $this->createRemoveBatchStudent($user, $input),
        };
    }

    /**
     * @param  array<string, mixed>  $input
     */
    private function createGeneral(User $user, array $input): AdminRequest
    {
        $subtitle = trim((string) ($input['subtitle'] ?? ''));
        $description = trim((string) ($input['description'] ?? ''));

        if ($subtitle === '' || $description === '') {
            throw ValidationException::withMessages([
                'subtitle' => 'Enter a subject.',
                'description' => 'Enter a description.',
            ]);
        }

        return $this->store($user, AdminRequestType::General, $subtitle, $description);
    }

    /**
     * @param  array<string, mixed>  $input
     */
    private function createRemoveMentee(User $user, array $input): AdminRequest
    {
        if (! $user->hasRole(RoleName::MasterTeacher->value)) {
            throw new ApiException(ErrorCode::FORBIDDEN, 'Only Master Teachers can request mentee removal.', 403);
        }

        $teacher = $user->teacherProfile;
        $student = StudentProfile::query()->find($input['student_id'] ?? null);
        if ($teacher === null || $student === null) {
            throw ValidationException::withMessages([
                'student_id' => 'Select a valid student.',
            ]);
        }

        $assigned = $teacher->activeMasterTeacherAssignments()
            ->where('student_id', $student->id)
            ->exists();

        if (! $assigned) {
            throw new ApiException(
                ErrorCode::FORBIDDEN,
                'You can only request removal for students currently assigned to you.',
                403,
            );
        }

        $this->assertNoDuplicatePending($user, AdminRequestType::RemoveMentee, $student->id);

        $reason = trim((string) ($input['reason'] ?? ''));
        $subtitle = "Remove student: {$student->full_name}";
        $description = $reason === ''
            ? "{$teacher->full_name} requested to remove {$student->full_name} ({$student->student_code}) from their mentee list."
            : "{$teacher->full_name} requested to remove {$student->full_name} ({$student->student_code}) from their mentee list.\n\nReason: {$reason}";

        return $this->store(
            $user,
            AdminRequestType::RemoveMentee,
            $subtitle,
            $description,
            studentId: $student->id,
        );
    }

    /**
     * @param  array<string, mixed>  $input
     */
    private function createRemoveBatchStudent(User $user, array $input): AdminRequest
    {
        $teacher = $user->teacherProfile;
        $student = StudentProfile::query()->find($input['student_id'] ?? null);
        $batch = Batch::query()->find($input['batch_id'] ?? null);

        if ($teacher === null || $student === null || $batch === null) {
            throw ValidationException::withMessages([
                'student_id' => 'Select a valid student.',
                'batch_id' => 'Select a valid batch.',
            ]);
        }

        $assigned = $teacher->activeBatchAssignments()
            ->where('batch_id', $batch->id)
            ->exists();

        if (! $assigned) {
            throw new ApiException(
                ErrorCode::FORBIDDEN,
                'You can only request removal for students in your assigned batches.',
                403,
            );
        }

        $enrollment = $student->activeEnrollment;
        if ($enrollment === null || $enrollment->batch_id !== $batch->id) {
            throw new ApiException(
                ErrorCode::VALIDATION_ERROR,
                'This student is not actively enrolled in the selected batch.',
                422,
            );
        }

        $this->assertNoDuplicatePending($user, AdminRequestType::RemoveBatchStudent, $student->id, $batch->id);

        $reason = trim((string) ($input['reason'] ?? ''));
        $batchLabel = $batch->name;
        $subtitle = "Remove student from batch: {$student->full_name}";
        $description = $reason === ''
            ? "{$teacher->full_name} requested to remove {$student->full_name} ({$student->student_code}) from {$batchLabel}."
            : "{$teacher->full_name} requested to remove {$student->full_name} ({$student->student_code}) from {$batchLabel}.\n\nReason: {$reason}";

        return $this->store(
            $user,
            AdminRequestType::RemoveBatchStudent,
            $subtitle,
            $description,
            studentId: $student->id,
            batchId: $batch->id,
        );
    }

    private function assertNoDuplicatePending(
        User $user,
        AdminRequestType $type,
        string $studentId,
        ?string $batchId = null,
    ): void {
        $exists = AdminRequest::query()
            ->where('user_id', $user->id)
            ->where('status', AdminRequestStatus::Pending)
            ->where('request_type', $type)
            ->where('student_id', $studentId)
            ->when($batchId !== null, fn ($query) => $query->where('batch_id', $batchId))
            ->exists();

        if ($exists) {
            throw new ApiException(
                ErrorCode::CONFLICT,
                'You already have a pending request for this student.',
                409,
            );
        }
    }

    private function store(
        User $user,
        AdminRequestType $type,
        string $subtitle,
        string $description,
        ?string $studentId = null,
        ?string $batchId = null,
    ): AdminRequest {
        return AdminRequest::query()->create([
            'user_id' => $user->id,
            'requester_type' => AdminRequestRequesterType::Teacher,
            'request_type' => $type,
            'subtitle' => $subtitle,
            'description' => $description,
            'student_id' => $studentId,
            'batch_id' => $batchId,
            'status' => AdminRequestStatus::Pending,
        ]);
    }
}
