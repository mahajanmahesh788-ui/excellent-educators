<?php

namespace App\Http\Requests\Api\V1\Scheduling;

use Illuminate\Foundation\Http\FormRequest;

class AssignLeaveReplacementRequest extends FormRequest
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
            'replacement_teacher_id' => ['nullable', 'ulid', 'exists:teacher_profiles,id'],
        ];
    }
}
