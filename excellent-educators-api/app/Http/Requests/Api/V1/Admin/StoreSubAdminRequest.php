<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Enums\Gender;
use App\Enums\PermissionName;
use App\Support\PhoneNumber;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class StoreSubAdminRequest extends FormRequest
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
        $keys = array_map(fn (PermissionName $p) => $p->value, PermissionName::subAdminToggles());

        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', Rule::unique('users', 'email')->whereNull('deleted_at')],
            'password' => ['required', Password::defaults()],
            'phone' => ['required', 'string', 'min:10', 'max:15', 'unique:admin_profiles,phone'],
            'gender' => ['required', Rule::enum(Gender::class)],
            'permissions' => ['sometimes'],
            'permissions.*' => ['nullable'],
        ] + collect($keys)->mapWithKeys(fn (string $key) => ["permissions.{$key}" => ['sometimes', 'boolean']])->all();
    }
}
