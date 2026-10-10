<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;

class PromoteStudentRequest extends FormRequest
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
        $isMasterTeacherPromote = $this->is('api/v1/master-teacher/students/*/promote');

        return [
            'level_id' => ['required', 'ulid', 'exists:academic_levels,id'],
            // Teachers must explain why they are requesting the upgrade.
            'reason' => [
                $isMasterTeacherPromote ? 'required' : 'nullable',
                'string',
                'min:10',
                'max:2000',
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'reason.required' => 'Please explain why you are upgrading this student.',
            'reason.min' => 'Please enter at least 10 characters explaining the upgrade.',
        ];
    }
}
