<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;

class LoginPageContent extends Model
{
    use HasUlids;

    protected $fillable = [
        'tagline',
        'headline',
        'description',
        'pillars',
        'mission_quote',
        'form_title',
        'form_subtitle',
        'forgot_form_title',
        'forgot_form_subtitle',
    ];

    protected function casts(): array
    {
        return [
            'pillars' => 'array',
        ];
    }

    public static function current(): self
    {
        $record = static::query()->first();

        if ($record !== null) {
            return $record;
        }

        return static::query()->create(static::defaultAttributes());
    }

    /**
     * @return array<string, mixed>
     */
    public static function defaultAttributes(): array
    {
        return [
            'tagline' => 'Building Careers. Creating Leaders.',
            'headline' => "Student development\nwith purpose and direction",
            'description' => 'Excellent Educators is not a traditional tuition or exam-coaching institute. We focus on career guidance, personality development, essential skills and structured student growth.',
            'pillars' => [
                [
                    'icon' => 'person_search_outlined',
                    'title' => 'Understand first',
                    'body' => 'We start by understanding each student before shaping their path.',
                ],
                [
                    'icon' => 'foundation_outlined',
                    'title' => 'Build foundations',
                    'body' => 'A shared base of skills and habits supports everything that follows.',
                ],
                [
                    'icon' => 'route_outlined',
                    'title' => 'Personalise next',
                    'body' => 'Guidance adapts to strengths, goals and the choices ahead.',
                ],
                [
                    'icon' => 'insights_outlined',
                    'title' => 'Review progress',
                    'body' => 'Regular feedback keeps development structured and on track.',
                ],
            ],
            'mission_quote' => 'Help students understand themselves, build essential skills and make better-informed decisions for the future.',
            'form_title' => 'Welcome back',
            'form_subtitle' => 'Sign in to track feedback, assessments and your development journey.',
            'forgot_form_title' => 'Reset your password',
            'forgot_form_subtitle' => 'Enter the email you use to sign in. Students and teachers can use this form.',
        ];
    }
}
