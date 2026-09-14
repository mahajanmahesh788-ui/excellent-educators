<?php

namespace App\Actions\Assessments;

use App\Enums\AptitudeAssessmentStatus;
use App\Enums\AssessmentAttemptStatus;
use App\Models\AptitudeAssessment;
use App\Models\StudentProfile;

class GetApplicableStudentAssessment
{
    public function execute(StudentProfile $student): ?AptitudeAssessment
    {
        return AptitudeAssessment::query()
            ->where('status', AptitudeAssessmentStatus::Active)
            ->whereDoesntHave('submittedAttempts', function ($query) use ($student): void {
                $query->where('student_id', $student->id)
                    ->where('status', AssessmentAttemptStatus::Submitted->value);
            })
            ->with(['questions.options'])
            ->orderByDesc('updated_at')
            ->first();
    }

    public function completedExists(StudentProfile $student): bool
    {
        return AptitudeAssessment::query()
            ->whereHas('submittedAttempts', function ($query) use ($student): void {
                $query->where('student_id', $student->id)
                    ->where('status', AssessmentAttemptStatus::Submitted->value);
            })
            ->exists();
    }
}
