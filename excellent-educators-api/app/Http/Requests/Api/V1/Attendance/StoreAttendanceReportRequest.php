<?php

namespace App\Http\Requests\Api\V1\Attendance;

use App\Enums\AttendanceIssueType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreAttendanceReportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'message' => ['required', 'string', 'min:3', 'max:2000'],
            'issue_type' => [
                'sometimes',
                'string',
                Rule::in([
                    AttendanceIssueType::TeacherDidNotJoin->value,
                    AttendanceIssueType::StudentDidNotJoin->value,
                ]),
            ],
        ];
    }
}
