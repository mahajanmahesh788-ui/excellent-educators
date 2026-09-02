<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Enums\DimensionCode;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreAptitudeQuestionRequest extends FormRequest
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
            'question_text' => ['required', 'string', 'max:2000'],
            'display_order' => ['nullable', 'integer', 'min:1'],
            'options' => ['required', 'array', 'min:1'],
            'options.*.option_text' => ['required', 'string', 'max:1000'],
            'options.*.dimension_codes' => ['required', 'array', 'min:1', 'max:3'],
            'options.*.dimension_codes.*' => ['required', Rule::enum(DimensionCode::class)],
            'options.*.display_order' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
