<?php

namespace App\Http\Requests\Api\V1\Admin;

use App\Support\AppSettings;
use Illuminate\Foundation\Http\FormRequest;

class UpdateAppSettingsRequest extends FormRequest
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
        $rules = [
            'values' => ['sometimes', 'array'],
            'max_active_students' => ['sometimes', 'integer', 'min:1', 'max:500'],
            'values.max_active_students' => ['sometimes', 'integer', 'min:1', 'max:500'],
        ];

        foreach (app(AppSettings::class)->catalog() as $item) {
            $key = (string) $item['key'];
            if ($key === AppSettings::MAX_ACTIVE_STUDENTS) {
                continue;
            }
            $rule = match ($item['type']) {
                'integer' => ['sometimes', 'integer', 'min:'.($item['min'] ?? 0), 'max:'.($item['max'] ?? 999999)],
                'boolean' => ['sometimes', 'boolean'],
                default => ['sometimes', 'string', 'max:2000'],
            };
            $rules[$key] = $rule;
            $rules['values.'.$key] = $rule;
        }

        return $rules;
    }
}
