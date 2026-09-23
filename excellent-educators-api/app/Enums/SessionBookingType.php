<?php

namespace App\Enums;

enum SessionBookingType: string
{
    case IntroductionCall = 'introduction_call';
    case MasterClass = 'master_class';

    public function label(): string
    {
        return match ($this) {
            self::IntroductionCall => 'Introduction Call',
            self::MasterClass => 'Master Class',
        };
    }

    public static function fromMixed(mixed $value): ?self
    {
        if ($value instanceof self) {
            return $value;
        }

        return self::tryFrom((string) $value);
    }
}
