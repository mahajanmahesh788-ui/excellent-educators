<?php

namespace App\Http\Requests\Api\V1\Scheduling;

use Illuminate\Foundation\Http\FormRequest;

class StoreTeacherAvailabilityOverrideRequest extends FormRequest
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
            'date' => ['required', 'date'],
            'type' => ['required', 'in:available,unavailable'],
            'start' => ['nullable', 'date_format:H:i'],
            'end' => ['nullable', 'date_format:H:i'],
            'ranges' => ['nullable', 'array'],
            'ranges.*.start' => ['required_with:ranges', 'date_format:H:i'],
            'ranges.*.end' => ['required_with:ranges', 'date_format:H:i'],
        ];
    }
}
