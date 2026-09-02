<?php

namespace App\Actions\Mentoring;

use App\Actions\Notifications\DispatchAssignmentNotifications;
use App\Models\MasterTeacherAssignment;
use App\Models\StudentProfile;
use Illuminate\Support\Facades\DB;

class UnassignMasterTeacher
{
    public function __construct(
        private readonly DispatchAssignmentNotifications $dispatchAssignmentNotifications,
    ) {}

    public function execute(StudentProfile $student): void
    {
        $previousTeacher = null;

        DB::transaction(function () use ($student, &$previousTeacher): void {
            $current = MasterTeacherAssignment::query()
                ->where('student_id', $student->id)
                ->whereNull('ended_at')
                ->with('teacher')
                ->lockForUpdate()
                ->first();

            if ($current) {
                $previousTeacher = $current->teacher;
                $current->update(['ended_at' => now()]);
            }
        });

        if ($previousTeacher !== null) {
            $this->dispatchAssignmentNotifications->masterTeacherRemoved($student, $previousTeacher);
        }
    }
}
