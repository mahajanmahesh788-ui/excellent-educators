<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Enums\Gender;
use App\Support\MentorProfileRules;
use App\Support\PhoneNumber;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class StoreTeacherRequest extends FormRequest
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

        foreach (['photo_url', 'professional_title', 'bio', 'experience_summary'] as $field) {
            if ($this->exists($field) && is_string($this->input($field)) && trim((string) $this->input($field)) === '') {
                $merge[$field] = null;
            }
        }

        if (! $this->has('roles')) {
            $merge['roles'] = ['master_teacher'];
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
            'name' => ['required', 'string', 'max:255'],
            'gender' => ['required', Rule::enum(Gender::class)],
            'email' => ['required', 'email', Rule::unique('users', 'email')->whereNull('deleted_at')],
            'password' => ['required', Password::defaults()],
            'employee_code' => ['nullable', 'string', 'max:32', 'unique:teacher_profiles,employee_code'],
            'phone' => ['nullable', 'string', 'min:10', 'max:15'],
            'whatsapp_number' => ['nullable', 'string', 'min:10', 'max:15'],
            'address' => ['nullable', 'string', 'max:1000'],
            'roles' => ['sometimes', 'array', 'min:1'],
            'roles.*' => ['in:master_teacher'],
            ...MentorProfileRules::fields(),
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'email.unique' => 'This email is already registered.',
        ];
    }
}
