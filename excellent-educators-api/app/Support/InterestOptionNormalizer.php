<?php

namespace App\Support;

final class InterestOptionNormalizer
{
    public static function normalize(string $text): string
    {
        $collapsed = preg_replace('/\s+/u', ' ', trim($text)) ?? '';

        return mb_strtolower($collapsed);
    }

    public static function displayLabel(string $text): string
    {
        $collapsed = preg_replace('/\s+/u', ' ', trim($text)) ?? '';

        return mb_substr($collapsed, 0, 25);
    }
}
