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

    public static function formatDisplayDate(mixed $date, string $fallback = ''): string
    {
        if ($date === null || $date === '') {
            return $fallback;
        }

        try {
            return Carbon::parse($date)->timezone(config('app.timezone'))->format('d-M-Y');
        } catch (\Throwable) {
            return $fallback !== '' ? $fallback : (string) $date;
        }
    }

    /**
     * Human label like "12-Sep-2026 at 4:30 PM".
     */
    public static function formatWhen(
        mixed $date,
        ?DateTimeInterface $startsAt = null,
        string $fallback = 'the scheduled time',
    ): string {
        $displayDate = self::formatDisplayDate($date);
        $time = self::formatTime($startsAt);
        $label = trim($displayDate.($time !== '' ? ' at '.$time : ''));

        return $label !== '' ? $label : $fallback;
    }
}
