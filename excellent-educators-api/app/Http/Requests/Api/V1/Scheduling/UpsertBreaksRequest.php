<?php

namespace App\Http\Requests\Api\V1\Scheduling;

use Illuminate\Foundation\Http\FormRequest;

class UpsertBreaksRequest extends FormRequest
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
            'breakfast_start' => ['nullable', 'date_format:H:i'],
            'lunch_start' => ['nullable', 'date_format:H:i'],
        ];
    }
}
