<?php

namespace App\Actions\Assessments;

use App\Enums\DimensionCode;
use App\Models\AptitudeAssessment;
use App\Models\AptitudeAssessmentOption;
use App\Models\AptitudeAssessmentQuestion;

class RecordQuestionStructure
{
    public function __construct(private readonly SyncOptionDimensionCodes $syncOptionDimensionCodes) {}

    /**
     * Replace all questions and options for an assessment.
     *
     * @param  list<array<string, mixed>>  $questions
     */
    public function replace(AptitudeAssessment $assessment, array $questions): void
    {
        $assessment->questions()->each(function (AptitudeAssessmentQuestion $question): void {
            $question->options()->delete();
            $question->delete();
        });

        foreach (array_values($questions) as $index => $questionData) {
            $question = AptitudeAssessmentQuestion::query()->create([
                'aptitude_assessment_id' => $assessment->id,
                'question_text' => $questionData['question_text'],
                'display_order' => $questionData['display_order'] ?? ($index + 1),
            ]);

            foreach (array_values($questionData['options'] ?? []) as $optionIndex => $optionData) {
                $option = AptitudeAssessmentOption::query()->create([
                    'aptitude_assessment_question_id' => $question->id,
                    'option_text' => $optionData['option_text'],
                    'display_order' => $optionData['display_order'] ?? ($optionIndex + 1),
                ]);

                $this->syncOptionDimensionCodes->execute(
                    $option,
                    $this->normalizeCodes($optionData),
                );
            }
        }
    }

    /**
     * @param  array<string, mixed>  $optionData
     * @return list<string>
     */
    private function normalizeCodes(array $optionData): array
    {
        if (isset($optionData['dimension_codes']) && is_array($optionData['dimension_codes'])) {
            return array_values(array_map('strval', $optionData['dimension_codes']));
        }

        if (isset($optionData['dimension_code']) && is_string($optionData['dimension_code'])) {
            return [$optionData['dimension_code']];
        }

        return [];
    }
}
