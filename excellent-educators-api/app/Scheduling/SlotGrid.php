<?php

namespace App\Scheduling;

use Carbon\Carbon;
use Carbon\CarbonInterface;

final class SlotGrid
{
    public static function dayStart(): string
    {
        return (string) config('excellent_educators.scheduling.day_start', '06:00');
    }

    public static function dayEnd(): string
    {
        return (string) config('excellent_educators.scheduling.day_end', '20:00');
    }

    public static function slotMinutes(): int
    {
        return (int) config('excellent_educators.scheduling.slot_minutes', 30);
    }

    public static function breakMinutes(): int
    {
        return (int) config('excellent_educators.scheduling.break_minutes', 60);
    }

    /**
     * Clock-aligned 30-minute slots (from configured day_start through day_end).
     *
     * @return list<string>
     */
    public static function starts(): array
    {
        $starts = [];
        $cursor = self::parseHm(self::dayStart());
        $end = self::parseHm(self::dayEnd());
        $step = self::slotMinutes();

        while ($cursor + $step <= $end) {
            $starts[] = self::formatMinutes($cursor);
            $cursor += $step;
        }

        return $starts;
    }

    /**
     * @return list<string>
     */
    public static function alignedStartsBetween(string $from, string $to): array
    {
        $starts = [];
        $step = self::slotMinutes();
        $cursor = (int) (ceil(self::parseHm($from) / $step) * $step);
        $end = self::parseHm($to);
        while ($cursor + $step <= $end) {
            $starts[] = self::formatMinutes($cursor);
            $cursor += $step;
        }

        return $starts;
    }

    public static function slotFitsRange(string $start, string $rangeStart, string $rangeEnd): bool
    {
        $from = self::parseHm($start);
        $to = $from + self::slotMinutes();

        return $from >= self::parseHm($rangeStart) && $to <= self::parseHm($rangeEnd);
    }

    public static function endFor(string $start): string
    {
        return self::addMinutes($start, self::slotMinutes());
    }

    public static function addMinutes(string $hm, int $minutes): string
    {
        return self::formatMinutes(self::parseHm($hm) + $minutes);
    }

    public static function parseHm(string $hm): int
    {
        [$hours, $mins] = array_map('intval', explode(':', $hm) + [0, 0]);

        return ($hours * 60) + $mins;
    }

    public static function formatMinutes(int $minutes): string
    {
        $hours = intdiv($minutes, 60);
        $mins = $minutes % 60;

        return sprintf('%02d:%02d', $hours, $mins);
    }

    public static function isAligned(string $hm): bool
    {
        return self::parseHm($hm) % self::slotMinutes() === 0;
    }

    public static function isWithinDay(string $start, string $end): bool
    {
        return self::parseHm($start) >= self::parseHm(self::dayStart())
            && self::parseHm($end) <= self::parseHm(self::dayEnd())
            && self::parseHm($start) < self::parseHm($end);
    }

    /**
     * @return list<string>
     */
    public static function startsCovering(string $start, string $end): array
    {
        $from = self::parseHm($start);
        $to = self::parseHm($end);
        $covered = [];

        foreach (self::starts() as $slotStart) {
            $slotFrom = self::parseHm($slotStart);
            $slotTo = $slotFrom + self::slotMinutes();
            if ($slotFrom < $to && $from < $slotTo) {
                $covered[] = $slotStart;
            }
        }

        return $covered;
    }

    public static function atDate(string $date, string $hm): Carbon
    {
        return Carbon::parse($date.' '.$hm.':00', config('app.timezone'));
    }

    public static function hmFrom(CarbonInterface $time): string
    {
        return $time->copy()->timezone(config('app.timezone'))->format('H:i');
    }

    public static function dateFrom(CarbonInterface $time): string
    {
        return $time->copy()->timezone(config('app.timezone'))->toDateString();
    }
}
