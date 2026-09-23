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
     * @return list<string>
     */
    public static function allowedIcons(): array
    {
        return [
            'person_search_outlined',
            'foundation_outlined',
            'route_outlined',
            'insights_outlined',
            'school_outlined',
            'psychology_outlined',
            'auto_awesome_outlined',
            'groups_outlined',
            'verified_outlined',
            'star_outline',
            'public_outlined',
            'workspace_premium_outlined',
            'military_tech_outlined',
            'favorite_outline',
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $icons = Rule::in(self::allowedIcons());

        return [
            'tagline' => ['sometimes', 'string', 'max:255'],
            'headline' => ['sometimes', 'string', 'max:500'],
            'description' => ['sometimes', 'string', 'max:5000'],
            'pillars' => ['sometimes', 'array', 'min:1', 'max:6'],
            'pillars.*.icon' => ['required', 'string', $icons],
            'pillars.*.title' => ['required', 'string', 'max:120'],
            'pillars.*.body' => ['required', 'string', 'max:500'],
            'trust_signals' => ['sometimes', 'array', 'max:4'],
            'trust_signals.*.icon' => ['required', 'string', $icons],
            'trust_signals.*.value' => ['required', 'string', 'max:80'],
            'trust_signals.*.label' => ['required', 'string', 'max:160'],
            'why_heading' => ['nullable', 'string', 'max:255'],
            'stories' => ['sometimes', 'array', 'max:4'],
            'stories.*.title' => ['required', 'string', 'max:160'],
            'stories.*.body' => ['required', 'string', 'max:1000'],
            'stories.*.image_url' => ['required', 'string', 'max:2000', 'url'],
            'stories.*.image_on_left' => ['sometimes', 'boolean'],
            'testimonials_heading' => ['nullable', 'string', 'max:255'],
            'testimonials' => ['sometimes', 'array', 'max:6'],
            'testimonials.*.quote' => ['required', 'string', 'max:500'],
            'testimonials.*.attribution' => ['required', 'string', 'max:120'],
            'testimonials.*.role' => ['nullable', 'string', 'max:80'],
            'mission_quote' => ['nullable', 'string', 'max:2000'],
            'form_title' => ['sometimes', 'string', 'max:255'],
            'form_subtitle' => ['sometimes', 'string', 'max:2000'],
            'forgot_form_title' => ['sometimes', 'string', 'max:255'],
            'forgot_form_subtitle' => ['sometimes', 'string', 'max:2000'],
        ];
    }
}
