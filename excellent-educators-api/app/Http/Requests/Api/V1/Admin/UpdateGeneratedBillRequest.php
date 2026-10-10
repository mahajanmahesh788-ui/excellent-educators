<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Enums\Gender;
use App\Support\PhoneNumber;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateGeneratedBillRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $merge = [];
        foreach (['phone', 'whatsapp_number', 'guardian_phone'] as $field) {
            if ($this->has($field)) {
                $merge[$field] = PhoneNumber::normalize($this->input($field));
            }
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
            'full_name' => ['sometimes', 'required', 'string', 'max:255'],
            'email' => ['nullable', 'email', 'max:255'],
            'phone' => ['sometimes', 'required', 'string', 'min:10', 'max:15'],
            'whatsapp_number' => ['nullable', 'string', 'min:10', 'max:15'],
            'address' => ['nullable', 'string', 'max:1000'],
            'class_grade' => ['sometimes', 'required', 'integer', 'min:5', 'max:12'],
            'gender' => ['sometimes', 'required', Rule::enum(Gender::class)],
            'guardian_name' => ['nullable', 'string', 'max:255'],
            'guardian_phone' => ['nullable', 'string', 'max:32'],
            'payment_type' => ['sometimes', 'required', Rule::in(['full', 'partial'])],
            'payment_mode' => ['nullable', Rule::in(['online', 'offline'])],
            'total_amount' => ['sometimes', 'required', 'numeric', 'min:0'],
            'paid_amount' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'bill_date' => ['nullable', 'date'],
        ];
    }
}
