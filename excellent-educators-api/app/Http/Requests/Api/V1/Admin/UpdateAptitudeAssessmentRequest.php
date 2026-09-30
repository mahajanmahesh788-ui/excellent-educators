<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Support\OptionDimensionCodeRules;
use Illuminate\Foundation\Http\FormRequest;

class UpdateAptitudeAssessmentRequest extends FormRequest
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
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:5000'],
            'questions' => ['sometimes', 'array'],
            'questions.*.question_text' => ['required_with:questions', 'string', 'max:2000'],
            'questions.*.display_order' => ['nullable', 'integer', 'min:1'],
            'questions.*.options' => ['required_with:questions', 'array', 'min:1'],
            'questions.*.options.*.option_text' => ['required', 'string', 'max:1000'],
            ...OptionDimensionCodeRules::forField('questions.*.options.*.dimension_codes'),
            'questions.*.options.*.display_order' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
