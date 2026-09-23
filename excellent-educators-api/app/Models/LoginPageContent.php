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
        'trust_signals',
        'why_heading',
        'stories',
        'testimonials_heading',
        'testimonials',
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
            'trust_signals' => 'array',
            'stories' => 'array',
            'testimonials' => 'array',
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
            'trust_signals' => [
                [
                    'icon' => 'verified_outlined',
                    'value' => 'Mentor first',
                    'label' => 'one guide for the full journey',
                ],
                [
                    'icon' => 'star_outline',
                    'value' => 'Weekly rhythm',
                    'label' => 'journal, class, and review',
                ],
                [
                    'icon' => 'public_outlined',
                    'value' => 'Live 1:1',
                    'label' => 'intro calls and master classes',
                ],
            ],
            'why_heading' => 'A clearer way to grow',
            'pillars' => [
                [
                    'icon' => 'person_search_outlined',
                    'title' => 'Start with the student',
                    'body' => 'We learn how they think, what they avoid, and where they already shine — then we shape the path around that, not a generic syllabus.',
                ],
                [
                    'icon' => 'foundation_outlined',
                    'title' => 'Skills before shortcuts',
                    'body' => 'Habits, communication, and career sense sit beside academics. The aim is a stronger person, not a last-minute exam sprint.',
                ],
                [
                    'icon' => 'insights_outlined',
                    'title' => 'Feedback that lands',
                    'body' => 'Mentors and master teachers write monthly notes you can act on. Progress is visible, not guessed at the end of the term.',
                ],
            ],
            'stories' => [
                [
                    'title' => 'Sessions that fit real weeks',
                    'body' => 'Book an introduction call or a master class around school hours — not the other way around. One link, one teacher, one focused slot.',
                    'image_url' => 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1400&q=80',
                    'image_on_left' => true,
                ],
                [
                    'title' => 'Mentors who stay on the path',
                    'body' => 'The same faculty follows the student from first conversation through weekly learning. Guidance is personal, not a revolving door of tutors.',
                    'image_url' => 'https://images.unsplash.com/photo-1577896851231-70ef18881754?auto=format&fit=crop&w=1400&q=80',
                    'image_on_left' => false,
                ],
                [
                    'title' => 'A journal that proves the week',
                    'body' => 'Each week has a video, questions, and a written trail. Students see what they finished. Mentors see where to push next.',
                    'image_url' => 'https://images.unsplash.com/photo-1456513080080-77db1ea6bb6f?auto=format&fit=crop&w=1400&q=80',
                    'image_on_left' => true,
                ],
            ],
            'testimonials_heading' => 'Voices from our community',
            'testimonials' => [
                [
                    'quote' => 'The monthly notes finally told us what to work on at home. We stopped guessing.',
                    'attribution' => 'Kavita',
                    'role' => 'Parent',
                ],
                [
                    'quote' => 'My introduction call felt like a real conversation. After that, the weekly journal made sense.',
                    'attribution' => 'Arjun',
                    'role' => 'Student',
                ],
                [
                    'quote' => 'I can see attendance, journal weeks, and ratings in one place. Mentoring is easier to do well.',
                    'attribution' => 'Meera',
                    'role' => 'Master Teacher',
                ],
                [
                    'quote' => 'He started showing up prepared. The structure did more than extra tuition ever did.',
                    'attribution' => 'Sanjay',
                    'role' => 'Parent',
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
