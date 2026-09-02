<?php

namespace App\Actions\Mentoring;

use App\Models\MasterTeacherAssignment;
use App\Models\StudentProfile;
use Illuminate\Support\Facades\DB;

class UnassignMasterTeacher
{
    public function execute(StudentProfile $student): void
    {
        DB::transaction(function () use ($student): void {
            $current = MasterTeacherAssignment::query()
                ->where('student_id', $student->id)
                ->whereNull('ended_at')
                ->lockForUpdate()
                ->first();

            if ($current) {
                $current->update(['ended_at' => now()]);
            }
        });
    }
}
