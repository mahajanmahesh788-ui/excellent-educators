<?php

namespace App\Actions\Batches;

use App\Enums\BatchStatus;
use App\Enums\ProfileStatus;
use App\Models\AcademicLevel;
use App\Models\Batch;
use App\Models\BatchStudent;
use App\Models\StudentProfile;
use App\Models\User;
use App\Support\AppSettings;
use Illuminate\Support\Facades\DB;

class AllocateBatchForStudent
{
    public function __construct(private readonly ActivateBatch $activateBatch) {}

    public function execute(AcademicLevel $level, StudentProfile $student, User $actor): Batch
    {
        return DB::transaction(function () use ($level, $student, $actor) {
            $maxActive = app(AppSettings::class)->maxActiveStudents();

            // Fill the oldest open batch (active or inactive) that still has room.
            // Do not skip inactive batches — students wait there until the batch is activated.
            $batch = Batch::query()
                ->where('level_id', $level->id)
                ->whereIn('status', [BatchStatus::Active->value, BatchStatus::Inactive->value])
                ->where('enrolled_watermark', '<', $maxActive)
                ->orderBy('created_at')
                ->lockForUpdate()
                ->first();

            if (! $batch) {
                $count = Batch::query()->where('level_id', $level->id)->count();
                $batchNumber = $count + 1;
                $batchName = "Batch {$batchNumber}";

                while (Batch::query()->where('level_id', $level->id)->where('name', $batchName)->exists()) {
                    $batchNumber++;
                    $batchName = "Batch {$batchNumber}";
                }

                $currentYear = (int) date('Y');
                $currentMonth = (int) date('n');

                $batch = Batch::query()->create([
                    'level_id' => $level->id,
                    'name' => $batchName,
                    'academic_year' => $level->academic_year ?? $currentYear,
                    'year' => $currentYear,
                    'month' => $currentMonth,
                    'status' => BatchStatus::Inactive,
                    'enrolled_watermark' => 0,
                ]);
            }

            $alreadyActive = BatchStudent::query()
                ->where('batch_id', $batch->id)
                ->where('student_id', $student->id)
                ->whereNull('left_at')
                ->where('status', ProfileStatus::Active->value)
                ->exists();

            if (! $alreadyActive) {
                BatchStudent::query()
                    ->where('student_id', $student->id)
                    ->whereNull('left_at')
                    ->where('status', ProfileStatus::Active->value)
                    ->update([
                        'left_at' => now(),
                        'status' => ProfileStatus::Inactive->value,
                    ]);

                BatchStudent::query()->create([
                    'batch_id' => $batch->id,
                    'student_id' => $student->id,
                    'enrolled_by' => $actor->id,
                    'status' => ProfileStatus::Active,
                    'enrolled_at' => now(),
                ]);

                $batch->increment('enrolled_watermark');
                $batch->refresh();
            }

            // Batch becomes active when it is full (or when an admin activates it).
            if (
                $batch->enrolled_watermark >= $maxActive
                && $batch->status !== BatchStatus::Active
            ) {
                $batch = $this->activateBatch->execute($batch);
            }

            return $batch->fresh() ?? $batch;
        });
    }
}
