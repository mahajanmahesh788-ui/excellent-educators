<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Enums\Gender;
use App\Support\PhoneNumber;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class StoreStudentRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', Rule::unique('users', 'email')->whereNull('deleted_at')],
            'password' => ['required', Password::defaults()],
            'class_grade' => ['required', 'integer', 'min:5', 'max:12'],
            'gender' => ['required', Rule::enum(Gender::class)],
            'phone' => ['required', 'string', 'min:10', 'max:15', 'unique:student_profiles,phone'],
            'whatsapp_number' => ['nullable', 'string', 'min:10', 'max:15'],
            'address' => ['nullable', 'string', 'max:1000'],
            'academic_year' => ['sometimes', 'integer', 'min:2000', 'max:2100'],
            'guardian_name' => ['nullable', 'string', 'max:255'],
            'guardian_phone' => ['nullable', 'string', 'max:32'],
            'student_code' => ['prohibited'],
            'payment' => ['nullable', 'array'],
            'payment.payment_type' => ['required_with:payment', Rule::in(['full', 'partial'])],
            'payment.preferred_mode' => ['nullable', Rule::in(['online', 'offline'])],
            'payment.total_amount' => ['nullable', 'numeric', 'min:0'],
            'payment.initial_amount' => ['nullable', 'numeric', 'min:0'],
            'payment.payment_amount' => ['nullable', 'numeric', 'min:0'],
            'payment.notes' => ['nullable', 'string', 'max:2000'],
            'payment.due_day' => ['nullable', 'integer', 'min:1', 'max:28'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'email.unique' => 'This email is already registered.',
            'phone.unique' => 'This phone number is already registered.',
        ];
    }
}
