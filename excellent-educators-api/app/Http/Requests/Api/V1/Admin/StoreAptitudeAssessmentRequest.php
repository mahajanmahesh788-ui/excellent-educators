<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Enums\DimensionCode;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreAptitudeAssessmentRequest extends FormRequest
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
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:5000'],
            'career_compass_level_id' => ['required', 'ulid', 'exists:career_compass_levels,id'],
            'questions' => ['sometimes', 'array'],
            'questions.*.question_text' => ['required', 'string', 'max:2000'],
            'questions.*.display_order' => ['nullable', 'integer', 'min:1'],
            'questions.*.options' => ['required', 'array', 'min:1'],
            'questions.*.options.*.option_text' => ['required', 'string', 'max:1000'],
            'questions.*.options.*.dimension_codes' => ['required', 'array', 'min:1', 'max:3'],
            'questions.*.options.*.dimension_codes.*' => ['required', Rule::enum(DimensionCode::class)],
            'questions.*.options.*.display_order' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
