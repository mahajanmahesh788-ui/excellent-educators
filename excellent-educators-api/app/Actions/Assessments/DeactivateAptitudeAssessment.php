<?php

namespace App\Actions\Assessments;

use App\Enums\AptitudeAssessmentStatus;
use App\Models\AptitudeAssessment;
use App\Models\User;

class DeactivateAptitudeAssessment
{
    public function execute(AptitudeAssessment $assessment, User $actor): AptitudeAssessment
    {
        $assessment->status = AptitudeAssessmentStatus::Inactive;
        $assessment->updated_by = $actor->id;
        $assessment->save();

        return $assessment->fresh(['questions.options.dimensionCodes']) ?? $assessment;
    }
}
