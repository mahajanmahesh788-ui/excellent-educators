<?php

namespace App\Actions\Batches;

use App\Actions\Learning\StartStudentLevelJourney;
use App\Enums\BatchStatus;
use App\Enums\ProfileStatus;
use App\Models\AcademicLevel;
use App\Models\Batch;
use App\Models\BatchStudent;
use App\Support\AppClock;
use Illuminate\Support\Facades\DB;

class ActivateBatch
{
    public function __construct(private readonly StartStudentLevelJourney $startStudentLevelJourney) {}

    public function execute(Batch $batch): Batch
    {
        return DB::transaction(function () use ($batch): Batch {
            $batch = Batch::query()->lockForUpdate()->findOrFail($batch->id);

            $alreadyActive = $batch->status === BatchStatus::Active
                || $batch->status === 'active';

            $startsOn = $batch->starts_on ?? AppClock::todayString();

            if (! $alreadyActive) {
                $batch->update([
                    'status' => BatchStatus::Active,
                    'starts_on' => $startsOn,
                ]);
            } elseif ($batch->starts_on === null) {
                $batch->update(['starts_on' => $startsOn]);
            }

            $batch->refresh();

            $level = $batch->level ?? AcademicLevel::query()->find($batch->level_id);
            if ($level === null) {
                return $batch;
            }

            $startedAt = $batch->starts_on?->copy()->startOfDay() ?? AppClock::now();

            $studentIds = BatchStudent::query()
                ->where('batch_id', $batch->id)
                ->whereNull('left_at')
                ->where('status', ProfileStatus::Active->value)
                ->pluck('student_id');

            foreach ($studentIds as $studentId) {
                $student = \App\Models\StudentProfile::query()->find($studentId);
                if ($student === null) {
                    continue;
                }
                $this->startStudentLevelJourney->execute($student, $level, $startedAt);
            }

            return $batch->fresh();
        });
    }
}
