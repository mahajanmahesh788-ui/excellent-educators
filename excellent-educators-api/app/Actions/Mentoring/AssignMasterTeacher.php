<?php

namespace App\Actions\Mentoring;

use App\Actions\Notifications\DispatchAssignmentNotifications;
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
    public function __construct(
        private readonly DispatchAssignmentNotifications $dispatchAssignmentNotifications,
    ) {}

    public function execute(StudentProfile $student, TeacherProfile $teacher, User $actor): MasterTeacherAssignment
    {
        if (! $teacher->user->hasRole(RoleName::MasterTeacher->value)) {
            throw new ApiException(
                ErrorCode::VALIDATION_ERROR,
                'Only a Master Teacher can be assigned to a student.',
                422,
            );
        }

        $previousTeacher = null;

        $assignment = DB::transaction(function () use ($student, $teacher, $actor, &$previousTeacher): MasterTeacherAssignment {
            $current = MasterTeacherAssignment::query()
                ->where('student_id', $student->id)
                ->whereNull('ended_at')
                ->with('teacher')
                ->lockForUpdate()
                ->first();

            if ($current && $current->teacher_id === $teacher->id) {
                return $current;
            }

            if ($current) {
                $previousTeacher = $current->teacher;
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

        if ($previousTeacher === null && $assignment->wasRecentlyCreated) {
            $this->dispatchAssignmentNotifications->masterTeacherAssigned($student, $teacher);
        } elseif ($previousTeacher !== null) {
            $this->dispatchAssignmentNotifications->masterTeacherAssigned($student, $teacher, $previousTeacher);
        }

        return $assignment;
    }
}
