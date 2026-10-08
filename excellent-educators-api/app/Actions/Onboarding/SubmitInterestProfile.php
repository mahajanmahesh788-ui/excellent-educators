<?php

namespace App\Actions\Onboarding;

use App\Enums\InterestOptionSource;
use App\Exceptions\ApiException;
use App\Models\InterestOption;
use App\Models\InterestQuestion;
use App\Models\InterestResponse;
use App\Models\StudentProfile;
use App\Support\ErrorCode;
use App\Support\InterestOptionNormalizer;
use Illuminate\Support\Facades\DB;

class SubmitInterestProfile
{
    /**
     * @param  list<array{question_id: string, option_ids?: list<string>, other_text?: string|null}>  $answers
     */
    public function execute(StudentProfile $student, array $answers): InterestResponse
    {
        $existing = InterestResponse::query()->where('student_id', $student->id)->first();

        $questions = InterestQuestion::query()
            ->with('activeOptions')
            ->where('is_active', true)
            ->orderBy('display_order')
            ->get()
            ->keyBy('id');

        if ($questions->isEmpty()) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'No interest questions are available.', 422);
        }

        $answeredIds = collect($answers)->pluck('question_id')->unique()->values();
        if ($answeredIds->count() !== $questions->count() || $answeredIds->diff($questions->keys())->isNotEmpty()) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Please answer every interest question.', 422);
        }

        return DB::transaction(function () use ($student, $answers, $questions, $existing): InterestResponse {
            $response = $existing ?? InterestResponse::query()->create([
                'student_id' => $student->id,
                'completed_at' => now(),
            ]);

            if ($existing !== null) {
                $oldAnswerIds = $response->answers()->pluck('id');
                $oldOptionIds = DB::table('interest_response_answer_options')
                    ->whereIn('interest_response_answer_id', $oldAnswerIds)
                    ->pluck('interest_option_id')
                    ->all();
                if (! empty($oldOptionIds)) {
                    InterestOption::query()->whereIn('id', $oldOptionIds)->decrement('usage_count');
                }
                $response->answers()->delete();
                $response->forceFill(['completed_at' => now()])->save();
            }

            foreach ($answers as $answerData) {
                /** @var InterestQuestion $question */
                $question = $questions->get($answerData['question_id']);
                $optionIds = array_values(array_unique($answerData['option_ids'] ?? []));
                $otherText = isset($answerData['other_text'])
                    ? InterestOptionNormalizer::displayLabel((string) $answerData['other_text'])
                    : '';

                $resolvedOptionIds = $this->resolveOptionIds($question, $optionIds, $otherText);
                $max = max(1, (int) $question->max_selections);
                if ($resolvedOptionIds === [] || count($resolvedOptionIds) > $max) {
                    throw new ApiException(
                        ErrorCode::VALIDATION_ERROR,
                        "Select between 1 and {$max} options for each question.",
                        422,
                    );
                }

                $answer = $response->answers()->create([
                    'interest_question_id' => $question->id,
                    'other_text' => $otherText !== '' ? $otherText : null,
                ]);
                $answer->options()->attach($resolvedOptionIds);

                InterestOption::query()
                    ->whereIn('id', $resolvedOptionIds)
                    ->increment('usage_count');
            }

            return $response->load(['answers.options']);
        });
    }

    /**
     * @param  list<string>  $optionIds
     * @return list<string>
     */
    private function resolveOptionIds(InterestQuestion $question, array $optionIds, string $otherText): array
    {
        $activeIds = $question->activeOptions->pluck('id')->all();
        foreach ($optionIds as $optionId) {
            if (! in_array($optionId, $activeIds, true)) {
                throw new ApiException(ErrorCode::VALIDATION_ERROR, 'One or more selected options are invalid.', 422);
            }
        }

        $resolved = $optionIds;

        if ($otherText !== '') {
            if (! $question->allow_other) {
                throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Other is not allowed for this question.', 422);
            }

            $option = $this->findOrCreateStudentOption($question, $otherText);
            if (! in_array($option->id, $resolved, true)) {
                $resolved[] = $option->id;
            }
        } elseif ($question->allow_other === false && $optionIds === []) {
            // handled by caller empty check
        }

        return array_values(array_unique($resolved));
    }

    private function findOrCreateStudentOption(InterestQuestion $question, string $label): InterestOption
    {
        $key = InterestOptionNormalizer::normalize($label);
        if ($key === '' || mb_strlen($key) < 2) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Other text must be at least 2 characters.', 422);
        }

        $existing = InterestOption::query()
            ->where('interest_question_id', $question->id)
            ->where('normalized_key', $key)
            ->first();

        if ($existing !== null) {
            if (! $existing->is_active) {
                $existing->forceFill(['is_active' => true])->save();
            }

            return $existing;
        }

        $nextOrder = ((int) $question->options()->max('display_order')) + 1;

        return InterestOption::query()->create([
            'interest_question_id' => $question->id,
            'option_text' => $label,
            'normalized_key' => $key,
            'source' => InterestOptionSource::Student,
            'display_order' => $nextOrder,
            'is_active' => true,
            'usage_count' => 0,
        ]);
    }
}
