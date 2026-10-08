<?php

namespace App\Actions\Onboarding;

use App\Enums\OnboardingQuestionType;
use App\Exceptions\ApiException;
use App\Models\ParentOption;
use App\Models\ParentQuestion;
use App\Models\ParentResponse;
use App\Models\StudentProfile;
use App\Support\ErrorCode;
use Illuminate\Support\Facades\DB;

class SubmitParentIntake
{
    /**
     * @param  list<array{question_id: string, option_id?: string|null, text_answer?: string|null}>  $answers
     */
    public function execute(StudentProfile $student, array $answers): ParentResponse
    {
        $existing = ParentResponse::query()->where('student_id', $student->id)->first();

        $questions = ParentQuestion::query()
            ->with('options')
            ->where('is_active', true)
            ->orderBy('display_order')
            ->get()
            ->keyBy('id');

        if ($questions->isEmpty()) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'No parent questions are available.', 422);
        }

        $answeredIds = collect($answers)->pluck('question_id')->unique()->values();
        if ($answeredIds->count() !== $questions->count() || $answeredIds->diff($questions->keys())->isNotEmpty()) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Please answer every parent question.', 422);
        }

        return DB::transaction(function () use ($student, $answers, $questions, $existing): ParentResponse {
            $response = $existing ?? ParentResponse::query()->create([
                'student_id' => $student->id,
            ]);

            $response->answers()->delete();
            $response->forceFill([
                'completed_at' => now(),
                'skipped_at' => null,
            ])->save();

            foreach ($answers as $answerData) {
                /** @var ParentQuestion $question */
                $question = $questions->get($answerData['question_id']);

                if ($question->question_type === OnboardingQuestionType::Text) {
                    $text = trim((string) ($answerData['text_answer'] ?? ''));
                    if ($text === '') {
                        throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Text answers cannot be empty.', 422);
                    }
                    $response->answers()->create([
                        'parent_question_id' => $question->id,
                        'text_answer' => $text,
                        'parent_option_id' => null,
                    ]);

                    continue;
                }

                $optionId = $answerData['option_id'] ?? null;
                $valid = $question->options->where('is_active', true)->pluck('id')->all();
                if (! is_string($optionId) || ! in_array($optionId, $valid, true)) {
                    throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Please select a valid option.', 422);
                }

                $response->answers()->create([
                    'parent_question_id' => $question->id,
                    'text_answer' => null,
                    'parent_option_id' => $optionId,
                ]);
            }

            return $response->fresh(['answers.option']);
        });
    }
}
