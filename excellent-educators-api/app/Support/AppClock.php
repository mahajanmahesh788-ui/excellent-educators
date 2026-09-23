<?php

namespace App\Support;

use DateTimeInterface;
use Illuminate\Support\Carbon;

final class AppClock
{
    public static function now(): Carbon
    {
        return Carbon::now(config('app.timezone'));
    }

    public static function todayString(): string
    {
        return self::now()->toDateString();
    }

    /**
     * @return array{year: int, month: int}
     */
    public static function currentYearMonth(): array
    {
        $now = self::now();

        return [
            'year' => $now->year,
            'month' => $now->month,
        ];
    }

    public static function formatTime(?DateTimeInterface $at): string
    {
        if ($at === null) {
            return '';
        }

        return Carbon::parse($at)->timezone(config('app.timezone'))->format('g:i A');
    }
}
