<?php

namespace App\Http\Requests\Api\V1\AdminRequests;

use Illuminate\Foundation\Http\FormRequest;

class ResolveAdminRequestRequest extends FormRequest
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
            'apply_action' => ['sometimes', 'boolean'],
        ];
    }
}
