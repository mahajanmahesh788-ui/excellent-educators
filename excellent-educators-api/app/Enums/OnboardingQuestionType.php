<?php

namespace App\Enums;

enum OnboardingQuestionType: string
{
    case Options = 'options';
    case Text = 'text';

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(fn (self $type) => $type->value, self::cases());
    }
}
