<?php

namespace App\Enums;

enum InterestOptionSource: string
{
    case Admin = 'admin';
    case Student = 'student';

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(fn (self $source) => $source->value, self::cases());
    }
}
