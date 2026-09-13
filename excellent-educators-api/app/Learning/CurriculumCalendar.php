<?php

namespace App\Learning;

use App\Models\AcademicLevel;
use App\Models\StudentLevelJourney;
use App\Models\StudentProfile;
use App\Support\AppClock;
use Illuminate\Support\Carbon;

final class CurriculumCalendar
{
    /**
     * @return array{month: int, month_name: string, year: int}
     */
    public static function forWeek(int $weekNumber, AcademicLevel $level): array
    {
        $weekNumber = max(1, min(52, $weekNumber));
        $month = min(12, (int) floor(($weekNumber - 1) * 12 / 52) + 1);
        $year = (int) ($level->academic_year ?? AppClock::now()->year);

        return [
            'month' => $month,
            'month_name' => Carbon::create($year, $month, 1)->format('F'),
            'year' => $year,
        ];
    }
}
