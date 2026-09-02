<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreBatchRequest extends FormRequest
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
            'career_compass_level_id' => ['required', 'ulid', 'exists:career_compass_levels,id'],
            'name' => ['required', 'string', 'max:255'],
            'academic_year' => ['required', 'integer', 'min:2000', 'max:2100'],
            'starts_on' => ['nullable', 'date'],
            'ends_on' => ['nullable', 'date', 'after_or_equal:starts_on'],
        ];
    }
}
