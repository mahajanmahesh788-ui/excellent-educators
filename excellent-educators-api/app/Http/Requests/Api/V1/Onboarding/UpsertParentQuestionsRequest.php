<?php

namespace App\Http\Requests\Api\V1\Onboarding;

use App\Enums\OnboardingQuestionType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpsertParentQuestionsRequest extends FormRequest
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
            'questions' => ['required', 'array', 'max:30'],
            'questions.*.id' => ['nullable', 'string'],
            'questions.*.question_text' => ['required', 'string', 'max:500'],
            'questions.*.question_type' => ['required', 'string', Rule::in(OnboardingQuestionType::values())],
            'questions.*.is_active' => ['sometimes', 'boolean'],
            'questions.*.options' => ['nullable', 'array', 'max:50'],
            'questions.*.options.*.id' => ['nullable', 'string'],
            'questions.*.options.*.option_text' => ['required_with:questions.*.options', 'string', 'max:255'],
            'questions.*.options.*.is_active' => ['sometimes', 'boolean'],
        ];
    }
}
