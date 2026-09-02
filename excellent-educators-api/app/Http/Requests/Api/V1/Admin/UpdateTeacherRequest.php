<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Support\PhoneNumber;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateTeacherRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $merge = [];

        if ($this->has('phone')) {
            $merge['phone'] = PhoneNumber::normalize($this->input('phone'));
        }

        if ($this->has('whatsapp_number')) {
            $merge['whatsapp_number'] = PhoneNumber::normalize($this->input('whatsapp_number'));
        }

        if ($merge !== []) {
            $this->merge($merge);
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'employee_code' => [
                'nullable',
                'string',
                'max:32',
                Rule::unique('teacher_profiles', 'employee_code')->ignore($this->route('teacher')),
            ],
            'phone' => ['nullable', 'string', 'min:10', 'max:15'],
            'whatsapp_number' => ['nullable', 'string', 'min:10', 'max:15'],
            'status' => ['sometimes', 'in:active,inactive'],
            'roles' => ['sometimes', 'array', 'min:1'],
            'roles.*' => ['in:common_teacher,master_teacher'],
        ];
    }
}
