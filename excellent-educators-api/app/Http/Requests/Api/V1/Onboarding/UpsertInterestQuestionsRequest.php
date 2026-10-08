<?php

namespace App\Http\Requests\Api\V1\Onboarding;

use Illuminate\Foundation\Http\FormRequest;

class UpsertInterestQuestionsRequest extends FormRequest
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
            'questions.*.allow_other' => ['sometimes', 'boolean'],
            'questions.*.max_selections' => ['sometimes', 'integer', 'min:1', 'max:5'],
            'questions.*.is_active' => ['sometimes', 'boolean'],
            'questions.*.options' => ['required', 'array', 'min:1', 'max:50'],
            'questions.*.options.*.id' => ['nullable', 'string'],
            'questions.*.options.*.option_text' => ['required', 'string', 'max:100'],
            'questions.*.options.*.is_active' => ['sometimes', 'boolean'],
        ];
    }
}
