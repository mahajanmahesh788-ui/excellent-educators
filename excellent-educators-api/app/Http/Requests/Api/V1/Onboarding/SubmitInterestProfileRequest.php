<?php

namespace App\Http\Requests\Api\V1\Onboarding;

use Illuminate\Foundation\Http\FormRequest;

class SubmitInterestProfileRequest extends FormRequest
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
            'answers.*.option_ids' => ['nullable', 'array', 'max:5'],
            'answers.*.option_ids.*' => ['string'],
            'answers.*.other_text' => ['nullable', 'string', 'max:25'],
        ];
    }
}
