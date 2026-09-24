<?php

namespace App\Actions\Identity;

use App\Support\AppClock;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\DB;

class GenerateStudentCode
{
    public function execute(?CarbonInterface $at = null): string
    {
        $campaign = strtoupper((string) config('excellent_educators.student_id.campaign_code', 'APS'));
        $now = ($at ?? AppClock::now())->copy()->timezone(config('app.timezone'));
        $academicYear = (int) $now->year;
        $month = (int) $now->month;
        $yearSuffix = $now->format('y');
        $monthSuffix = $now->format('m');

        return DB::transaction(function () use ($campaign, $academicYear, $month, $yearSuffix, $monthSuffix): string {
            $exists = DB::table('student_code_sequences')
                ->where('campaign_code', $campaign)
                ->where('academic_year', $academicYear)
                ->where('month', $month)
                ->exists();

            if (! $exists) {
                DB::table('student_code_sequences')->insert([
                    'campaign_code' => $campaign,
                    'academic_year' => $academicYear,
                    'month' => $month,
                    'last_seq' => 0,
                ]);
            }

            $sequence = DB::table('student_code_sequences')
                ->where('campaign_code', $campaign)
                ->where('academic_year', $academicYear)
                ->where('month', $month)
                ->lockForUpdate()
                ->first();

            $next = ((int) $sequence->last_seq) + 1;

            DB::table('student_code_sequences')
                ->where('campaign_code', $campaign)
                ->where('academic_year', $academicYear)
                ->where('month', $month)
                ->update(['last_seq' => $next]);

            return sprintf('%s-%s-%02d', $yearSuffix, $monthSuffix, $next);
        });
    }
}
