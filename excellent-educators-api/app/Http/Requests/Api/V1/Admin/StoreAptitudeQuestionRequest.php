<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Support\OptionDimensionCodeRules;
use Illuminate\Foundation\Http\FormRequest;

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
            ...OptionDimensionCodeRules::forField('options.*.dimension_codes'),
            'options.*.display_order' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
