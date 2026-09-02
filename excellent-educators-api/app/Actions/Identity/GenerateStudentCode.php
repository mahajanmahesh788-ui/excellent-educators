<?php

namespace App\Actions\Identity;

use App\Models\CareerCompassLevel;
use Illuminate\Support\Facades\DB;

class GenerateStudentCode
{
    public function execute(CareerCompassLevel $level, int $academicYear): string
    {
        $campaign = strtoupper((string) config('excellent_educators.student_id.campaign_code', 'APS'));
        $ccPrefix = strtoupper($level->code);
        $yearSuffix = str_pad((string) ($academicYear % 100), 2, '0', STR_PAD_LEFT);

        return DB::transaction(function () use ($campaign, $academicYear, $ccPrefix, $yearSuffix): string {
            $exists = DB::table('student_code_sequences')
                ->where('campaign_code', $campaign)
                ->where('academic_year', $academicYear)
                ->exists();

            if (! $exists) {
                DB::table('student_code_sequences')->insert([
                    'campaign_code' => $campaign,
                    'academic_year' => $academicYear,
                    'last_seq' => 0,
                ]);
            }

            $sequence = DB::table('student_code_sequences')
                ->where('campaign_code', $campaign)
                ->where('academic_year', $academicYear)
                ->lockForUpdate()
                ->first();

            $next = ((int) $sequence->last_seq) + 1;

            DB::table('student_code_sequences')
                ->where('campaign_code', $campaign)
                ->where('academic_year', $academicYear)
                ->update(['last_seq' => $next]);

            return sprintf('%s-%s-%s-%04d', $ccPrefix, $campaign, $yearSuffix, $next);
        });
    }
}
