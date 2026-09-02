<?php

namespace App\Enums;

enum DimensionCode: string
{
    case Personality = 'P';
    case Interests = 'I';
    case Confidence = 'CF';
    case Leadership = 'L';
    case Communication = 'CM';
    case DecisionMaking = 'DM';
    case Creativity = 'CR';
    case Curiosity = 'CU';
    case Teamwork = 'TW';
    case FutureAspirations = 'FA';

    public function label(): string
    {
        return match ($this) {
            self::Personality => 'Personality',
            self::Interests => 'Interests',
            self::Confidence => 'Confidence',
            self::Leadership => 'Leadership',
            self::Communication => 'Communication',
            self::DecisionMaking => 'Decision-making',
            self::Creativity => 'Creativity',
            self::Curiosity => 'Curiosity',
            self::Teamwork => 'Teamwork',
            self::FutureAspirations => 'Future Aspirations',
        };
    }

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(fn (self $code) => $code->value, self::cases());
    }
}
