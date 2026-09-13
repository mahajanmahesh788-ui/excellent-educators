<?php

namespace App\Http\Requests\Api\V1\Scheduling;

use App\Enums\SessionBookingType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreBookingRequest extends FormRequest
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
            'student_id' => ['sometimes', 'string', 'exists:student_profiles,id'],
            'teacher_id' => ['required', 'string', 'exists:teacher_profiles,id'],
            'type' => ['sometimes', Rule::enum(SessionBookingType::class)],
            'date' => ['required', 'date'],
            'start' => ['required', 'date_format:H:i'],
        ];
    }
}
