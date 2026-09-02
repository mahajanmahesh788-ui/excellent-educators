<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateLoginPageContentRequest extends FormRequest
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
            'tagline' => ['sometimes', 'string', 'max:255'],
            'headline' => ['sometimes', 'string', 'max:500'],
            'description' => ['sometimes', 'string', 'max:5000'],
            'pillars' => ['sometimes', 'array', 'min:1', 'max:6'],
            'pillars.*.icon' => ['required', 'string', Rule::in([
                'person_search_outlined',
                'foundation_outlined',
                'route_outlined',
                'insights_outlined',
                'school_outlined',
                'psychology_outlined',
                'auto_awesome_outlined',
                'groups_outlined',
            ])],
            'pillars.*.title' => ['required', 'string', 'max:120'],
            'pillars.*.body' => ['required', 'string', 'max:500'],
            'mission_quote' => ['nullable', 'string', 'max:2000'],
            'form_title' => ['sometimes', 'string', 'max:255'],
            'form_subtitle' => ['sometimes', 'string', 'max:2000'],
            'forgot_form_title' => ['sometimes', 'string', 'max:255'],
            'forgot_form_subtitle' => ['sometimes', 'string', 'max:2000'],
        ];
    }
}
