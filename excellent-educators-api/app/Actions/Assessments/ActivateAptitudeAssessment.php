<?php

namespace App\Actions\Assessments;

use App\Enums\AptitudeAssessmentStatus;
use App\Exceptions\ApiException;
use App\Models\AptitudeAssessment;
use App\Models\User;
use App\Support\ErrorCode;

class ActivateAptitudeAssessment
{
    public function execute(AptitudeAssessment $assessment, User $actor): AptitudeAssessment
    {
        $assessment->load(['questions.options.dimensionCodes']);

        if (! $assessment->isComplete()) {
            throw new ApiException(
                ErrorCode::ASSESSMENT_NOT_READY,
                'Assessment cannot be activated until every question has options with one to three valid dimension codes.',
                422,
            );
        }

        $assessment->status = AptitudeAssessmentStatus::Active;
        $assessment->updated_by = $actor->id;
        $assessment->save();

        return $assessment->fresh(['questions.options.dimensionCodes']) ?? $assessment;
    }
}
