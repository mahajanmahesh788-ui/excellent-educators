<?php

namespace App\Http\Requests\Api\V1\Attendance;

use App\Enums\AttendanceDecision;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ResolveAttendanceIssueRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'decision' => ['required', 'string', Rule::enum(AttendanceDecision::class)],
            'notes' => ['nullable', 'string', 'max:4000'],
        ];
    }
}
