<?php

namespace App\Http\Requests\Api\V1\Scheduling;

use Illuminate\Foundation\Http\FormRequest;

class UpdateTeacherAvailabilityRequest extends FormRequest
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
            'work_type' => ['sometimes', 'in:full_time,part_time'],
            'weekly' => ['required', 'array', 'size:7'],
            'weekly.*.day_of_week' => ['required', 'integer', 'min:0', 'max:6'],
            'weekly.*.off' => ['sometimes', 'boolean'],
            'weekly.*.ranges' => ['sometimes', 'array'],
            'weekly.*.ranges.*.start' => ['required_with:weekly.*.ranges', 'date_format:H:i'],
            'weekly.*.ranges.*.end' => ['required_with:weekly.*.ranges', 'date_format:H:i'],
        ];
    }
}
