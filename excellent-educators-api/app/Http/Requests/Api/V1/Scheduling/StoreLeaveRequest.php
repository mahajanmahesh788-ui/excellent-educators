<?php

namespace App\Http\Requests\Api\V1\Scheduling;

use Illuminate\Foundation\Http\FormRequest;

class StoreLeaveRequest extends FormRequest
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
            'date' => ['required', 'date', 'after_or_equal:today'],
            'is_full_day' => ['sometimes', 'boolean'],
            'reason' => ['required', 'string', 'max:255'],
            'start_time' => ['nullable', 'date_format:H:i'],
            'end_time' => ['nullable', 'date_format:H:i', 'after:start_time'],
            'slot_starts' => ['nullable', 'array'],
            'slot_starts.*' => ['string', 'date_format:H:i'],
        ];
    }
}
