<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Enums\Gender;
use App\Enums\UserStatus;
use App\Support\PhoneNumber;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class UpdateSubAdminRequest extends FormRequest
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
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $userId = $this->route('subAdmin')?->id;

        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', Rule::unique('users', 'email')->ignore($userId)->whereNull('deleted_at')],
            'password' => ['sometimes', 'nullable', Password::defaults()],
            'phone' => [
                'sometimes',
                'string',
                'min:10',
                'max:15',
                Rule::unique('admin_profiles', 'phone')->ignore($userId, 'user_id'),
            ],
            'gender' => ['sometimes', Rule::enum(Gender::class)],
            'status' => ['sometimes', Rule::enum(UserStatus::class)],
            'permissions' => ['sometimes'],
        ];
    }
}
