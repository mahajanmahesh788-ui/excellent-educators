<?php

namespace App\Actions\Assessments;

use App\Exceptions\ApiException;
use App\Models\AptitudeAssessment;
use App\Support\ErrorCode;

class DeleteAptitudeAssessment
{
    public function execute(AptitudeAssessment $assessment): void
    {
        if ($assessment->hasSubmittedAttempts()) {
            throw new ApiException(
                ErrorCode::ASSESSMENT_LOCKED,
                'Assessments with submitted attempts cannot be deleted. Deactivate them instead.',
                409,
            );
        }

        $assessment->delete();
    }
}
