<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Support\OptionDimensionCodeRules;
use Illuminate\Foundation\Http\FormRequest;

class StoreAptitudeOptionRequest extends FormRequest
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
            'option_text' => ['required', 'string', 'max:1000'],
            ...OptionDimensionCodeRules::forField(),
            'display_order' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
