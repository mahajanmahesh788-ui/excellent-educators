<?php

namespace App\Http\Requests\Api\V1\Learning;

use App\Enums\WeeklyQuestionType;
use App\Support\OptionDimensionCodeRules;
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
            'comprehension_paragraph' => ['nullable', 'string', 'max:20000'],
            'questions' => ['required', 'array', 'min:1'],
            'questions.*.question_text' => ['required', 'string', 'max:2000'],
            'questions.*.question_type' => ['required', Rule::enum(WeeklyQuestionType::class)],
            'questions.*.options' => ['nullable', 'array'],
            'questions.*.options.*.option_text' => ['required', 'string', 'max:500'],
            ...OptionDimensionCodeRules::forField('questions.*.options.*.dimension_codes'),
            'comprehension_questions' => ['nullable', 'array'],
            'comprehension_questions.*.question_text' => ['required', 'string', 'max:2000'],
            'comprehension_questions.*.question_type' => ['required', Rule::enum(WeeklyQuestionType::class)],
            'comprehension_questions.*.options' => ['nullable', 'array'],
            'comprehension_questions.*.options.*.option_text' => ['required', 'string', 'max:500'],
            ...OptionDimensionCodeRules::forField('comprehension_questions.*.options.*.dimension_codes'),
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $this->assertQuestionGroups($validator, 'questions', $this->input('questions', []));
            $this->assertQuestionGroups(
                $validator,
                'comprehension_questions',
                $this->input('comprehension_questions', []),
            );

            $paragraph = trim((string) $this->input('comprehension_paragraph', ''));
            $comprehensionQuestions = $this->input('comprehension_questions', []);
            $hasComprehensionQuestions = is_array($comprehensionQuestions) && count($comprehensionQuestions) > 0;

            if ($paragraph !== '' && ! $hasComprehensionQuestions) {
                $validator->errors()->add(
                    'comprehension_questions',
                    'Add at least one comprehension question, or clear the paragraph.',
                );
            }

            if ($hasComprehensionQuestions && $paragraph === '') {
                $validator->errors()->add(
                    'comprehension_paragraph',
                    'Enter a comprehension paragraph when comprehension questions are included.',
                );
            }
        });
    }

    /**
     * @param  mixed  $questions
     */
    private function assertQuestionGroups(Validator $validator, string $prefix, mixed $questions): void
    {
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
                        "{$prefix}.{$index}.options",
                        'Each options question needs at least two answer options.',
                    );
                }
            }

            if ($type === WeeklyQuestionType::Text->value && is_array($options) && count($options) > 0) {
                $validator->errors()->add(
                    "{$prefix}.{$index}.options",
                    'Text field questions must not include answer options.',
                );
            }
        }
    }
}
