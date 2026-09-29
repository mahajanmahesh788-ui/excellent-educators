<?php

namespace App\Enums;

enum PaymentPlanType: string
{
    case Full = 'full';
    case Partial = 'partial';

    public function label(): string
    {
        return match ($this) {
            self::Full => 'Full Payment',
            self::Partial => 'Partial Payment',
        };
    }
}
