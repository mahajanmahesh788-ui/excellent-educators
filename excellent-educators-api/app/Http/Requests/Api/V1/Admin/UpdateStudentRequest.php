<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Support\PhoneNumber;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateStudentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('phone')) {
            $this->merge([
                'phone' => PhoneNumber::normalize($this->input('phone')),
            ]);
        }

        if ($this->has('whatsapp_number')) {
            $this->merge([
                'whatsapp_number' => PhoneNumber::normalize($this->input('whatsapp_number')),
            ]);
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'career_compass_level_id' => ['sometimes', 'ulid', 'exists:career_compass_levels,id'],
            'class_grade' => ['sometimes', 'integer', 'min:5', 'max:12'],
            'address' => ['nullable', 'string', 'max:1000'],
            'phone' => [
                'sometimes',
                'string',
                'min:10',
                'max:15',
                Rule::unique('student_profiles', 'phone')->ignore($this->route('student')),
            ],
            'whatsapp_number' => ['nullable', 'string', 'min:10', 'max:15'],
            'guardian_name' => ['nullable', 'string', 'max:255'],
            'guardian_phone' => ['nullable', 'string', 'max:32'],
            'status' => ['sometimes', 'in:active,inactive'],
            'student_code' => ['prohibited'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'phone.unique' => 'This phone number is already registered.',
        ];
    }
}
