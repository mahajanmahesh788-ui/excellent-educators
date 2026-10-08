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
        if ($student->level_id === null) {
            return null;
        }

        return AptitudeAssessment::query()
            ->where('status', AptitudeAssessmentStatus::Active)
            ->whereHas('levels', fn ($query) => $query->where('academic_levels.id', $student->level_id))
            ->whereDoesntHave('submittedAttempts', function ($query) use ($student): void {
                $query->where('student_id', $student->id)
                    ->where('status', AssessmentAttemptStatus::Submitted->value);
            })
            ->with(['questions.options'])
            ->orderByDesc('updated_at')
            ->first();
    }

    /**
     * True when this student's current level has active assigned assessments
     * and every one of them has already been submitted by the student.
     */
    public function completedExists(StudentProfile $student): bool
    {
        if ($student->level_id === null) {
            return false;
        }

        $assigned = AptitudeAssessment::query()
            ->where('status', AptitudeAssessmentStatus::Active)
            ->whereHas('levels', fn ($query) => $query->where('academic_levels.id', $student->level_id));

        if (! (clone $assigned)->exists()) {
            return false;
        }

        // Still pending if any assigned active assessment is not submitted yet.
        return ! (clone $assigned)
            ->whereDoesntHave('submittedAttempts', function ($query) use ($student): void {
                $query->where('student_id', $student->id)
                    ->where('status', AssessmentAttemptStatus::Submitted->value);
            })
            ->exists();
    }
}
