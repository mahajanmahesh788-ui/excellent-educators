<?php

namespace App\Support;

abstract class MentorProfileRules
{
    /**
     * @return array<string, mixed>
     */
    public static function fields(bool $required = false): array
    {
        $presence = $required ? ['required'] : ['sometimes', 'nullable'];

        return [
            'photo_url' => [...$presence, 'nullable', 'string', 'max:2048', 'url'],
            'professional_title' => [...$presence, 'string', 'max:120'],
            'bio' => [...$presence, 'string', 'max:2000'],
            'experience_summary' => [...$presence, 'string', 'max:255'],
            'guidance_areas' => [...$presence, 'array', 'max:20'],
            'guidance_areas.*' => ['required', 'string', 'max:80'],
            'mentoring_approach' => [...$presence, 'array', 'max:20'],
            'mentoring_approach.*' => ['required', 'string', 'max:80'],
            'education' => [...$presence, 'array', 'max:20'],
            'education.*.degree' => ['required_with:education', 'string', 'max:160'],
            'education.*.institution' => ['required_with:education', 'string', 'max:160'],
            'education.*.year' => ['nullable', 'string', 'max:20'],
            'certifications' => [...$presence, 'array', 'max:20'],
            'certifications.*.name' => ['required_with:certifications', 'string', 'max:160'],
            'certifications.*.organization' => ['nullable', 'string', 'max:160'],
            'certifications.*.year' => ['nullable', 'string', 'max:20'],
            'experience' => [...$presence, 'array', 'max:20'],
            'experience.*.organization' => ['required_with:experience', 'string', 'max:160'],
            'experience.*.role' => ['required_with:experience', 'string', 'max:160'],
            'experience.*.duration' => ['nullable', 'string', 'max:80'],
        ];
    }

    /**
     * @param  array<string, mixed>  $input
     * @return array<string, mixed>
     */
    public static function extract(array $input): array
    {
        $keys = [
            'photo_url',
            'professional_title',
            'bio',
            'experience_summary',
            'guidance_areas',
            'mentoring_approach',
            'education',
            'certifications',
            'experience',
        ];

        $profile = [];
        foreach ($keys as $key) {
            if (array_key_exists($key, $input)) {
                $value = $input[$key];
                if (in_array($key, ['photo_url', 'professional_title', 'bio', 'experience_summary'], true)
                    && is_string($value)
                    && trim($value) === '') {
                    $value = null;
                }
                $profile[$key] = $value;
            }
        }

        return $profile;
    }
}
