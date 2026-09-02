<?php

namespace App\Actions\Mentoring;

use App\Enums\RoleName;
use App\Exceptions\ApiException;
use App\Models\MasterTeacherAssignment;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class AssignMasterTeacher
{
    public function execute(StudentProfile $student, TeacherProfile $teacher, User $actor): MasterTeacherAssignment
    {
        if (! $teacher->user->hasRole(RoleName::MasterTeacher->value)) {
            throw new ApiException(
                ErrorCode::VALIDATION_ERROR,
                'Only a Master Teacher can be assigned to a student.',
                422,
            );
        }

        return DB::transaction(function () use ($student, $teacher, $actor): MasterTeacherAssignment {
            $current = MasterTeacherAssignment::query()
                ->where('student_id', $student->id)
                ->whereNull('ended_at')
                ->lockForUpdate()
                ->first();

            if ($current && $current->teacher_id === $teacher->id) {
                return $current;
            }

            if ($current) {
                $current->update(['ended_at' => now()]);
            }

            return MasterTeacherAssignment::query()->create([
                'student_id' => $student->id,
                'teacher_id' => $teacher->id,
                'assigned_by' => $actor->id,
                'started_at' => now(),
                'created_at' => now(),
            ]);
        });
    }
}
