<?php

namespace App\Support;

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
}
