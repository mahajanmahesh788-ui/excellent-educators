<?php

namespace App\Actions\Assessments;

use App\Enums\AptitudeAssessmentStatus;
use App\Exceptions\ApiException;
use App\Models\AptitudeAssessment;
use App\Models\User;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class UpdateAptitudeAssessment
{
    public function __construct(private readonly RecordQuestionStructure $recordQuestionStructure) {}

    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(AptitudeAssessment $assessment, User $actor, array $input): AptitudeAssessment
    {
        return DB::transaction(function () use ($assessment, $actor, $input) {
            $assessment = AptitudeAssessment::query()->whereKey($assessment->id)->lockForUpdate()->firstOrFail();

            if (isset($input['questions']) && $assessment->hasSubmittedAttempts()) {
                throw new ApiException(
                    ErrorCode::ASSESSMENT_LOCKED,
                    'Questions cannot be changed after a student has submitted this assessment.',
                    409,
                );
            }

            $assessment->fill([
                'title' => $input['title'] ?? $assessment->title,
                'description' => array_key_exists('description', $input) ? $input['description'] : $assessment->description,
                'updated_by' => $actor->id,
            ]);

            if (isset($input['status']) && $input['status'] === AptitudeAssessmentStatus::Draft->value) {
                $assessment->status = AptitudeAssessmentStatus::Draft;
            }

            $assessment->save();

            if (isset($input['questions']) && is_array($input['questions'])) {
                $this->recordQuestionStructure->replace($assessment, $input['questions']);
            }

            return $assessment->fresh(['questions.options.dimensionCodes']) ?? $assessment;
        });
    }
}
