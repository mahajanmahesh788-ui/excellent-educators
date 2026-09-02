<?php

namespace App\Actions\Assessments;

use App\Enums\DimensionCode;
use App\Models\AptitudeAssessmentAnswer;
use Illuminate\Support\Collection;

class CalculateAssessmentResult
{
    /**
     * Count selected options per ExcellentEducators dimension.
     *
     * @param  iterable<AptitudeAssessmentAnswer>  $answers
     * @return array<string, int>
     */
    public function execute(iterable $answers): array
    {
        $scores = [];

        foreach (DimensionCode::cases() as $code) {
            $scores[$code->value] = 0;
        }

        foreach ($answers as $answer) {
            $option = $answer->option;
            if ($option === null) {
                continue;
            }

            if ($option->relationLoaded('dimensionCodes')) {
                $rows = $option->dimensionCodes;
            } elseif ($option->exists) {
                $option->loadMissing('dimensionCodes');
                $rows = $option->dimensionCodes;
            } else {
                continue;
            }

            foreach ($rows as $row) {
                $code = $row->dimension_code instanceof DimensionCode
                    ? $row->dimension_code->value
                    : (string) $row->dimension_code;

                if (array_key_exists($code, $scores)) {
                    $scores[$code]++;
                }
            }
        }

        return $scores;
    }

    /**
     * @param  Collection<int, AptitudeAssessmentAnswer>  $answers
     * @return array<string, int>
     */
    public function fromAnswers(Collection $answers): array
    {
        return $this->execute($answers);
    }
}
