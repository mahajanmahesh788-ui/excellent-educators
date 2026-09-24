<?php

namespace App\Enums;

enum AdminAccountType: string
{
    case Admin = 'admin';
    case Agent = 'agent';

    public function label(): string
    {
        return match ($this) {
            self::Admin => 'Admin',
            self::Agent => 'Agent',
        };
    }

    public function isAgent(): bool
    {
        return $this === self::Agent;
    }
}
