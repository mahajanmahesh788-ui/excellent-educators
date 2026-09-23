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
        $codeLists = [];

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

            $codeLists[] = $rows->map(fn ($row) => $row->dimension_code)->all();
        }

        return $this->fromSelectedCodes($codeLists);
    }

    /**
     * @param  iterable<int, iterable<int, DimensionCode|string>>  $selectedCodeLists
     * @return array<string, int>
     */
    public function fromSelectedCodes(iterable $selectedCodeLists): array
    {
        $scores = $this->emptyScores();

        foreach ($selectedCodeLists as $codes) {
            foreach ($codes as $code) {
                $value = $code instanceof DimensionCode ? $code->value : (string) $code;
                if (array_key_exists($value, $scores)) {
                    $scores[$value]++;
                }
            }
        }

        return $scores;
    }

    /**
     * @param  array<string, int>  $scores
     * @return list<array{name: string, score: int, code?: string}>
     */
    public function toDimensions(array $scores, bool $includeCodes = false): array
    {
        $dimensions = [];

        foreach (DimensionCode::cases() as $code) {
            $row = [
                'name' => $code->label(),
                'score' => (int) ($scores[$code->value] ?? 0),
            ];

            if ($includeCodes) {
                $row['code'] = $code->value;
            }

            $dimensions[] = $row;
        }

        return $dimensions;
    }

    /**
     * @return array<string, int>
     */
    private function emptyScores(): array
    {
        $scores = [];

        foreach (DimensionCode::cases() as $code) {
            $scores[$code->value] = 0;
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
