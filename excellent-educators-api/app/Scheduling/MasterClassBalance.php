<?php

namespace App\Scheduling;

use App\Models\StudentMasterClassBalance;
use App\Models\StudentProfile;
use App\Support\AppClock;
use Illuminate\Support\Facades\DB;

class MasterClassBalance
{
    /**
     * @return array{allotment: int, remaining: int, used: int, year: int, month: int}
     */
    public function snapshot(StudentProfile $student): array
    {
        $row = $this->ensure($student);

        return [
            'allotment' => (int) $row->allotment,
            'remaining' => (int) $row->remaining,
            'used' => max(0, (int) $row->allotment - (int) $row->remaining),
            'year' => (int) $row->year,
            'month' => (int) $row->month,
        ];
    }

    public function allotmentFor(StudentProfile $student): int
    {
        $student->loadMissing(['academicLevel', 'activeEnrollment.batch.level']);
        $override = $student->master_classes_per_month;
        if ($override !== null) {
            return max(1, min(10, (int) $override));
        }
        $level = $student->academicLevel ?? $student->activeEnrollment?->batch?->level;

        return max(1, min(10, (int) ($level?->master_classes_per_month ?? 1)));
    }

    public function remaining(StudentProfile $student): int
    {
        return (int) $this->ensure($student)->remaining;
    }

    public function spend(StudentProfile $student): void
    {
        DB::transaction(function () use ($student): void {
            $row = $this->lockRow($student);
            if ((int) $row->remaining < 1) {
                return;
            }
            $row->update(['remaining' => (int) $row->remaining - 1]);
        });
    }

    public function restore(StudentProfile $student): void
    {
        DB::transaction(function () use ($student): void {
            $row = $this->lockRow($student);
            $next = min(10, (int) $row->remaining + 1);
            $row->update(['remaining' => $next]);
        });
    }

    public function syncAllotment(StudentProfile $student): void
    {
        $row = $this->ensure($student);
        $allotment = $this->allotmentFor($student->fresh(['academicLevel', 'activeEnrollment.batch.level']));
        $delta = $allotment - (int) $row->allotment;
        $remaining = max(0, (int) $row->remaining + $delta);
        $row->update([
            'allotment' => $allotment,
            'remaining' => min($allotment, $remaining),
        ]);
    }

    public function ensure(StudentProfile $student): StudentMasterClassBalance
    {
        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();
        $existing = StudentMasterClassBalance::query()
            ->where('student_id', $student->id)
            ->where('year', $year)
            ->where('month', $month)
            ->first();
        if ($existing !== null) {
            $allotment = $this->allotmentFor($student);
            if ((int) $existing->allotment !== $allotment) {
                $delta = $allotment - (int) $existing->allotment;
                $remaining = max(0, min($allotment, (int) $existing->remaining + $delta));
                $existing->update([
                    'allotment' => $allotment,
                    'remaining' => $remaining,
                ]);
            }

            return $existing->fresh() ?? $existing;
        }

        $allotment = $this->allotmentFor($student);

        return StudentMasterClassBalance::query()->create([
            'student_id' => $student->id,
            'year' => $year,
            'month' => $month,
            'allotment' => $allotment,
            'remaining' => $allotment,
        ]);
    }

    private function lockRow(StudentProfile $student): StudentMasterClassBalance
    {
        ['year' => $year, 'month' => $month] = AppClock::currentYearMonth();
        $row = StudentMasterClassBalance::query()
            ->where('student_id', $student->id)
            ->where('year', $year)
            ->where('month', $month)
            ->lockForUpdate()
            ->first();

        return $row ?? $this->ensure($student);
    }
}
