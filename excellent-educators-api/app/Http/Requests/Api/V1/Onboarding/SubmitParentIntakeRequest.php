<?php

namespace App\Http\Requests\Api\V1\Onboarding;

use Illuminate\Foundation\Http\FormRequest;

class SubmitParentIntakeRequest extends FormRequest
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
            'answers' => ['required', 'array', 'min:1'],
            'answers.*.question_id' => ['required', 'string'],
            'answers.*.option_id' => ['nullable', 'string'],
            'answers.*.text_answer' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
