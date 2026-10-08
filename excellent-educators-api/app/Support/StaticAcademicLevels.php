<?php

namespace App\Support;

use App\Models\AcademicLevel;

final class StaticAcademicLevels
{
    public const MIN = 1;

    public const MAX = 10;

    /**
     * @return list<int>
     */
    public static function allNumbers(): array
    {
        return range(self::MIN, self::MAX);
    }

    public static function label(int $number): string
    {
        return 'Level '.$number;
    }

    public static function isValidNumber(int $number): bool
    {
        return $number >= self::MIN && $number <= self::MAX;
    }

    public static function parseNumberFromName(?string $name): ?int
    {
        if ($name === null) {
            return null;
        }

        if (preg_match('/^Level\s+(\d+)$/i', trim($name), $matches) !== 1) {
            return null;
        }

        $number = (int) $matches[1];

        return self::isValidNumber($number) ? $number : null;
    }

    /**
     * @return list<int>
     */
    public static function availableNumbers(): array
    {
        $used = AcademicLevel::query()
            ->whereNotNull('number')
            ->pluck('number')
            ->map(fn ($n) => (int) $n)
            ->all();

        return array_values(array_filter(
            self::allNumbers(),
            fn (int $n) => ! in_array($n, $used, true),
        ));
    }
}
