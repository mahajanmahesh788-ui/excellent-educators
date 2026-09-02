<?php

namespace App\Http\Requests\Api\V1\AdminRequests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAdminRequestRequest extends FormRequest
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
        return [
            'subtitle' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'max:5000'],
        ];
    }
}
