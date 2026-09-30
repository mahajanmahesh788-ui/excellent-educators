<?php

namespace App\Support;

final class PolicyTerms
{
    /**
     * Bump this when Terms / Privacy / Refund material changes require re-acceptance.
     */
    public const CURRENT_VERSION = '2026-09-29';

    public static function currentVersion(): string
    {
        return self::CURRENT_VERSION;
    }
}
