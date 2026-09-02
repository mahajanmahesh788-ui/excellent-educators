<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Enums\DimensionCode;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

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
            'dimension_codes' => ['required', 'array', 'min:1', 'max:3'],
            'dimension_codes.*' => ['required', Rule::enum(DimensionCode::class)],
            'display_order' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
