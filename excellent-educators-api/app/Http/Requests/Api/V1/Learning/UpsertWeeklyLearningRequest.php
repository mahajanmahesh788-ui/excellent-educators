<?php

namespace App\Http\Requests\Api\V1\Learning;

use App\Enums\DimensionCode;
use App\Enums\WeeklyQuestionType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class UpsertWeeklyLearningRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'week_number' => ['required', 'integer', 'min:1', 'max:52'],
            'video_url' => ['required', 'url', 'max:2048'],
            'questions' => ['required', 'array', 'min:1'],
            'questions.*.question_text' => ['required', 'string', 'max:2000'],
            'questions.*.question_type' => ['required', Rule::enum(WeeklyQuestionType::class)],
            'questions.*.options' => ['nullable', 'array'],
            'questions.*.options.*.option_text' => ['required', 'string', 'max:500'],
            'questions.*.options.*.dimension_codes' => ['required', 'array', 'min:1', 'max:3'],
            'questions.*.options.*.dimension_codes.*' => ['required', Rule::enum(DimensionCode::class)],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $questions = $this->input('questions', []);
            if (! is_array($questions)) {
                return;
            }

            foreach ($questions as $index => $question) {
                if (! is_array($question)) {
                    continue;
                }

                $type = (string) ($question['question_type'] ?? '');
                $options = $question['options'] ?? [];

                if ($type === WeeklyQuestionType::Options->value) {
                    if (! is_array($options) || count($options) < 2) {
                        $validator->errors()->add(
                            "questions.{$index}.options",
                            'Each options question needs at least two answer options.',
                        );
                    }
                }

                if ($type === WeeklyQuestionType::Text->value && is_array($options) && count($options) > 0) {
                    $validator->errors()->add(
                        "questions.{$index}.options",
                        'Text field questions must not include answer options.',
                    );
                }
            }
        });
    }
}
