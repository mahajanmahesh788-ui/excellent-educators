<?php

namespace App\Actions\Assessments;

use App\Enums\AptitudeAssessmentStatus;
use App\Enums\DimensionCode;
use App\Models\AptitudeAssessment;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CreateAptitudeAssessment
{
    public function __construct(private readonly RecordQuestionStructure $recordQuestionStructure) {}

    /**
     * @param  array<string, mixed>  $input
     */
    public function execute(User $actor, array $input): AptitudeAssessment
    {
        return DB::transaction(function () use ($actor, $input) {
            $assessment = AptitudeAssessment::query()->create([
                'title' => $input['title'],
                'description' => $input['description'] ?? null,
                'status' => AptitudeAssessmentStatus::Draft,
                'created_by' => $actor->id,
                'updated_by' => $actor->id,
            ]);

            if (isset($input['questions']) && is_array($input['questions'])) {
                $this->assertValidDimensionCodes($input['questions']);
                $this->recordQuestionStructure->replace($assessment, $input['questions']);
            }

            return $assessment->fresh(['questions.options.dimensionCodes']) ?? $assessment;
        });
    }

    /**
     * @param  list<array<string, mixed>>  $questions
     */
    private function assertValidDimensionCodes(array $questions): void
    {
        $valid = DimensionCode::values();

        foreach ($questions as $questionIndex => $question) {
            foreach ($question['options'] ?? [] as $optionIndex => $option) {
                $codes = $this->codesFromOption($option);
                if ($codes === []) {
                    throw ValidationException::withMessages([
                        "questions.{$questionIndex}.options.{$optionIndex}.dimension_codes" => 'Each option must have at least one dimension code.',
                    ]);
                }

                if (count($codes) > 3) {
                    throw ValidationException::withMessages([
                        "questions.{$questionIndex}.options.{$optionIndex}.dimension_codes" => 'Each option may have at most three dimension codes.',
                    ]);
                }

                if (count($codes) !== count(array_unique($codes))) {
                    throw ValidationException::withMessages([
                        "questions.{$questionIndex}.options.{$optionIndex}.dimension_codes" => 'Dimension codes must be unique.',
                    ]);
                }

                foreach ($codes as $code) {
                    if (! in_array($code, $valid, true)) {
                        throw ValidationException::withMessages([
                            "questions.{$questionIndex}.options.{$optionIndex}.dimension_codes" => 'One or more dimension codes are invalid.',
                        ]);
                    }
                }
            }
        }
    }

    /**
     * @param  array<string, mixed>  $option
     * @return list<string>
     */
    private function codesFromOption(array $option): array
    {
        if (isset($option['dimension_codes']) && is_array($option['dimension_codes'])) {
            return array_values(array_map('strval', $option['dimension_codes']));
        }

        if (isset($option['dimension_code']) && is_string($option['dimension_code'])) {
            return [$option['dimension_code']];
        }

        return [];
    }
}
